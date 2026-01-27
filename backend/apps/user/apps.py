# apps/user/apps.py
from django.apps import AppConfig

class UserConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.user'
    verbose_name = 'User'

    def ready(self):
        # 这里导入以注册 signals（确保有 apps/user/signals.py）
        from . import signals  # noqa
