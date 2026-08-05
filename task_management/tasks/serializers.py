from rest_framework import serializers
from .models import Team, Task, TaskSync


class TeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = '__all__'


class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'


class TaskCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            'job_id',
            'email_from',
            'email_subject',
            'task_type',
            'task_detail',
            'assign_to',
            'priority',
            'note',
            'status',
            'source',
            'external_id',
            'dbname',
            'userid',
        ]


class TaskUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            'status',
            'assign_to',
            'note',
            'closed_at',
            'dbname',
            'userid',
        ]


class SyncItemSerializer(serializers.Serializer):
    external_id = serializers.CharField(max_length=255)
    job_id      = serializers.CharField(max_length=50, required=False, allow_blank=True)
    title       = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True, default='')
    status      = serializers.ChoiceField(
        choices=[
            'Open', 'Assigned', 'In Progress', 'Pending User',
            'Pending Vendor', 'Completed', 'Closed', 'Rejected', 'Cancelled',
        ],
        required=False,
        default='Open',
    )
    priority    = serializers.ChoiceField(
        choices=['High', 'Medium', 'Low'],
        required=False,
        default='Medium',
    )
    assignee    = serializers.CharField(required=False, allow_blank=True, default='')
    created_at  = serializers.DateTimeField(required=False)
    updated_at  = serializers.DateTimeField(required=False)
    url         = serializers.URLField(required=False, allow_blank=True)
    raw         = serializers.DictField(required=False, default=dict)
    task_type   = serializers.CharField(required=False, allow_blank=True, default='')
    dbname      = serializers.CharField(required=False, allow_blank=True, default='')
    userid      = serializers.CharField(required=False, allow_blank=True, default='')


class SyncRequestSerializer(serializers.Serializer):
    source = serializers.ChoiceField(choices=[
        ('email',          'Email'),
        ('teams',          'Microsoft Teams'),
        ('clickup',        'ClickUp'),
        ('whatsapp',       'WhatsApp'),
        ('telegram',       'Telegram'),
        ('action_network', 'Action Network'),
        ('n8n',            'n8n'),
    ])
    items  = SyncItemSerializer(many=True, allow_empty=False)


class TaskSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskSync
        fields = '__all__'