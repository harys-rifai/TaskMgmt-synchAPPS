import os
from pathlib import Path

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
        'DIRS': [
            BASE_DIR / 'tasks' / 'templates',
        ],
        # Use cached loader so templates are parsed once and reused
        'APP_DIRS': False,
        'OPTIONS': {
            'loaders': [
                ('django.template.loaders.cached.Loader', [
                    'django.template.loaders.filesystem.Loader',
                    'django.template.loaders.app_directories.Loader',
                ]),
            ],
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
        'CONN_MAX_AGE': 60,          # keep DB connections alive for 60s (connection pooling)
        'OPTIONS': {
            'connect_timeout': 5,
        },
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

# ---------------------------------------------------------------------------
# Cache — Redis (Memurai) on localhost.
# Timeouts are intentionally short (300ms) so that if Redis is down the app
# degrades gracefully in <1s rather than blocking for multiple seconds.
# IGNORE_EXCEPTIONS=True means a cache miss is returned instead of an error.
# ---------------------------------------------------------------------------
REDIS_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS':          'django_redis.client.DefaultClient',
            'SOCKET_CONNECT_TIMEOUT': 0.3,   # fail fast if Redis is down
            'SOCKET_TIMEOUT':         0.3,   # don't wait more than 300ms per op
            'RETRY_ON_TIMEOUT':       False, # one attempt only — no double wait
            'MAX_CONNECTIONS':        20,
            'IGNORE_EXCEPTIONS':      True,  # cache miss on any error, never crash
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

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

DATA_UPLOAD_MAX_NUMBER_FIELDS = 10000

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