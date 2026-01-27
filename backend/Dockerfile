FROM python:3.12-slim

# 系统库（GeoDjango 依赖 + 字体支持）
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils gdal-bin libgdal-dev libgeos-dev libproj-dev \
    gcc libpq-dev postgresql-client \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 先装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 拷贝代码
COPY . /app

# 让 Django 找到 settings；非必须，但更稳妥
ENV DJANGO_SETTINGS_MODULE=server.settings \
    PYTHONUNBUFFERED=1

# 收集静态文件（必须有 STATIC_ROOT）
RUN python manage.py collectstatic --noinput

# 迁移 + 启动 gunicorn
CMD ["bash", "-lc", "python manage.py migrate && gunicorn server.wsgi:application -b 0.0.0.0:8000 --workers 3 --timeout 120 --graceful-timeout 30 --keep-alive 5 --access-logfile - --error-logfile -"]
