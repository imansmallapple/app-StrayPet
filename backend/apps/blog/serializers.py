from rest_framework import serializers
from .models import Article, Category, Tag
from apps.user.models import ViewStatistics
from apps.comment.models import Comment
import re


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'


class TagSerializer(serializers.ModelSerializer):
    article_count = serializers.IntegerField(read_only=True, default=0)
    
    class Meta:
        model = Tag
        fields = ['id', 'name', 'add_date', 'pub_date', 'article_count']


class AuthorInfoSerializer(serializers.Serializer):
    """作者信息序列化器 - 用于在文章中显示"""
    id = serializers.IntegerField()
    username = serializers.CharField()
    avatar = serializers.SerializerMethodField()
    
    def get_avatar(self, obj):
        """获取用户头像"""
        if hasattr(obj, 'profile') and obj.profile and hasattr(obj.profile, 'avatar'):
            if obj.profile.avatar:
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(obj.profile.avatar.url)
                return obj.profile.avatar.url
        return None


class ArticleSerializer(serializers.ModelSerializer):
    category = serializers.HyperlinkedRelatedField(
        view_name='category-detail',
        read_only=True,
    )
    tags = serializers.StringRelatedField(many=True, read_only=True)
    count = serializers.IntegerField(read_only=True, default=0)
    # 直接返回HTML内容，不转换为Markdown
    author_username = serializers.CharField(source='author.username', read_only=True, default=None)
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Article
        fields = '__all__'

    def to_representation(self, instance):
        """自定义输出，将 author FK 转换为完整的作者信息"""
        data = super().to_representation(instance)
        # 将 author ID 替换为完整的作者信息
        if instance.author:
            data['author'] = AuthorInfoSerializer(instance.author, context=self.context).data
        else:
            data['author'] = None
        return data

    def get_is_favorited(self, obj):
        """判断当前用户是否收藏了该文章"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from .models import FavoriteArticle
            return FavoriteArticle.objects.filter(
                user=request.user,
                article=obj
            ).exists()
        return False


class ArticleCreateUpdateSerializer(serializers.ModelSerializer):
    """用于创建和更新文章的 Serializer"""
    category = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        required=False,
        allow_null=True
    )
    tags = serializers.PrimaryKeyRelatedField(
        queryset=Tag.objects.all(),
        many=True,
        required=False,
        allow_null=True
    )

    class Meta:
        model = Article
        fields = ['id', 'title', 'description', 'content', 'category', 'tags']
        read_only_fields = ['id']

    def extract_hashtags(self, content):
        """从内容中提取所有 #hashtag"""
        # 匹配 #后面跟字母、数字、中文字符
        pattern = r'#([\w\u4e00-\u9fa5]+)'
        hashtags = re.findall(pattern, content)
        return list(set(hashtags))  # 去重

    def create(self, validated_data):
        tags_data = validated_data.pop('tags', [])
        content = validated_data.get('content', '')
        
        # 自动设置作者为当前登录用户
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['author'] = request.user
        
        # 如果没有提供category，使用默认的"未分类"
        if 'category' not in validated_data or validated_data.get('category') is None:
            default_category, _ = Category.objects.get_or_create(
                name='未分类',
                defaults={'name': '未分类'}
            )
            validated_data['category'] = default_category
        
        # 创建文章
        article = Article.objects.create(**validated_data)
        
        # 从内容中提取hashtags
        hashtags = self.extract_hashtags(content)
        
        # 为提取的hashtags创建或获取Tag对象
        tag_objects = []
        for tag_name in hashtags:
            tag, _ = Tag.objects.get_or_create(name=tag_name)
            tag_objects.append(tag)
        
        # 添加手动指定的tags（如果有）
        tag_objects.extend(tags_data)
        
        # 关联所有tags
        if tag_objects:
            article.tags.set(tag_objects)
        
        return article

    def update(self, instance, validated_data):
        tags_data = validated_data.pop('tags', None)
        content = validated_data.get('content', instance.content)
        
        # 更新基本字段
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # 从内容中提取hashtags
        hashtags = self.extract_hashtags(content)
        
        # 为提取的hashtags创建或获取Tag对象
        tag_objects = []
        for tag_name in hashtags:
            tag, _ = Tag.objects.get_or_create(name=tag_name)
            tag_objects.append(tag)
        
        # 如果手动指定了tags，也添加进去
        if tags_data is not None:
            tag_objects.extend(tags_data)
        
        # 更新tags关联
        if tag_objects or tags_data is not None:
            instance.tags.set(tag_objects)
        
        return instance


class BlogCommentSerializer(serializers.ModelSerializer):
    """博客评论序列化器 - 不需要验证码"""
    owner = serializers.HiddenField(default=serializers.CurrentUserDefault())

    class Meta:
        model = Comment
        fields = ['id', 'owner', 'content', 'parent', 'add_date', 'pub_date', 'content_type', 'object_id']
        read_only_fields = ('content_type', 'object_id', 'add_date', 'pub_date', 'id')

    def create(self, validated_data):
        """自定义create方法以支持content_object"""
        content_object = self.context.get('content_object')
        if not content_object:
            raise ValueError('content_object is required in context')
        
        # 从content_object中提取content_type和object_id
        from django.contrib.contenttypes.models import ContentType
        content_type = ContentType.objects.get_for_model(content_object)
        
        comment = Comment.objects.create(
            owner=validated_data.get('owner'),
            content=validated_data.get('content'),
            parent=validated_data.get('parent'),
            content_type=content_type,
            object_id=content_object.pk
        )
        return comment


class BlogCommentListSerializer(serializers.ModelSerializer):
    """博客评论列表序列化器 - 用于展示"""
    user = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ['id', 'user', 'content', 'add_date', 'pub_date', 'parent', 'replies']

    def get_user(self, obj):
        """返回用户信息，包括头像"""
        from django.conf import settings
        import logging
        logger = logging.getLogger(__name__)
        
        user_data = {
            'id': obj.owner.id,
            'username': obj.owner.username
        }
        # 添加用户头像
        if hasattr(obj.owner, 'profile') and obj.owner.profile:
            if hasattr(obj.owner.profile, 'avatar') and obj.owner.profile.avatar:
                request = self.context.get('request')
                if request:
                    # 确保使用完整的绝对 URL
                    avatar_url = request.build_absolute_uri(obj.owner.profile.avatar.url)
                    user_data['avatar'] = avatar_url
                    logger.info(f"Avatar URL for {obj.owner.username}: {avatar_url}")
                else:
                    # 如果没有 request，使用 MEDIA_URL + path
                    avatar_url = f"{settings.MEDIA_URL}{obj.owner.profile.avatar.name}"
                    user_data['avatar'] = avatar_url
                    logger.info(f"Avatar URL (no request) for {obj.owner.username}: {avatar_url}")
            else:
                user_data['avatar'] = None
                logger.warning(f"No avatar for {obj.owner.username}")
        else:
            user_data['avatar'] = None
            logger.warning(f"No profile for {obj.owner.username}")
        return user_data

    def get_replies(self, obj):
        # 获取该评论的所有回复
        replies = Comment.objects.filter(parent=obj)
        return BlogCommentListSerializer(replies, many=True, context=self.context).data
