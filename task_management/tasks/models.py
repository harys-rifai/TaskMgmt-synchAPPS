from django.db import models
from django.core.exceptions import ValidationError


PROVIDER_PRESETS = {
    'gmail': {
        'host': 'smtp.gmail.com',
        'port': 587,
        'use_tls': True,
        'use_ssl': False,
        'label': 'Gmail',
    },
    'outlook': {
        'host': 'smtp.office365.com',
        'port': 587,
        'use_tls': True,
        'use_ssl': False,
        'label': 'Outlook / Office 365',
    },
    'yahoo': {
        'host': 'smtp.mail.yahoo.com',
        'port': 587,
        'use_tls': True,
        'use_ssl': False,
        'label': 'Yahoo Mail',
    },
    'sendgrid': {
        'host': 'smtp.sendgrid.net',
        'port': 587,
        'use_tls': True,
        'use_ssl': False,
        'label': 'SendGrid',
    },
    'mailgun': {
        'host': 'smtp.mailgun.org',
        'port': 587,
        'use_tls': True,
        'use_ssl': False,
        'label': 'Mailgun',
    },
    'custom': {
        'host': '',
        'port': 587,
        'use_tls': True,
        'use_ssl': False,
        'label': 'Custom SMTP',
    },
}


class Team(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'tasks_team'

    def __str__(self):
        return self.name


class Task(models.Model):
    job_id = models.CharField(
        max_length=50,
        unique=True,
    )
    email_from = models.EmailField()
    email_subject = models.TextField()
    task_type = models.CharField(
        max_length=100,
    )
    task_detail = models.TextField()
    assign_to = models.ForeignKey(
        Team,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    priority = models.CharField(
        max_length=20,
    )
    note = models.TextField(
        blank=True,
        null=True,
    )
    status = models.CharField(
        max_length=30,
        default='Open',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
    )
    updated_at = models.DateTimeField(
        auto_now=True,
    )
    closed_at = models.DateTimeField(
        null=True,
        blank=True,
    )
    source       = models.CharField(max_length=20, blank=True, db_index=True)
    external_id  = models.CharField(max_length=255, blank=True, db_index=True)

    class Meta:
        db_table = 'tasks_task'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.job_id} - {self.status}'

    @classmethod
    def get_next_job_id(cls):
        from django.db import transaction
        with transaction.atomic():
            last = cls.objects.filter(job_id__startswith='SCRQ').select_for_update().order_by('-job_id').first()
            if last and last.job_id.startswith('SCRQ'):
                num = last.job_id[4:]
                if num.isdigit():
                    return f'SCRQ{int(num) + 1}'
            return 'SCRQ1'


class TaskSync(models.Model):
    SOURCE_CHOICES = [
        ('email',    'Email'),
        ('teams',    'Microsoft Teams'),
        ('clickup',  'ClickUp'),
        ('whatsapp', 'WhatsApp'),
        ('telegram', 'Telegram'),
    ]

    source       = models.CharField(max_length=20, choices=SOURCE_CHOICES)
    external_id  = models.CharField(max_length=255, db_index=True)
    task         = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='syncs')
    raw          = models.JSONField(default=dict, blank=True)
    synced_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'tasks_tasksync'
        unique_together = ('source', 'external_id')
        ordering = ['-synced_at']

    def __str__(self):
        return f'{self.source}:{self.external_id} -> {self.task}'


class RedisConfig(models.Model):
    url = models.CharField(max_length=255, default='redis://localhost:6379/0')
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_redisconfig'
        verbose_name = 'Redis Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'Redis Config ({self.url})'


class AssignmentRule(models.Model):
    keyword = models.CharField(max_length=100, unique=True)
    team = models.ForeignKey(Team, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'tasks_assignmentrule'
        ordering = ['keyword']

    def __str__(self):
        return f'{self.keyword} -> {self.team.name}'


class N8nConfig(models.Model):
    """Singleton — only one row allowed. Stores n8n integration config."""

    base_url      = models.CharField(max_length=255, default='http://localhost:5678',
                                     help_text='n8n instance base URL')
    api_key       = models.TextField(blank=True,
                                     help_text='n8n API key (optional)')
    is_active     = models.BooleanField(default=True, help_text='Enable n8n integration')
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_n8nconfig'
        verbose_name = 'n8n Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'n8n Config ({self.base_url})'


class ClickUpConfig(models.Model):
    """Singleton — only one row allowed. Stores ClickUp integration config."""

    api_token     = models.TextField(blank=True,
                                     help_text='ClickUp API token (Personal API Key)')
    workspace_id  = models.CharField(max_length=255, blank=True,
                                     help_text='ClickUp Workspace ID')
    is_active     = models.BooleanField(default=True, help_text='Enable ClickUp integration')
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_clickupconfig'
        verbose_name = 'ClickUp Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'ClickUp Config ({self.workspace_id or "not set"})'


class WhatsAppConfig(models.Model):
    api_token        = models.TextField(blank=True, help_text='WhatsApp Business API token')
    phone_number_id  = models.CharField(max_length=255, blank=True, help_text='WhatsApp Phone Number ID')
    business_account_id = models.CharField(max_length=255, blank=True, help_text='WhatsApp Business Account ID')
    is_active        = models.BooleanField(default=True, help_text='Enable WhatsApp integration')
    updated_at       = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_whatsappconfig'
        verbose_name = 'WhatsApp Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'WhatsApp Config ({self.phone_number_id or "not set"})'


class TelegramConfig(models.Model):
    bot_token = models.TextField(blank=True, help_text='Telegram Bot Token from @BotFather')
    chat_id   = models.CharField(max_length=255, blank=True, help_text='Telegram Chat/Group ID')
    is_active = models.BooleanField(default=True, help_text='Enable Telegram integration')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_telegramconfig'
        verbose_name = 'Telegram Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'Telegram Config ({self.chat_id or "not set"})'


class DatabaseConfig(models.Model):
    ENGINE_CHOICES = [
        ('postgresql', 'PostgreSQL'),
        ('sqlite3',    'SQLite3'),
    ]

    engine   = models.CharField(max_length=20, choices=ENGINE_CHOICES, default='postgresql')
    name     = models.CharField(max_length=255, default='taskdb')
    user     = models.CharField(max_length=255, default='postgres')
    password = models.CharField(max_length=255, blank=True)
    host     = models.CharField(max_length=255, default='localhost')
    port     = models.CharField(max_length=10, default='5008')
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_databaseconfig'
        verbose_name = 'Database Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'Database Config ({self.get_engine_display()} - {self.name})'


class EmailConfig(models.Model):
    """Singleton — only one row allowed. Stores SMTP outbound config."""

    PROVIDER_CHOICES = [
        ('gmail',     'Gmail'),
        ('outlook',   'Outlook / Office 365'),
        ('yahoo',     'Yahoo Mail'),
        ('sendgrid',  'SendGrid'),
        ('mailgun',   'Mailgun'),
        ('custom',    'Custom SMTP'),
    ]

    provider      = models.CharField(max_length=20, choices=PROVIDER_CHOICES, default='gmail')
    host          = models.CharField(max_length=255, default='smtp.gmail.com')
    port          = models.PositiveIntegerField(default=587)
    username      = models.CharField(max_length=255, blank=True, help_text='SMTP username / email address')
    # Password stored plaintext — acceptable for internal self-hosted tool.
    # For production consider django-environ or a secrets manager.
    password      = models.CharField(max_length=255, blank=True)
    use_tls       = models.BooleanField(default=True)
    use_ssl       = models.BooleanField(default=False)
    from_email    = models.EmailField(blank=True, help_text='Displayed sender address (defaults to username)')
    from_name     = models.CharField(max_length=100, blank=True, default='Task Management',
                                     help_text='Displayed sender name')
    is_active     = models.BooleanField(default=False, help_text='Enable outbound email')
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_emailconfig'
        verbose_name = 'Email Configuration'

    def clean(self):
        if self.use_tls and self.use_ssl:
            raise ValidationError('use_tls and use_ssl are mutually exclusive.')

    def save(self, *args, **kwargs):
        # Enforce singleton
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def get_from_address(self):
        name = self.from_name or 'Task Management'
        addr = self.from_email or self.username
        return f'{name} <{addr}>' if addr else name

    def __str__(self):
        return f'Email Config ({self.get_provider_display()} / {"active" if self.is_active else "inactive"})'


class ActionNetworkConfig(models.Model):
    api_key = models.TextField(blank=True, help_text='Action Network API Key')
    webhook_url = models.CharField(max_length=255, blank=True, help_text='Action Network webhook callback URL')
    webhook_secret = models.CharField(max_length=255, blank=True, help_text='Webhook verification secret')
    is_active = models.BooleanField(default=True, help_text='Enable Action Network integration')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tasks_actionnetworkconfig'
        verbose_name = 'Action Network Configuration'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return f'Action Network Config ({self.webhook_url or "not set"})'
