from django.contrib import admin
from django.http import HttpResponseRedirect
from django.urls import path, reverse
from django.contrib import messages
from django.utils.html import format_html
from .models import Team, Task, EmailConfig, N8nConfig, ClickUpConfig, TaskSync, RedisConfig, AssignmentRule

@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ('name', 'email', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('name', 'email')


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('job_id', 'status', 'priority', 'task_type', 'assign_to', 'source', 'created_at')
    list_filter = ('status', 'priority', 'task_type', 'source')
    search_fields = ('job_id', 'email_subject', 'task_detail', 'external_id')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(EmailConfig)
class EmailConfigAdmin(admin.ModelAdmin):
    list_display = ('provider', 'host', 'is_active', 'test_connection')
    list_filter = ('is_active', 'provider')
    search_fields = ('host', 'username')

    def test_connection(self, obj):
        return format_html(
            '<form method="post" action="{}" style="display:inline;">{{% csrf_token %}}<button type="submit" class="btn btn-sm btn-outline-success py-0">Test</button></form>',
            reverse('admin:tasks_emailconfig_test', args=[obj.pk])
        )
    test_connection.short_description = 'Test Connection'
    test_connection.allow_tags = True

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:pk>/test/',
                self.admin_site.admin_view(self.test_view),
                name='tasks_emailconfig_test',
            ),
        ]
        return custom_urls + urls

    def test_view(self, request, pk):
        from .views import _test_email_config
        obj = self.get_object(request, pk)
        result = _test_email_config(obj, obj.username)
        level = messages.SUCCESS if result['ok'] else messages.ERROR
        self.message_user(request, result['message'], level=level)
        return HttpResponseRedirect(reverse('admin:tasks_emailconfig_change', args=[pk]))

    def response_change(self, request, obj):
        if '_test_email' in request.POST:
            from django.contrib import messages
            from .views import _test_email_config
            result = _test_email_config(obj, obj.username)
            level = messages.SUCCESS if result['ok'] else messages.ERROR
            messages.add_message(request, level, result['message'])
        return super().response_change(request, obj)

    def change_view(self, request, object_id, form_url='', extra_context=None):
        extra_context = extra_context or {}
        extra_context['show_test_button'] = True
        return super().change_view(request, object_id, form_url, extra_context)


@admin.register(N8nConfig)
class N8nConfigAdmin(admin.ModelAdmin):
    list_display = ('base_url', 'is_active', 'test_connection')
    list_filter = ('is_active',)
    search_fields = ('base_url',)

    def test_connection(self, obj):
        return format_html(
            '<form method="post" action="{}" style="display:inline;">{{% csrf_token %}}<button type="submit" class="btn btn-sm btn-outline-success py-0">Test</button></form>',
            reverse('admin:tasks_n8nconfig_test', args=[obj.pk])
        )
    test_connection.short_description = 'Test Connection'
    test_connection.allow_tags = True

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:pk>/test/',
                self.admin_site.admin_view(self.test_view),
                name='tasks_n8nconfig_test',
            ),
        ]
        return custom_urls + urls

    def test_view(self, request, pk):
        from .views import _test_n8n_config
        obj = self.get_object(request, pk)
        result = _test_n8n_config(obj)
        level = messages.SUCCESS if result['ok'] else messages.ERROR
        self.message_user(request, result['message'], level=level)
        return HttpResponseRedirect(reverse('admin:tasks_n8nconfig_change', args=[pk]))

    def change_view(self, request, object_id, form_url='', extra_context=None):
        extra_context = extra_context or {}
        extra_context['show_test_button'] = True
        return super().change_view(request, object_id, form_url, extra_context)


@admin.register(TaskSync)
class TaskSyncAdmin(admin.ModelAdmin):
    list_display = ('source', 'external_id', 'task', 'synced_at')
    list_filter = ('source', 'synced_at')
    search_fields = ('external_id', 'task__job_id')
    readonly_fields = ('synced_at',)


@admin.register(RedisConfig)
class RedisConfigAdmin(admin.ModelAdmin):
    list_display = ('url', 'is_active', 'test_connection')
    list_filter = ('is_active',)
    search_fields = ('url',)

    def test_connection(self, obj):
        return format_html(
            '<form method="post" action="{}" style="display:inline;">{{% csrf_token %}}<button type="submit" class="btn btn-sm btn-outline-success py-0">Test</button></form>',
            reverse('admin:tasks_redisconfig_test', args=[obj.pk])
        )
    test_connection.short_description = 'Test Connection'
    test_connection.allow_tags = True

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:pk>/test/',
                self.admin_site.admin_view(self.test_view),
                name='tasks_redisconfig_test',
            ),
        ]
        return custom_urls + urls

    def test_view(self, request, pk):
        from .views import _test_redis_config
        obj = self.get_object(request, pk)
        result = _test_redis_config(obj)
        level = messages.SUCCESS if result['ok'] else messages.ERROR
        self.message_user(request, result['message'], level=level)
        return HttpResponseRedirect(reverse('admin:tasks_redisconfig_change', args=[pk]))

    def change_view(self, request, object_id, form_url='', extra_context=None):
        extra_context = extra_context or {}
        extra_context['show_test_button'] = True
        return super().change_view(request, object_id, form_url, extra_context)


@admin.register(AssignmentRule)
class AssignmentRuleAdmin(admin.ModelAdmin):
    list_display = ('keyword', 'team', 'is_active')
    list_filter = ('is_active', 'team')
    search_fields = ('keyword', 'team__name')


@admin.register(ClickUpConfig)
class ClickUpConfigAdmin(admin.ModelAdmin):
    list_display = ('workspace_id', 'is_active', 'test_connection')
    list_filter = ('is_active',)
    search_fields = ('workspace_id',)

    def test_connection(self, obj):
        return format_html(
            '<form method="post" action="{}" style="display:inline;">{{% csrf_token %}}<button type="submit" class="btn btn-sm btn-outline-success py-0">Test</button></form>',
            reverse('admin:tasks_clickupconfig_test', args=[obj.pk])
        )
    test_connection.short_description = 'Test Connection'
    test_connection.allow_tags = True

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:pk>/test/',
                self.admin_site.admin_view(self.test_view),
                name='tasks_clickupconfig_test',
            ),
        ]
        return custom_urls + urls

    def test_view(self, request, pk):
        obj = self.get_object(request, pk)
        from .views import _test_clickup_config
        result = _test_clickup_config(obj)
        level = messages.SUCCESS if result['ok'] else messages.ERROR
        self.message_user(request, result['message'], level=level)
        return HttpResponseRedirect(reverse('admin:tasks_clickupconfig_change', args=[pk]))

    def change_view(self, request, object_id, form_url='', extra_context=None):
        extra_context = extra_context or {}
        extra_context['show_test_button'] = True
        return super().change_view(request, object_id, form_url, extra_context)
