from django.db import models
from django.db.models.functions import ExtractYear, ExtractMonth
from django_filters import rest_framework as filters
from rest_framework import viewsets, mixins, permissions, status
from rest_framework.decorators import action
from rest_framework.filters import SearchFilter, OrderingFilter
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.core.files.storage import default_storage
from django.conf import settings
import os
from apps.user.models import ViewStatistics
from common import pagination
from .models import Article, Tag, Category, FavoriteArticle
from .serializers import (
    ArticleSerializer, 
    ArticleCreateUpdateSerializer, 
    TagSerializer, 
    CategorySerializer,
    BlogCommentSerializer,
    BlogCommentListSerializer
)
from django.db.models import Sum, F
from django.db.models.functions import Coalesce
from apps.comment.serializers import CommentSerializer, CommentListSerializer


class CategoryViewSet(mixins.ListModelMixin,
                      mixins.RetrieveModelMixin,
                      mixins.CreateModelMixin,
                      viewsets.GenericViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    filter_backends = [SearchFilter, OrderingFilter]
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    search_fields = ['name']
    ordering_fields = ['add_date']


class ArticleViewSet(mixins.ListModelMixin,
                     mixins.RetrieveModelMixin,
                     mixins.CreateModelMixin,
                     mixins.UpdateModelMixin,
                     viewsets.GenericViewSet):
    queryset = Article.objects.all()
    serializer_class = ArticleSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [
        filters.DjangoFilterBackend,
        SearchFilter
    ]
    search_fields = ['title']
    ordering_fields = ['add_date', 'pub_date', 'count']
    ordering = ['-add_date']  # 默认排序
    filterset_fields = ['category', 'tags']

    def get_serializer_class(self):
        if self.action == 'add_comment':
            return BlogCommentSerializer
        elif self.action == 'comments':
            return BlogCommentListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ArticleCreateUpdateSerializer
        return super().get_serializer_class()

    def get_queryset(self):
        queryset = super().get_queryset()
        # 注解 count 字段用于排序和序列化
        queryset = queryset.annotate(
            count=Coalesce(Sum('view_count__count'), 0)
        )
        return queryset
    
    def list(self, request, *args, **kwargs):
        ordering = request.query_params.get('ordering', '-add_date')
        self.queryset = self.get_queryset()
        
        # 调试：打印前5篇文章的count值
        print(f"DEBUG: ordering={ordering}")
        for article in self.queryset[:5]:
            print(f"DEBUG: Article {article.id} - {article.title} - count={article.count}")
        
        # 应用排序
        if ordering == '-count':
            self.queryset = self.queryset.order_by('-count', '-add_date')
            print("DEBUG: Applied -count ordering")
        elif ordering == 'count':
            self.queryset = self.queryset.order_by('count', '-add_date')
            print("DEBUG: Applied count ordering")
        else:
            self.queryset = self.queryset.order_by(ordering)
        
        # 再次打印排序后的前5篇
        print("DEBUG: After ordering:")
        for article in self.queryset[:5]:
            print(f"DEBUG: Article {article.id} - {article.title} - count={article.count}")
        
        return super().list(request, *args, **kwargs)
        
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        obj = self.get_object()
        ViewStatistics.increase(request, obj)
        return super().retrieve(request, *args, **kwargs)

    @action(methods=['get'], detail=False)
    def archive(self, request, *args, **kwargs):
        queryset = self.get_queryset().annotate(
            year=ExtractYear('add_date'),
            month=ExtractMonth('add_date')
        ).values('year', 'month').annotate(
            count=models.Count('id')
        ).order_by('-year', '-month')
        return Response(list(queryset))
        # [{'year': 2021, 'month': 1, 'count': 1}]

    @action(methods=['get'], detail=False)
    def archive_detail(self, request, year: int, month: int):
        queryset = self.get_queryset().annotate(
            year=ExtractYear('add_date'),
            month=ExtractMonth('add_date')
        ).filter(
            add_date__year=year,
            add_date__month=month
        ).order_by('-add_date')

        serializer = self.get_serializer(
            queryset,
            many=True,
        )
        paginator = pagination.PageNumberPagination()
        page = paginator.paginate_queryset(serializer.data, request)
        response = paginator.get_paginated_response(page)
        return response

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def add_comment(self, request, pk=None):
        content_object = self.get_object()
        
        # 检查是否是回复评论
        parent_id = request.data.get('parent')
        if parent_id:
            from apps.comment.models import Comment
            parent = Comment.objects.get(id=parent_id)
            content_object = parent.content_object
        
        serializer = self.get_serializer(
            data=request.data,
            context={'request': request, 'content_object': content_object}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def comments(self, request, pk=None):
        article = self.get_object()
        comments = article.comments.filter(parent__isnull=True)
        serializer = BlogCommentListSerializer(comments, many=True, context={'request': request})
        paginator = pagination.PageNumberPagination()
        page = paginator.paginate_queryset(serializer.data, request)
        response = paginator.get_paginated_response(page)
        return response

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_articles(self, request):
        """获取当前用户发布的文章列表"""
        queryset = Article.objects.filter(author=request.user).order_by('-add_date')
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        paginator = pagination.PageNumberPagination()
        page = paginator.paginate_queryset(serializer.data, request)
        return paginator.get_paginated_response(page)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def favorites(self, request):
        """获取当前用户收藏的文章列表"""
        favorite_articles = FavoriteArticle.objects.filter(
            user=request.user
        ).select_related('article').order_by('-add_date')
        
        articles = [fav.article for fav in favorite_articles]
        serializer = self.get_serializer(articles, many=True, context={'request': request})
        paginator = pagination.PageNumberPagination()
        page = paginator.paginate_queryset(serializer.data, request)
        return paginator.get_paginated_response(page)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_comments(self, request):
        """获取当前用户的所有评论"""
        from apps.comment.models import Comment
        
        # 获取当前用户发表的所有评论
        comments = Comment.objects.filter(owner=request.user).order_by('-add_date')
        
        # 为每个评论添加所属文章信息
        comments_data = []
        for comment in comments:
            serializer = BlogCommentListSerializer(comment, context={'request': request})
            data = serializer.data
            
            # 获取评论所属的文章
            if hasattr(comment, 'content_object') and comment.content_object:
                if isinstance(comment.content_object, Article):
                    data['article_id'] = comment.content_object.id
                    data['article_title'] = comment.content_object.title
            
            comments_data.append(data)
        
        paginator = pagination.PageNumberPagination()
        page = paginator.paginate_queryset(comments_data, request)
        return paginator.get_paginated_response(page)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def replies_to_me(self, request):
        """获取别人对我的评论的回复（不包括我自己回复自己）"""
        from apps.comment.models import Comment
        
        # 获取所有对当前用户评论的回复
        # 1. 找到当前用户的所有评论
        my_comments = Comment.objects.filter(owner=request.user).values_list('id', flat=True)
        
        # 2. 找到这些评论的所有回复，但排除当前用户自己的回复
        replies = Comment.objects.filter(
            parent_id__in=my_comments
        ).exclude(
            owner=request.user
        ).order_by('-add_date').select_related('owner__profile')
        
        # 为每个回复添加所属文章和被回复评论的信息
        replies_data = []
        
        for reply in replies:
            serializer = BlogCommentListSerializer(reply, context={'request': request})
            data = serializer.data
            
            # 添加被回复的评论信息（当前用户的评论）
            if reply.parent:
                parent_serializer = BlogCommentListSerializer(reply.parent, context={'request': request})
                data['parent_comment'] = parent_serializer.data
            
            # 获取回复所属的文章 - 通过 parent.content_object
            article_id = None
            article_title = None
            try:
                # 回复评论本身没有 content_object，需要通过 parent 评论获取
                if reply.parent:
                    parent = reply.parent
                    if parent.content_type_id and parent.object_id:
                        try:
                            from django.contrib.contenttypes.models import ContentType
                            article_ct = ContentType.objects.get(app_label='blog', model='article')
                            if parent.content_type_id == article_ct.id:
                                article = Article.objects.get(id=parent.object_id)
                                article_id = article.id
                                article_title = article.title
                        except Exception:
                            pass
            except Exception as e:
                pass
            
            data['article_id'] = article_id
            data['article_title'] = article_title
            
            replies_data.append(data)
        
        paginator = pagination.PageNumberPagination()
        page = paginator.paginate_queryset(replies_data, request)
        return paginator.get_paginated_response(page)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def favorite(self, request, pk=None):
        """收藏文章"""
        article = self.get_object()
        favorite, created = FavoriteArticle.objects.get_or_create(
            user=request.user,
            article=article
        )
        if created:
            return Response({'status': 'favorited', 'message': 'Added to favorites'})
        else:
            return Response({'status': 'already_favorited', 'message': 'Already in favorites'}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def unfavorite(self, request, pk=None):
        """取消收藏文章"""
        article = self.get_object()
        deleted_count, _ = FavoriteArticle.objects.filter(
            user=request.user,
            article=article
        ).delete()
        if deleted_count > 0:
            return Response({'status': 'unfavorited', 'message': 'Removed from favorites'})
        else:
            return Response({'status': 'not_favorited', 'message': 'Not in favorites'}, status=status.HTTP_404_NOT_FOUND)


class TagViewSet(mixins.ListModelMixin, mixins.CreateModelMixin, viewsets.GenericViewSet):
    queryset = Tag.objects.all()
    serializer_class = TagSerializer
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name']
    ordering_fields = ['add_date']

    @action(methods=['get'], detail=False)
    def popular(self, request):
        """返回按使用次数排序的热门标签"""
        from django.db.models import Count
        # 按关联的文章数量排序，返回前20个
        tags = Tag.objects.annotate(
            article_count=Count('article')
        ).filter(
            article_count__gt=0  # 只返回至少被使用过一次的标签
        ).order_by('-article_count', '-add_date')[:20]
        
        serializer = self.get_serializer(tags, many=True)
        return Response(serializer.data)


@csrf_exempt
def upload_image(request):
    """处理Django Admin Markdown编辑器的图片上传"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method allowed'}, status=405)
    
    if 'image' not in request.FILES:
        return JsonResponse({'error': 'No image file provided'}, status=400)
    
    image_file = request.FILES['image']
    
    # 验证文件类型
    allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
    file_ext = os.path.splitext(image_file.name)[1].lower()
    if file_ext not in allowed_extensions:
        return JsonResponse({'error': 'Invalid file type. Allowed: jpg, jpeg, png, gif, webp'}, status=400)
    
    # 保存文件
    upload_dir = 'blog_images'
    file_path = os.path.join(upload_dir, image_file.name)
    saved_path = default_storage.save(file_path, image_file)
    
    # 返回URL
    file_url = os.path.join(settings.MEDIA_URL, saved_path).replace('\\', '/')
    
    return JsonResponse({
        'url': file_url,
        'text': image_file.name
    })
