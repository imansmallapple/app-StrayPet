from rest_framework import serializers
from .models import HolidayFamilyApplication, HolidayFamilyPhoto


class HolidayFamilyPhotoSerializer(serializers.ModelSerializer):
    photo = serializers.SerializerMethodField()

    class Meta:
        model = HolidayFamilyPhoto
        fields = ['id', 'photo', 'uploaded_at']
        read_only_fields = ['id', 'uploaded_at']

    def get_photo(self, obj):
        """Return the absolute photo URL"""
        if obj.photo:
            return f"http://localhost:8000/media/{obj.photo}"
        return None


class HolidayFamilyApplicationSerializer(serializers.ModelSerializer):
    family_photos = HolidayFamilyPhotoSerializer(many=True, read_only=True)

    class Meta:
        model = HolidayFamilyApplication
        fields = [
            'id',
            'user',
            'full_name',
            'email',
            'phone',
            'country',
            'state',
            'city',
            'street_address',
            'postal_code',
            'pet_count',
            'can_take_dogs',
            'can_take_cats',
            'can_take_rabbits',
            'can_take_others',
            'motivation',
            'introduction',
            'id_document',
            'family_photos',
            'terms_agreed',
            'status',
            'rejection_reason',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'user', 'status', 'rejection_reason', 'created_at', 'updated_at', 'family_photos']

    def create(self, validated_data):
        # 获取 request 对象获取 user
        request = self.context.get('request')
        user = request.user if request else None
        
        # 创建应用实例，包含 user 信息
        application = HolidayFamilyApplication.objects.create(
            user=user,
            **validated_data
        )
        
        # 添加家庭照片
        if request and request.FILES:
            # 处理单个文件上传或多个文件上传
            family_photos = request.FILES.getlist('family_photos_0')
            if not family_photos:
                # 尝试使用 getlist 的标准方式
                family_photos = request.FILES.getlist('family_photos')
            
            # 也可能是按索引上传的多个文件
            if not family_photos:
                index = 0
                while True:
                    photo = request.FILES.get(f'family_photos_{index}')
                    if not photo:
                        break
                    HolidayFamilyPhoto.objects.create(application=application, photo=photo)
                    index += 1
            else:
                for photo_file in family_photos:
                    HolidayFamilyPhoto.objects.create(application=application, photo=photo_file)
        
        return application
