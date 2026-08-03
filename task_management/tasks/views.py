from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.shortcuts import render, get_object_or_404, redirect
from django.views.decorators.http import require_http_methods, require_POST
from django.core.paginator import Paginator
from django.utils import timezone
from django.http import HttpResponse, JsonResponse
from django.core.mail import EmailMessage
from django.core.mail.backends.smtp import EmailBackend as SMTPBackend
from datetime import datetime, timedelta
from django.db.models import Count, Q
from django.core.cache import cache
import json
import requests
from redis import Redis
from urllib3.exceptions import InsecureRequestWarning
import urllib3
urllib3.disable_warnings(InsecureRequestWarning)
from .models import Team, Task, EmailConfig, N8nConfig, ClickUpConfig, WhatsAppConfig, TelegramConfig, DatabaseConfig, TaskSync, RedisConfig, AssignmentRule, ActionNetworkConfig, PROVIDER_PRESETS
from .serializers import (
    TeamSerializer, TaskSerializer,
    TaskCreateSerializer, TaskUpdateSerializer,
    SyncRequestSerializer, SyncItemSerializer, TaskSyncSerializer,
)

# ---------------------------------------------------------------------------
# Cache keys & TTLs
# ---------------------------------------------------------------------------
CACHE_DASHBOARD   = 'dashboard_stats'
CACHE_BY_STATUS   = 'tasks_by_status'
CACHE_BY_PRIORITY = 'tasks_by_priority'
CACHE_BY_TEAM     = 'tasks_by_team'
CACHE_TEAMS_ALL   = 'teams_all'
CACHE_REPORTS     = 'reports_data'
CACHE_TASK_TYPES  = 'task_types_list'

TTL_DASHBOARD = 120
TTL_REPORTS   = 300
TTL_TEAMS     = 600

STATUS_CHOICES = [
    'Open', 'Assigned', 'In Progress', 'Pending User',
    'Pending Vendor', 'Completed', 'Closed', 'Rejected', 'Cancelled',
]
PRIORITY_CHOICES = ['High', 'Medium', 'Low']


def _invalidate_task_caches():
    cache.delete_many([
        CACHE_DASHBOARD, CACHE_BY_STATUS, CACHE_BY_PRIORITY,
        CACHE_BY_TEAM, CACHE_REPORTS, CACHE_TASK_TYPES,
    ])


def _invalidate_team_caches():
    cache.delete_many([
        CACHE_TEAMS_ALL, CACHE_BY_TEAM, CACHE_DASHBOARD, CACHE_REPORTS,
    ])


def _get_dashboard_metrics():
    cached = cache.get(CACHE_DASHBOARD)
    if cached is not None:
        return cached
    now = datetime.now()
    data = {
        'total':         Task.objects.count(),
        'open':          Task.objects.filter(status='Open').count(),
        'assigned':      Task.objects.filter(status='Assigned').count(),
        'in_progress':   Task.objects.filter(status='In Progress').count(),
        'closed':        Task.objects.filter(status='Closed').count(),
        'high_priority': Task.objects.filter(priority='High').count(),
        'overdue':       Task.objects.filter(
                             status__in=['Open', 'Assigned', 'In Progress'],
                             closed_at__lt=now,
                         ).count(),
    }
    cache.set(CACHE_DASHBOARD, data, TTL_DASHBOARD)
    return data


# ---------------------------------------------------------------------------
# DRF ViewSets (API)
# ---------------------------------------------------------------------------

class TeamViewSet(viewsets.ModelViewSet):
    queryset = Team.objects.all()
    serializer_class = TeamSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['name']
    ordering_fields = ['name', 'is_active']

    def list(self, request, *args, **kwargs):
        cached = cache.get(CACHE_TEAMS_ALL)
        if cached is not None:
            return Response(cached)
        response = super().list(request, *args, **kwargs)
        cache.set(CACHE_TEAMS_ALL, response.data, TTL_TEAMS)
        return response

    def perform_create(self, serializer):
        serializer.save()
        _invalidate_team_caches()

    def perform_update(self, serializer):
        serializer.save()
        _invalidate_team_caches()

    def perform_destroy(self, instance):
        instance.delete()
        _invalidate_team_caches()


class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'priority', 'task_type', 'assign_to']
    search_fields = ['job_id', 'email_from', 'email_subject', 'task_detail']
    ordering_fields = ['created_at', 'updated_at', 'priority', 'status']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'create':
            return TaskCreateSerializer
        if self.action in ['update', 'partial_update']:
            return TaskUpdateSerializer
        return TaskSerializer

    def perform_create(self, serializer):
        serializer.save()
        _invalidate_task_caches()

    def perform_update(self, serializer):
        serializer.save()
        _invalidate_task_caches()

    def perform_destroy(self, instance):
        instance.delete()
        _invalidate_task_caches()

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        return Response(_get_dashboard_metrics())

    @action(detail=False, methods=['get'])
    def by_status(self, request):
        cached = cache.get(CACHE_BY_STATUS)
        if cached is not None:
            return Response(cached)
        data = list(Task.objects.values('status').annotate(count=Count('id')).order_by('status'))
        cache.set(CACHE_BY_STATUS, data, TTL_DASHBOARD)
        return Response(data)

    @action(detail=False, methods=['get'])
    def by_priority(self, request):
        cached = cache.get(CACHE_BY_PRIORITY)
        if cached is not None:
            return Response(cached)
        data = list(Task.objects.values('priority').annotate(count=Count('id')).order_by('priority'))
        cache.set(CACHE_BY_PRIORITY, data, TTL_DASHBOARD)
        return Response(data)

    @action(detail=False, methods=['get'])
    def by_team(self, request):
        cached = cache.get(CACHE_BY_TEAM)
        if cached is not None:
            return Response(cached)
        data = list(Task.objects.values('assign_to__name').annotate(count=Count('id')).order_by('-count'))
        cache.set(CACHE_BY_TEAM, data, TTL_DASHBOARD)
        return Response(data)

    @action(detail=False, methods=['post'])
    def sync(self, request):
        """Sync tasks from external apps (email, teams, clickup, whatsapp, telegram)."""
        serializer = SyncRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        source = data['source']

        created = 0
        updated = 0
        skipped = 0
        errors = []

        for item in data['items']:
            external_id = item['external_id']
            title = item['title']
            description = item.get('description', '')
            status = item.get('status', 'Open')
            priority = item.get('priority', 'Medium')
            assignee_name = item.get('assignee', '').strip()
            url = item.get('url', '')
            raw = item.get('raw', {})

            job_id = item.get('job_id') or f'{source}-{external_id}'
            email_from = ''
            email_subject = title
            task_type = source.title()

            if status == 'Closed' and not item.get('updated_at'):
                closed_at = timezone.now()
            else:
                closed_at = None

            assign_to = None
            if assignee_name:
                assign_to = Team.objects.filter(name__iexact=assignee_name).first()

            try:
                task, task_created = Task.objects.update_or_create(
                    external_id=external_id,
                    defaults={
                        'job_id':     job_id,
                        'email_from': email_from,
                        'email_subject': email_subject,
                        'task_type':  task_type,
                        'task_detail': description,
                        'priority':   priority,
                        'status':     status,
                        'assign_to':  assign_to,
                        'source':    source,
                        'closed_at': closed_at,
                    },
                )
                if task_created:
                    created += 1
                else:
                    updated += 1

                TaskSync.objects.update_or_create(
                    source=source,
                    external_id=external_id,
                    defaults={
                        'task':  task,
                        'raw':  raw,
                    },
                )
            except Exception as e:
                skipped += 1
                errors.append({'external_id': external_id, 'error': str(e)})

        _invalidate_task_caches()
        return Response({
            'source': source,
            'created': created,
            'updated': updated,
            'skipped': skipped,
            'errors': errors,
        })


# ---------------------------------------------------------------------------
# HTMX partials (dashboard cards)
# ---------------------------------------------------------------------------

@login_required
def partial_by_status(request):
    data = (
        cache.get(CACHE_BY_STATUS)
        or list(Task.objects.values('status').annotate(count=Count('id')).order_by('status'))
    )
    return render(request, 'tasks/partials/by_status.html', {'rows': data})


@login_required
def partial_by_priority(request):
    data = (
        cache.get(CACHE_BY_PRIORITY)
        or list(Task.objects.values('priority').annotate(count=Count('id')).order_by('priority'))
    )
    return render(request, 'tasks/partials/by_priority.html', {'rows': data})


@login_required
def partial_by_team(request):
    data = (
        cache.get(CACHE_BY_TEAM)
        or list(Task.objects.values('assign_to__name').annotate(count=Count('id')).order_by('-count'))
    )
    return render(request, 'tasks/partials/by_team.html', {'rows': data})


# ---------------------------------------------------------------------------
# Template views — Dashboard
# ---------------------------------------------------------------------------

@login_required
def dashboard_page(request):
    metrics = _get_dashboard_metrics()
    recent_tasks = Task.objects.select_related('assign_to').all()[:10]
    return render(request, 'tasks/dashboard.html', {
        'metrics': metrics,
        'recent_tasks': recent_tasks,
    })


# ---------------------------------------------------------------------------
# Template views — Task list with filtering + pagination
# ---------------------------------------------------------------------------

def _get_task_types():
    tt = cache.get(CACHE_TASK_TYPES)
    if tt is None:
        tt = list(Task.objects.values_list('task_type', flat=True).distinct().order_by('task_type'))
        cache.set(CACHE_TASK_TYPES, tt, TTL_REPORTS)
    return tt


@login_required
def task_list_page(request):
    qs = Task.objects.select_related('assign_to').all()

    search   = request.GET.get('search', '').strip()
    status   = request.GET.get('status', '').strip()
    priority = request.GET.get('priority', '').strip()
    task_type = request.GET.get('task_type', '').strip()

    if search:
        qs = qs.filter(
            Q(job_id__icontains=search) |
            Q(email_from__icontains=search) |
            Q(email_subject__icontains=search) |
            Q(task_detail__icontains=search)
        )
    if status:
        qs = qs.filter(status=status)
    if priority:
        qs = qs.filter(priority=priority)
    if task_type:
        qs = qs.filter(task_type=task_type)

    paginator = Paginator(qs, 20)
    page_obj  = paginator.get_page(request.GET.get('page', 1))

    # HTMX: return only the rows partial
    if request.headers.get('HX-Request') and request.headers.get('HX-Target') == 'task-table-body':
        return render(request, 'tasks/partials/task_rows.html', {'page_obj': page_obj})

    teams = Team.objects.filter(is_active=True)
    return render(request, 'tasks/task_list.html', {
        'page_obj':        page_obj,
        'task_types':      _get_task_types(),
        'status_choices':  STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
        'teams':           teams,
        'filters': {
            'search': search, 'status': status,
            'priority': priority, 'task_type': task_type,
        },
    })


@login_required
def task_rows_partial(request):
    """Dedicated HTMX endpoint for filtering — avoids full-page reload."""
    return task_list_page(request)


# ---------------------------------------------------------------------------
# Template views — Task create
# ---------------------------------------------------------------------------

@login_required
def task_create_page(request):
    teams = Team.objects.filter(is_active=True)
    errors = {}
    form_data = {}

    if request.method == 'POST':
        form_data = request.POST
        required = ['email_from', 'email_subject', 'task_type', 'task_detail', 'priority']
        for f in required:
            if not request.POST.get(f, '').strip():
                errors[f] = 'This field is required.'

        if not errors:
            assign_to_id = request.POST.get('assign_to') or None
            job_id = request.POST.get('job_id', '').strip() or Task.get_next_job_id()
            Task.objects.create(
                job_id        = job_id,
                email_from    = request.POST['email_from'].strip(),
                email_subject = request.POST['email_subject'].strip(),
                task_type     = request.POST['task_type'].strip(),
                task_detail   = request.POST['task_detail'].strip(),
                priority      = request.POST['priority'],
                status        = request.POST.get('status', 'Open'),
                note          = request.POST.get('note', '').strip(),
                assign_to_id  = assign_to_id,
            )
            _invalidate_task_caches()
            if request.headers.get('HX-Request'):
                response = HttpResponse(status=204)
                response['HX-Redirect'] = '/tasks/'
                return response
            return redirect('task-list')

    next_job_id = Task.get_next_job_id()
    return render(request, 'tasks/task_create.html', {
        'teams':            teams,
        'status_choices':   STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
        'errors':           errors,
        'form_data':        form_data,
        'next_job_id':      next_job_id,
    })


# ---------------------------------------------------------------------------
# Template views — Task detail
# ---------------------------------------------------------------------------

@login_required
def task_detail_page(request, pk):
    task = get_object_or_404(Task.objects.select_related('assign_to'), pk=pk)
    teams = Team.objects.filter(is_active=True)
    return render(request, 'tasks/task_detail.html', {
        'task':             task,
        'teams':            teams,
        'status_choices':   STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
    })


# ---------------------------------------------------------------------------
# Template views — Task edit
# ---------------------------------------------------------------------------

@login_required
def task_edit_page(request, pk):
    task = get_object_or_404(Task, pk=pk)
    teams = Team.objects.filter(is_active=True)
    errors = {}

    if request.method == 'POST':
        required = ['email_from', 'email_subject', 'task_type', 'task_detail', 'priority']
        for f in required:
            if not request.POST.get(f, '').strip():
                errors[f] = 'This field is required.'

        if not errors:
            assign_to_id = request.POST.get('assign_to') or None
            task.email_from    = request.POST['email_from'].strip()
            task.email_subject = request.POST['email_subject'].strip()
            task.task_type     = request.POST['task_type'].strip()
            task.task_detail   = request.POST['task_detail'].strip()
            task.priority      = request.POST['priority']
            task.status        = request.POST.get('status', task.status)
            task.note          = request.POST.get('note', task.note or '').strip()
            task.assign_to_id  = assign_to_id
            if task.status == 'Closed' and not task.closed_at:
                task.closed_at = timezone.now()
            task.save()
            _invalidate_task_caches()
            return redirect('task-detail', pk=task.pk)

    return render(request, 'tasks/task_edit.html', {
        'task':             task,
        'teams':            teams,
        'status_choices':   STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
        'errors':           errors,
    })


# ---------------------------------------------------------------------------
# HTMX actions
# ---------------------------------------------------------------------------

@require_http_methods(['POST'])
@login_required
def task_update_status(request, pk):
    task = get_object_or_404(Task, pk=pk)
    new_status = request.POST.get('status', '').strip()
    if new_status in STATUS_CHOICES:
        task.status = new_status
        if new_status == 'Closed' and not task.closed_at:
            task.closed_at = timezone.now()
        task.save(update_fields=['status', 'closed_at'])
        _invalidate_task_caches()
    return render(request, 'tasks/partials/status_badge.html', {'task': task})


@require_http_methods(['POST'])
@login_required
def task_add_note(request, pk):
    task = get_object_or_404(Task, pk=pk)
    note = request.POST.get('note', '').strip()
    if note:
        task.note = f"{task.note}\n\n{note}".strip() if task.note else note
        task.save(update_fields=['note'])
        _invalidate_task_caches()
    return render(request, 'tasks/partials/note_block.html', {'task': task})


@require_http_methods(['POST'])
@login_required
def task_delete(request, pk):
    task = get_object_or_404(Task, pk=pk)
    task.delete()
    _invalidate_task_caches()
    # Return an empty 200 — HTMX will swap out the row
    return HttpResponse(status=200)


@login_required
def task_assign_form(request, pk):
    """Return the assign form HTML for the modal."""
    task = get_object_or_404(Task, pk=pk)
    teams = Team.objects.filter(is_active=True)
    return render(request, 'tasks/partials/assign_form.html', {
        'task': task, 'teams': teams,
    })


@require_http_methods(['POST'])
@login_required
def task_do_assign(request, pk):
    task = get_object_or_404(Task, pk=pk)
    assign_to_id = request.POST.get('assign_to') or None
    task.assign_to_id = assign_to_id
    if assign_to_id and task.status == 'Open':
        task.status = 'Assigned'
    task.save(update_fields=['assign_to_id', 'status'])
    _invalidate_task_caches()
    if request.headers.get('HX-Request'):
        response = HttpResponse(status=204)
        response['HX-Redirect'] = '/assignment/'
        return response
    return redirect('assignment')


# ---------------------------------------------------------------------------
# Template views — Assignment
# ---------------------------------------------------------------------------

@login_required
def assignment_page(request):
    unassigned = Task.objects.filter(assign_to__isnull=True).select_related('assign_to')
    teams = Team.objects.all()
    # Per-team task counts
    team_counts = {
        row['assign_to']: row['count']
        for row in Task.objects.filter(assign_to__isnull=False)
                               .values('assign_to')
                               .annotate(count=Count('id'))
    }
    teams_with_counts = [
        {'team': t, 'count': team_counts.get(t.pk, 0)} for t in teams
    ]
    return render(request, 'tasks/assignment.html', {
        'unassigned_tasks':   unassigned,
        'teams_with_counts':  teams_with_counts,
    })


# ---------------------------------------------------------------------------
# Template views — Reports
# ---------------------------------------------------------------------------

@login_required
def reports_page(request):
    cached = cache.get(CACHE_REPORTS)
    if cached:
        return render(request, 'tasks/reports.html', {'report': cached})

    now         = timezone.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start  = today_start - timedelta(days=today_start.weekday())
    month_start = today_start.replace(day=1)

    # 7-day trend
    trend = []
    for i in range(6, -1, -1):
        day_start = today_start - timedelta(days=i)
        day_end   = day_start + timedelta(days=1)
        trend.append({
            'date':    day_start,
            'created': Task.objects.filter(created_at__gte=day_start, created_at__lt=day_end).count(),
            'closed':  Task.objects.filter(status='Closed', closed_at__gte=day_start, closed_at__lt=day_end).count(),
            'open':    Task.objects.filter(created_at__lt=day_end)
                                   .exclude(status__in=['Closed', 'Cancelled', 'Rejected']).count(),
        })

    report = {
        'open':             Task.objects.filter(status='Open').count(),
        'in_progress':      Task.objects.filter(status='In Progress').count(),
        'closed_today':     Task.objects.filter(status='Closed', closed_at__gte=today_start).count(),
        'overdue':          Task.objects.filter(
                                status__in=['Open', 'Assigned', 'In Progress'],
                                closed_at__lt=now,
                            ).count(),
        'weekly_created':   Task.objects.filter(created_at__gte=week_start).count(),
        'weekly_closed':    Task.objects.filter(status='Closed', closed_at__gte=week_start).count(),
        'avg_resolution':   '—',
        'monthly_created':  Task.objects.filter(created_at__gte=month_start).count(),
        'monthly_closed':   Task.objects.filter(status='Closed', closed_at__gte=month_start).count(),
        'sla_compliance':   0,
        'trend':            trend,
    }
    cache.set(CACHE_REPORTS, report, TTL_REPORTS)
    return render(request, 'tasks/reports.html', {'report': report})


# ---------------------------------------------------------------------------
# Template views — Admin page
# ---------------------------------------------------------------------------

@login_required
def admin_page(request):
    if request.method == 'POST' and request.POST.get('flush_cache'):
        cache.clear()
    teams = Team.objects.all()
    email_cfg = EmailConfig.get()
    return render(request, 'tasks/admin_page.html', {
        'teams':      teams,
        'email_cfg':  email_cfg,
        'presets':    json.dumps(PROVIDER_PRESETS),
    })


# ---------------------------------------------------------------------------
# Email configuration views
# ---------------------------------------------------------------------------

@login_required
@require_http_methods(['POST'])
def email_config_save(request):
    """Save SMTP configuration from the admin page form."""
    cfg = EmailConfig.get()

    cfg.provider   = request.POST.get('provider', 'custom')
    cfg.host       = request.POST.get('host', '').strip()
    cfg.port       = int(request.POST.get('port', 587) or 587)
    cfg.username   = request.POST.get('username', '').strip()
    cfg.use_tls    = request.POST.get('use_tls') == '1'
    cfg.use_ssl    = request.POST.get('use_ssl') == '1'
    cfg.from_email = request.POST.get('from_email', '').strip()
    cfg.from_name  = request.POST.get('from_name', '').strip()
    cfg.is_active  = request.POST.get('is_active') == '1'

    # Only update password if a new one was submitted
    new_password = request.POST.get('password', '').strip()
    if new_password:
        cfg.password = new_password

    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'Configuration saved successfully.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


def _test_email_config(cfg, to_addr=None):
    if not cfg.is_active or not cfg.host or not cfg.username:
        return {'ok': False, 'message': 'Email is not configured or not active. Save a valid config first.'}
    to_addr = (to_addr or '').strip() or cfg.username
    try:
        backend = SMTPBackend(
            host=cfg.host,
            port=cfg.port,
            username=cfg.username,
            password=cfg.password,
            use_tls=cfg.use_tls,
            use_ssl=cfg.use_ssl,
            timeout=10,
            fail_silently=False,
        )
        mail = EmailMessage(
            subject='[TaskMgmt] Test Email',
            body=(
                'This is a test email from Task Management.\n\n'
                f'Provider : {cfg.get_provider_display()}\n'
                f'Host     : {cfg.host}:{cfg.port}\n'
                f'TLS      : {cfg.use_tls}  SSL: {cfg.use_ssl}\n'
            ),
            from_email=cfg.get_from_address(),
            to=[to_addr],
            connection=backend,
        )
        mail.send()
        return {'ok': True, 'message': f'Test email sent to {to_addr}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Failed: {e}'}


@login_required
@require_http_methods(['POST'])
def email_config_test(request):
    """Send a test email using the currently saved SMTP config."""
    cfg = EmailConfig.get()
    result = _test_email_config(cfg, request.POST.get('test_to', ''))

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


# ---------------------------------------------------------------------------
# n8n configuration views
# ---------------------------------------------------------------------------

@login_required
def admin_page(request):
    if request.method == 'POST' and request.POST.get('flush_cache'):
        cache.clear()
    teams = Team.objects.all()
    email_cfg = EmailConfig.get()
    n8n_cfg = N8nConfig.get()
    clickup_cfg = ClickUpConfig.get()
    whatsapp_cfg = WhatsAppConfig.get()
    telegram_cfg = TelegramConfig.get()
    database_cfg = DatabaseConfig.get()
    redis_cfg = RedisConfig.get()
    assignment_rules = AssignmentRule.objects.select_related('team').all()

    from django.contrib.admin.sites import site
    admin_app_list = site.get_app_list(request)

    return render(request, 'tasks/admin_page.html', {
        'teams':            teams,
        'email_cfg':        email_cfg,
        'n8n_cfg':          n8n_cfg,
        'clickup_cfg':      clickup_cfg,
        'whatsapp_cfg':     whatsapp_cfg,
        'telegram_cfg':     telegram_cfg,
        'database_cfg':     database_cfg,
        'redis_cfg':        redis_cfg,
        'assignment_rules': assignment_rules,
        'presets':          json.dumps(PROVIDER_PRESETS),
        'admin_app_list':   admin_app_list,
    })


@login_required
@require_http_methods(['POST'])
def n8n_config_save(request):
    """Save n8n configuration from the admin page form."""
    cfg = N8nConfig.get()

    cfg.base_url  = request.POST.get('base_url', '').strip() or 'http://localhost:5678'
    cfg.api_key   = request.POST.get('api_key', '').strip()
    cfg.is_active = request.POST.get('is_active') == '1'

    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'n8n configuration saved successfully.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


def _test_n8n_config(cfg):
    base_url = cfg.base_url.rstrip('/')
    if not cfg.is_active or not base_url:
        return {'ok': False, 'message': 'n8n is not configured or not active. Save a valid config first.'}
    try:
        headers = {}
        if cfg.api_key:
            headers['X-N8N-API-KEY'] = cfg.api_key
        resp = requests.get(f'{base_url}/healthz', headers=headers, timeout=10)
        if resp.status_code == 200:
            return {'ok': True, 'message': f'n8n is reachable at {base_url}.'}
        return {'ok': False, 'message': f'n8n responded with status {resp.status_code}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


@login_required
@require_http_methods(['POST'])
def n8n_config_test(request):
    """Test connectivity to the n8n instance."""
    cfg = N8nConfig.get()
    result = _test_n8n_config(cfg)

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


# ---------------------------------------------------------------------------
# ClickUp configuration views
# ---------------------------------------------------------------------------

def _test_clickup_config(cfg):
    if not cfg.is_active or not cfg.api_token:
        return {'ok': False, 'message': 'ClickUp is not configured or not active. Save an API token first.'}
    try:
        headers = {'Authorization': f'Bearer {cfg.api_token}'}
        resp = requests.get('https://api.clickup.com/api/v2/user', headers=headers, timeout=10, verify=False)
        if resp.status_code == 200:
            user = resp.json().get('user', {})
            return {'ok': True, 'message': f'ClickUp connected as {user.get("email", "unknown user")}.'}
        if resp.status_code == 401:
            return {'ok': False, 'message': 'Unauthorized (401). The API token is invalid or expired. Generate a new Personal API Key in ClickUp Settings > Apps.'}
        return {'ok': False, 'message': f'ClickUp responded with status {resp.status_code}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


@login_required
@require_http_methods(['POST'])
def clickup_config_save(request):
    """Save ClickUp configuration from the admin page form."""
    cfg = ClickUpConfig.get()

    cfg.api_token    = request.POST.get('api_token', '').strip()
    cfg.workspace_id = request.POST.get('workspace_id', '').strip()
    cfg.is_active    = request.POST.get('is_active') == '1'

    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'ClickUp configuration saved successfully.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


@login_required
@require_http_methods(['POST'])
def clickup_config_test(request, cfg=None):
    """Test connectivity to the ClickUp API."""
    if cfg is None:
        cfg = ClickUpConfig.get()

    result = _test_clickup_config(cfg)

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


# ---------------------------------------------------------------------------
# Redis configuration views
# ---------------------------------------------------------------------------

@login_required
@require_http_methods(['POST'])
def redis_config_save(request):
    """Save Redis configuration from the admin page form."""
    cfg = RedisConfig.get()

    cfg.url = request.POST.get('url', '').strip() or 'redis://localhost:6379/0'
    cfg.is_active = request.POST.get('is_active') == '1'

    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'Redis configuration saved. Restart the server to apply.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


def _test_redis_config(cfg):
    url = cfg.url.strip()
    if not cfg.is_active or not url:
        return {'ok': False, 'message': 'Redis is not configured or not active. Save a valid URL first.'}
    try:
        client = Redis.from_url(url, socket_connect_timeout=5, socket_timeout=5)
        client.ping()
        return {'ok': True, 'message': f'Redis is reachable at {url}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


@login_required
@require_http_methods(['POST'])
def redis_config_test(request):
    """Test connectivity to the configured Redis instance."""
    cfg = RedisConfig.get()
    result = _test_redis_config(cfg)

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


# ---------------------------------------------------------------------------
# Database configuration views
# ---------------------------------------------------------------------------

@login_required
@require_http_methods(['POST'])
def database_config_save(request):
    """Save database configuration from the admin page form."""
    cfg = DatabaseConfig.get()

    cfg.engine    = request.POST.get('engine', 'postgresql')
    cfg.name      = request.POST.get('name', '').strip()
    cfg.user      = request.POST.get('user', '').strip()
    cfg.password  = request.POST.get('password', '').strip()
    cfg.host      = request.POST.get('host', '').strip()
    cfg.port      = request.POST.get('port', '').strip()
    cfg.is_active = request.POST.get('is_active') == '1'

    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'Database configuration saved. Restart the server to apply.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


def _test_database_config(cfg):
    """Test database connectivity and return result dict."""
    if not cfg.is_active or not cfg.name:
        return {
            'ok': False,
            'message': 'Database is not configured or not active. Save a valid config first.',
        }
    try:
        if cfg.engine == 'sqlite3':
            import sqlite3
            conn = sqlite3.connect(cfg.name)
            conn.close()
            return {'ok': True, 'message': f'SQLite3 connection successful: {cfg.name}'}
        else:
            import psycopg2
            conn = psycopg2.connect(
                dbname=cfg.name,
                user=cfg.user,
                password=cfg.password,
                host=cfg.host,
                port=cfg.port,
                connect_timeout=5,
            )
            conn.close()
            return {'ok': True, 'message': f'Database connection successful: {cfg.name}@{cfg.host}:{cfg.port}'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


@login_required
@require_http_methods(['POST'])
def database_config_test(request, cfg=None):
    """Test connectivity to the configured database."""
    if cfg is None:
        cfg = DatabaseConfig.get()

    result = _test_database_config(cfg)

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


def _test_whatsapp_config(cfg):
    if not cfg.is_active or not cfg.api_token:
        return {'ok': False, 'message': 'WhatsApp is not configured or not active. Save an API token first.'}
    return {'ok': True, 'message': f'WhatsApp config saved ({cfg.phone_number_id or "no phone number"}).'}


def _test_telegram_config(cfg):
    if not cfg.is_active or not cfg.bot_token:
        return {'ok': False, 'message': 'Telegram is not configured or not active. Save a bot token first.'}
    try:
        resp = requests.get(f'https://api.telegram.org/bot{cfg.bot_token}/getMe', timeout=10, verify=False)
        if resp.status_code == 200:
            bot = resp.json().get('result', {})
            return {'ok': True, 'message': f'Telegram connected as @{bot.get("username", "unknown")}.'}
        return {'ok': False, 'message': f'Telegram responded with status {resp.status_code}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


@login_required
@require_http_methods(['POST'])
def whatsapp_config_save(request):
    cfg = WhatsAppConfig.get()
    cfg.api_token         = request.POST.get('api_token', '').strip()
    cfg.phone_number_id   = request.POST.get('phone_number_id', '').strip()
    cfg.business_account_id = request.POST.get('business_account_id', '').strip()
    cfg.is_active         = request.POST.get('is_active') == '1'
    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'WhatsApp configuration saved.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}
    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


@login_required
@require_http_methods(['POST'])
def whatsapp_config_test(request, cfg=None):
    if cfg is None:
        cfg = WhatsAppConfig.get()
    result = _test_whatsapp_config(cfg)
    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


@login_required
@require_http_methods(['POST'])
def telegram_config_save(request):
    cfg = TelegramConfig.get()
    cfg.bot_token = request.POST.get('bot_token', '').strip()
    cfg.chat_id   = request.POST.get('chat_id', '').strip()
    cfg.is_active = request.POST.get('is_active') == '1'
    try:
        cfg.full_clean()
        cfg.save()
        msg = {'ok': True, 'message': 'Telegram configuration saved.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}
    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


@login_required
@require_http_methods(['POST'])
def telegram_config_test(request, cfg=None):
    if cfg is None:
        cfg = TelegramConfig.get()
    result = _test_telegram_config(cfg)
    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if result['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if result['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{result["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


# ---------------------------------------------------------------------------
# Assignment rule views
# ---------------------------------------------------------------------------

@login_required
@require_http_methods(['POST'])
def assignment_rule_add(request):
    """Add a new assignment rule."""
    keyword = request.POST.get('keyword', '').strip()
    team_id = request.POST.get('team_id')
    is_active = request.POST.get('is_active') == '1'

    if not keyword or not team_id:
        msg = {'ok': False, 'message': 'Keyword and team are required.'}
    else:
        team = get_object_or_404(Team, pk=team_id)
        try:
            rule, created = AssignmentRule.objects.get_or_create(
                keyword=keyword,
                defaults={'team': team, 'is_active': is_active},
            )
            if not created:
                rule.team = team
                rule.is_active = is_active
                rule.save()
            msg = {'ok': True, 'message': f'Rule "{keyword}" saved.'}
        except Exception as e:
            msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


@login_required
@require_http_methods(['POST'])
def assignment_rule_delete(request, keyword):
    """Delete an assignment rule."""
    try:
        rule = AssignmentRule.objects.get(pk=keyword)
        rule.delete()
        msg = {'ok': True, 'message': f'Rule "{keyword}" deleted.'}
    except AssignmentRule.DoesNotExist:
        msg = {'ok': False, 'message': 'Rule not found.'}
    except Exception as e:
        msg = {'ok': False, 'message': str(e)}

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if msg['ok'] else 'alert-danger'
        icon = 'fa-circle-check' if msg['ok'] else 'fa-circle-xmark'
        html = (
            f'<div class="alert {status_class} py-2 mb-0 d-flex align-items-center gap-2">'
            f'<i class="fa {icon}"></i>{msg["message"]}</div>'
        )
        return HttpResponse(html)
    return redirect('admin-page')


# ---------------------------------------------------------------------------
# Webhook / External integration views
# ---------------------------------------------------------------------------

@require_http_methods(['POST'])
def n8n_webhook(request):
    """Receive data from n8n workflows and sync to task database."""
    try:
        data = json.loads(request.body)
        source = data.get('source', 'n8n')
        items = data.get('items', [])
        
        if not isinstance(items, list) or not items:
            return JsonResponse({'status': 'error', 'message': 'items must be a non-empty array'}, status=400)
        
        created = 0
        updated = 0
        skipped = 0
        errors = []

        for item in items:
            external_id = item.get('external_id')
            title = item.get('title')
            if not external_id or not title:
                skipped += 1
                errors.append({'external_id': external_id or 'missing', 'error': 'external_id and title are required'})
                continue

            description = item.get('description', '')
            status = item.get('status', 'Open')
            priority = item.get('priority', 'Medium')
            assignee_name = item.get('assignee', '').strip()
            url = item.get('url', '')
            raw = item.get('raw', {})
            task_type = item.get('task_type', source.title())

            job_id = item.get('job_id') or f'{source}-{external_id}'

            if status == 'Closed' and not item.get('updated_at'):
                closed_at = timezone.now()
            else:
                closed_at = None

            assign_to = None
            if assignee_name:
                assign_to = Team.objects.filter(name__iexact=assignee_name).first()

            try:
                task, task_created = Task.objects.update_or_create(
                    external_id=external_id,
                    defaults={
                        'job_id': job_id,
                        'email_from': item.get('email_from', ''),
                        'email_subject': title,
                        'task_type': task_type,
                        'task_detail': description,
                        'priority': priority,
                        'status': status,
                        'assign_to': assign_to,
                        'source': source,
                        'closed_at': closed_at,
                    },
                )
                if task_created:
                    created += 1
                else:
                    updated += 1

                TaskSync.objects.update_or_create(
                    source=source,
                    external_id=external_id,
                    defaults={
                        'task': task,
                        'raw': raw,
                    },
                )
            except Exception as e:
                skipped += 1
                errors.append({'external_id': external_id, 'error': str(e)})

        _invalidate_task_caches()
        return JsonResponse({
            'status': 'ok',
            'source': source,
            'created': created,
            'updated': updated,
            'skipped': skipped,
            'errors': errors,
        })
    except json.JSONDecodeError:
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=400)


@require_http_methods(['POST'])
def action_network_webhook(request):
    """Receive webhook from Action Network and sync to task database."""
    try:
        # Verify webhook secret if configured
        cfg = ActionNetworkConfig.get()
        if cfg.webhook_secret:
            signature = request.headers.get('X-Action-Network-Signature', '')
            if not signature:
                return JsonResponse({'status': 'error', 'message': 'Missing signature'}, status=401)
        
        data = json.loads(request.body)
        
        # Action Network payload structure
        # Typically: { "actions": [...], "people": [...], "events": [...] }
        # We'll normalize to our task format
        items = []
        
        if 'actions' in data:
            for action in data['actions']:
                items.append({
                    'external_id': str(action.get('id', '')),
                    'title': action.get('title', 'Untitled Action'),
                    'description': action.get('description', '') or action.get('notes', ''),
                    'status': 'Open',
                    'priority': 'Medium',
                    'source': 'action_network',
                    'raw': action,
                })
        
        if 'events' in data:
            for event in data['events']:
                items.append({
                    'external_id': str(event.get('id', '')),
                    'title': event.get('title', 'Untitled Event'),
                    'description': event.get('description', '') or event.get('notes', ''),
                    'status': event.get('status', 'Open'),
                    'priority': 'Medium',
                    'source': 'action_network',
                    'raw': event,
                })
        
        if not items:
            return JsonResponse({'status': 'ok', 'message': 'No items to sync', 'created': 0, 'updated': 0})

        created = 0
        updated = 0
        skipped = 0
        errors = []

        for item in items:
            external_id = item['external_id']
            title = item['title']
            if not external_id or not title:
                skipped += 1
                continue

            description = item.get('description', '')
            status = item.get('status', 'Open')
            priority = item.get('priority', 'Medium')
            raw = item.get('raw', {})
            task_type = item.get('task_type', 'Action Network')

            job_id = item.get('job_id') or f'AN-{external_id}'

            try:
                task, task_created = Task.objects.update_or_create(
                    external_id=external_id,
                    defaults={
                        'job_id': job_id,
                        'email_from': '',
                        'email_subject': title,
                        'task_type': task_type,
                        'task_detail': description,
                        'priority': priority,
                        'status': status,
                        'source': 'action_network',
                    },
                )
                if task_created:
                    created += 1
                else:
                    updated += 1

                TaskSync.objects.update_or_create(
                    source='action_network',
                    external_id=external_id,
                    defaults={
                        'task': task,
                        'raw': raw,
                    },
                )
            except Exception as e:
                skipped += 1
                errors.append({'external_id': external_id, 'error': str(e)})

        _invalidate_task_caches()
        return JsonResponse({
            'status': 'ok',
            'created': created,
            'updated': updated,
            'skipped': skipped,
            'errors': errors,
        })
    except json.JSONDecodeError:
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=400)


# ---------------------------------------------------------------------------
# Authentication views
# ---------------------------------------------------------------------------

def logout_view(request):
    """Accepts GET and POST — logs out and redirects to /login/."""
    from django.http import HttpResponseRedirect
    logout(request)
    return HttpResponseRedirect('/login/')
