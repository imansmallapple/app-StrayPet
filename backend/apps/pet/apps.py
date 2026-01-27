from django.apps import AppConfig


class PetConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.pet'
    verbose_name = 'Pet'

    def ready(self):
        # 导入以触发 @receiver 装饰器注册
        from . import signals  # noqa