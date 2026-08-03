import os
from pathlib import Path
from redis import Redis
from redis.exceptions import RedisError

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-fbrpo56$!li8b((fs45t0)4v4ykb^^$-af)q1$fpr!%1h=ds*t'

DEBUG = True

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'django_filters',
    'tasks',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'task_management.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'task_management.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'taskdb',
        'USER': 'postgres',
        'PASSWORD': 'Password09!',
        'HOST': 'localhost',
        'PORT': '5008',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

REDIS_URL = os.environ.get('REDIS_URL', 'redis://default:Kp2MdJmmsJTBx6rLy5fmvmkJNKXWBrJR@redis-19062.c15.us-east-1-4.ec2.cloud.redislabs.com:19062')
REDIS_LOCAL_URL = os.environ.get('REDIS_LOCAL_URL', 'redis://localhost:6379/0')


def get_redis_url():
    try:
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT url, is_active FROM tasks_redisconfig WHERE id=1")
            row = cursor.fetchone()
            if row and row[0] and row[1]:
                return row[0]
    except Exception:
        pass

    try:
        client = Redis.from_url(REDIS_URL, socket_connect_timeout=3, socket_timeout=3)
        client.ping()
        return REDIS_URL
    except (RedisError, TimeoutError, ConnectionError):
        return REDIS_LOCAL_URL


CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': get_redis_url(),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
            'RETRY_ON_TIMEOUT': True,
            'MAX_CONNECTIONS': 50,
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            'IGNORE_EXCEPTIONS': True,
        },
        'KEY_PREFIX': 'taskmgmt',
        'TIMEOUT': 300,
    }
}

# Use database sessions — more reliable than cache-only sessions
# Redis cache is still used for app-level caching
SESSION_ENGINE = 'django.contrib.sessions.backends.db'

LOGIN_URL          = '/login/'
LOGIN_REDIRECT_URL = '/dashboard/'

AUTH_USER_MODEL = 'auth.User'

# ---------------------------------------------------------------------------
# Email — loaded from DB at runtime via get_email_backend() in views.
# These are safe defaults; the live config comes from tasks_emailconfig table.
# ---------------------------------------------------------------------------
EMAIL_BACKEND   = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST      = 'smtp.gmail.com'
EMAIL_PORT      = 587
EMAIL_USE_TLS   = True
EMAIL_USE_SSL   = False
EMAIL_HOST_USER     = ''
EMAIL_HOST_PASSWORD = ''
DEFAULT_FROM_EMAIL  = 'Task Management <noreply@example.com>'

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'Asia/Jakarta'

USE_I18N = True

USE_TZ = True

STATIC_URL = 'static/'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}