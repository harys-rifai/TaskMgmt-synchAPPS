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
        ]


class TaskUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            'status',
            'assign_to',
            'note',
            'closed_at',
        ]


class SyncItemSerializer(serializers.Serializer):
    external_id = serializers.CharField(max_length=255)
    job_id      = serializers.CharField(max_length=50, required=False)
    title       = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False)
    status      = serializers.ChoiceField(choices=[
        'Open', 'Assigned', 'In Progress', 'Pending User',
        'Pending Vendor', 'Completed', 'Closed', 'Rejected', 'Cancelled',
    ], default='Open')
    priority    = serializers.ChoiceField(choices=['High', 'Medium', 'Low'], default='Medium')
    assignee    = serializers.CharField(required=False, allow_blank=True)
    created_at  = serializers.DateTimeField(required=False)
    updated_at  = serializers.DateTimeField(required=False)
    url         = serializers.URLField(required=False, allow_blank=True)
    raw         = serializers.DictField(required=False, default=dict)


class SyncRequestSerializer(serializers.Serializer):
    source  = serializers.ChoiceField(choices=TaskSync.SOURCE_CHOICES)
    items   = SyncItemSerializer(many=True, allow_empty=False)


class TaskSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskSync
        fields = '__all__'