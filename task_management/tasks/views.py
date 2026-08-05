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
from django.db.models import Count, Q, F, Avg
from django.db import IntegrityError
from django.conf import settings
from django.core.cache import cache
import csv
import io
import json
import openpyxl
import requests
import subprocess
import os
import shutil
from pathlib import Path
from redis import Redis
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib3.exceptions import InsecureRequestWarning
import urllib3
urllib3.disable_warnings(InsecureRequestWarning)
from .models import Team, Task, EmailConfig, N8nConfig, ClickUpConfig, WhatsAppConfig, TelegramConfig, DatabaseConfig, TaskSync, RedisConfig, AssignmentRule, ActionNetworkConfig, TaskAttachment, PROVIDER_PRESETS
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
CACHE_TARGET_ANALYTICS = 'target_analytics'

TTL_DASHBOARD = 120
TTL_REPORTS   = 300
TTL_TEAMS     = 600
TTL_ANALYTICS = 300

STATUS_CHOICES = [
    'Open', 'Assigned', 'In Progress', 'Pending User',
    'Pending Vendor', 'Completed', 'Closed', 'Rejected', 'Cancelled',
]
PRIORITY_CHOICES = ['High', 'Medium', 'Low']
SLA_HOURS = 48


def _invalidate_task_caches():
    cache.delete_many([
        CACHE_DASHBOARD, CACHE_BY_STATUS, CACHE_BY_PRIORITY,
        CACHE_BY_TEAM, CACHE_REPORTS, CACHE_TASK_TYPES, CACHE_TARGET_ANALYTICS,
    ])


def _invalidate_team_caches():
    cache.delete_many([
        CACHE_TEAMS_ALL, CACHE_BY_TEAM, CACHE_DASHBOARD, CACHE_REPORTS,
    ])


def _get_dashboard_metrics():
    cached = cache.get(CACHE_DASHBOARD)
    if cached is not None:
        return cached
    now = timezone.now()
    data = {
        'total':         Task.objects.count(),
        'open':          Task.objects.filter(status='Open').count(),
        'assigned':      Task.objects.filter(status='Assigned').count(),
        'in_progress':   Task.objects.filter(status='In Progress').count(),
        'closed':        Task.objects.filter(status='Closed').count(),
        'high_priority': Task.objects.filter(priority='High').count(),
        'overdue':       Task.objects.filter(
                             status__in=['Open', 'Assigned', 'In Progress'],
                             created_at__lt=now - timedelta(days=7),
                         ).count(),
    }
    cache.set(CACHE_DASHBOARD, data, TTL_DASHBOARD)
    return data


def _get_target_analytics():
    cached = cache.get(CACHE_TARGET_ANALYTICS)
    if cached is not None:
        return cached

    rows = []
    for task in Task.objects.select_related('assign_to').all():
        rows.append(task)

    summary = {}
    for task in rows:
        target = task.target_name
        if target not in summary:
            summary[target] = {'total': 0, 'open': 0, 'in_progress': 0, 'closed': 0, 'high': 0}
        summary[target]['total'] += 1
        if task.status == 'Open':
            summary[target]['open'] += 1
        elif task.status == 'In Progress':
            summary[target]['in_progress'] += 1
        if task.status == 'Closed':
            summary[target]['closed'] += 1
        if task.priority == 'High':
            summary[target]['high'] += 1

    result = sorted(
        [{'target': t, **v} for t, v in summary.items()],
        key=lambda x: x['total'],
        reverse=True,
    )
    cache.set(CACHE_TARGET_ANALYTICS, result, TTL_ANALYTICS)
    return result


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
    filterset_fields = ['status', 'priority', 'task_type', 'assign_to', 'dbname', 'userid']
    search_fields = ['job_id', 'email_from', 'email_subject', 'task_detail', 'dbname', 'userid']
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
            dbname = item.get('dbname', '').strip()
            userid = item.get('userid', '').strip()

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
                        'dbname':    dbname,
                        'userid':    userid,
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
    qs = Task.objects.select_related('assign_to').all()
    paginator = Paginator(qs, 5)
    page_obj = paginator.get_page(request.GET.get('page', 1))
    target_analytics = _get_target_analytics()
    return render(request, 'tasks/dashboard.html', {
        'metrics': metrics,
        'page_obj': page_obj,
        'target_analytics': target_analytics,
    })


@login_required
def partial_by_target(request):
    data = _get_target_analytics()
    paginator = Paginator(data, 5)
    page_obj = paginator.get_page(request.GET.get('page', 1))
    return render(request, 'tasks/partials/by_target.html', {'page_obj': page_obj})


# ---------------------------------------------------------------------------
# Template views — Task list with filtering + pagination
# Supports multiple views: table (default), list, board, card
# ---------------------------------------------------------------------------

VIEW_MODE_TABLE = 'table'
VIEW_MODE_LIST = 'list'
VIEW_MODE_BOARD = 'board'
VIEW_MODE_CARD = 'card'


def _get_task_types():
    tt = cache.get(CACHE_TASK_TYPES)
    if tt is None:
        tt = list(AssignmentRule.objects.values_list('keyword', flat=True).order_by('keyword'))
        cache.set(CACHE_TASK_TYPES, tt, TTL_REPORTS)
    return tt


def _get_filtered_tasks(request):
    qs = Task.objects.select_related('assign_to').all()

    search    = request.GET.get('search', '').strip()
    status    = request.GET.get('status', '').strip()
    priority  = request.GET.get('priority', '').strip()
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

    return qs, search, status, priority, task_type


@login_required
def task_list_page(request):
    qs, search, status, priority, task_type = _get_filtered_tasks(request)
    view_mode = request.GET.get('view', VIEW_MODE_TABLE)
    if view_mode == VIEW_MODE_TABLE and request.path.rstrip('/').endswith('/tasks/board'):
        view_mode = VIEW_MODE_BOARD

    if view_mode == VIEW_MODE_BOARD:
        return _render_board(request, qs, search, status, priority, task_type)
    if view_mode == VIEW_MODE_CARD:
        return _render_card(request, qs, search, status, priority, task_type)
    if view_mode == VIEW_MODE_LIST:
        return _render_list(request, qs, search, status, priority, task_type)

    paginator = Paginator(qs, 20)
    page_obj  = paginator.get_page(request.GET.get('page', 1))

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
        'view_mode': VIEW_MODE_TABLE,
    })


@login_required
def _render_table(request, qs, search, status, priority, task_type):
    paginator = Paginator(qs, 20)
    page_obj  = paginator.get_page(request.GET.get('page', 1))

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
        'view_mode': VIEW_MODE_TABLE,
    })


@login_required
def _render_list(request, qs, search, status, priority, task_type):
    paginator = Paginator(qs, 20)
    page_obj  = paginator.get_page(request.GET.get('page', 1))

    if request.headers.get('HX-Request') and request.headers.get('HX-Target') == 'task-list-body':
        return render(request, 'tasks/partials/task_list_rows.html', {'page_obj': page_obj})

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
        'view_mode': VIEW_MODE_LIST,
    })


@login_required
def _render_board(request, qs, search, status, priority, task_type):
    # prefetch_related eliminates N+1 from task.attachments.exists in the template.
    # Cap at 200 per board render — beyond that the kanban is unusable anyway.
    tasks = list(qs.select_related('assign_to').prefetch_related('attachments').order_by('-created_at')[:200])
    status_groups = []
    for s in STATUS_CHOICES:
        status_groups.append((s, [t for t in tasks if t.status == s]))
    overflow = [t for t in tasks if t.status not in STATUS_CHOICES]
    if overflow:
        status_groups.append(('Other', overflow))

    if request.headers.get('HX-Request'):
        return render(request, 'tasks/partials/task_board.html', {
            'status_groups': status_groups,
            'filters': {
                'search': search, 'status': status,
                'priority': priority, 'task_type': task_type,
            },
        })

    teams = Team.objects.filter(is_active=True)
    return render(request, 'tasks/task_list.html', {
        'status_groups':   status_groups,
        'task_types':      _get_task_types(),
        'status_choices':  STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
        'teams':           teams,
        'filters': {
            'search': search, 'status': status,
            'priority': priority, 'task_type': task_type,
        },
        'view_mode': VIEW_MODE_BOARD,
    })


@login_required
def _render_card(request, qs, search, status, priority, task_type):
    paginator = Paginator(qs, 24)
    page_obj  = paginator.get_page(request.GET.get('page', 1))

    if request.headers.get('HX-Request') and request.headers.get('HX-Target') == 'task-cards-body':
        return render(request, 'tasks/partials/task_cards.html', {'page_obj': page_obj})

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
        'view_mode': VIEW_MODE_CARD,
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
            try:
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
                    dbname        = request.POST.get('dbname', '').strip(),
                    userid        = request.POST.get('userid', '').strip(),
                )
            except IntegrityError:
                job_id = Task.get_next_job_id()
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
                    dbname        = request.POST.get('dbname', '').strip(),
                    userid        = request.POST.get('userid', '').strip(),
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
        'task_types':       _get_task_types(),
        'status_choices':   STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
        'errors':           errors,
        'form_data':        form_data,
        'next_job_id':      next_job_id,
    })


@login_required
@require_http_methods(['POST'])
def task_create_modal(request):
    """HTMX endpoint for creating a task from the quick-create modal."""
    errors = {}
    required = ['email_from', 'email_subject', 'task_type', 'task_detail', 'priority']
    for f in required:
        if not request.POST.get(f, '').strip():
            errors[f] = 'This field is required.'

    if errors:
        html = (
            '<div class="alert alert-danger py-2 d-flex align-items-center gap-2">'
            '<i class="fa fa-circle-xmark"></i>Please fill all required fields.</div>'
        )
        return HttpResponse(html)

    assign_to_id = request.POST.get('assign_to') or None
    job_id = Task.get_next_job_id()
    try:
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
            dbname        = request.POST.get('dbname', '').strip(),
            userid        = request.POST.get('userid', '').strip(),
        )
    except IntegrityError:
        job_id = Task.get_next_job_id()
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
            dbname        = request.POST.get('dbname', '').strip(),
            userid        = request.POST.get('userid', '').strip(),
        )
    _invalidate_task_caches()

    html = (
        '<div class="alert alert-success py-2 d-flex align-items-center gap-2">'
        f'<i class="fa fa-circle-check"></i>'
        f'Job ID <strong>{job_id}</strong> tersimpan.'
        '</div>'
    )
    response = HttpResponse(html)
    response['HX-Trigger'] = 'taskCreated'
    return response


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
            task.dbname        = request.POST.get('dbname', '').strip()
            task.userid        = request.POST.get('userid', '').strip()
            task.assign_to_id  = assign_to_id
            if task.status == 'Closed' and not task.closed_at:
                task.closed_at = timezone.now()
            task.save()
            _invalidate_task_caches()

            uploaded_files = request.FILES.getlist('attachments')
            for uploaded in uploaded_files:
                TaskAttachment.objects.create(
                    task=task,
                    file=uploaded,
                    filename=uploaded.name,
                    content_type=getattr(uploaded, 'content_type', ''),
                    uploaded_by=request.user,
                )

            return redirect('task-detail', pk=task.pk)

    return render(request, 'tasks/task_edit.html', {
        'task':             task,
        'teams':            teams,
        'task_types':       _get_task_types(),
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
def task_board_move(request, pk):
    task = get_object_or_404(Task, pk=pk)
    new_status = request.POST.get('status', '').strip()
    if new_status in STATUS_CHOICES:
        task.status = new_status
        if new_status == 'Closed' and not task.closed_at:
            task.closed_at = timezone.now()
        task.save(update_fields=['status', 'closed_at'])
        _invalidate_task_caches()
    return HttpResponse(status=204)


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


@require_http_methods(['POST'])
@login_required
def task_attachment_delete(request, pk, attachment_id):
    task = get_object_or_404(Task, pk=pk)
    attachment = get_object_or_404(TaskAttachment, pk=attachment_id, task=task)
    attachment.file.delete()
    attachment.delete()
    _invalidate_task_caches()
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


@login_required
def task_view_modal(request, pk):
    """Return the task detail view HTML for the modal."""
    task = get_object_or_404(Task.objects.select_related('assign_to'), pk=pk)
    teams = Team.objects.filter(is_active=True)
    return render(request, 'tasks/partials/task_view_modal.html', {
        'task': task, 'teams': teams,
        'status_choices': STATUS_CHOICES,
    })


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

def _calc_avg_resolution():
    closed_qs = Task.objects.filter(status='Closed', closed_at__isnull=False, created_at__isnull=False)
    if not closed_qs.exists():
        return '—'
    avg_duration = closed_qs.aggregate(
        avg_dur=Avg(F('closed_at') - F('created_at'))
    )['avg_dur']
    if avg_duration is None:
        return '—'
    total_seconds = avg_duration.total_seconds()
    days = int(total_seconds // 86400)
    hours = int((total_seconds % 86400) // 3600)
    minutes = int((total_seconds % 3600) // 60)
    seconds = int(total_seconds % 60)
    if days > 0:
        return f'{days}d {hours}h'
    elif hours > 0:
        return f'{hours}h {minutes}m'
    elif minutes > 0:
        return f'{minutes}m'
    return f'{seconds}s'


def _calc_sla_compliance(month_start):
    closed_qs = Task.objects.filter(
        status='Closed', closed_at__isnull=False,
        created_at__isnull=False, closed_at__gte=month_start,
    )
    total = closed_qs.count()
    if total == 0:
        return 0
    sla_met = closed_qs.filter(
        closed_at__lte=F('created_at') + timedelta(hours=SLA_HOURS)
    ).count()
    return round(sla_met / total * 100)


@login_required
def reports_page(request):
    cached = cache.get(CACHE_REPORTS)
    if cached:
        return render(request, 'tasks/reports.html', {'report': cached})

    now         = timezone.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start  = today_start - timedelta(days=today_start.weekday())
    month_start = today_start.replace(day=1)

    # 7-day trend (weekly)
    weekly_trend = []
    for i in range(6, -1, -1):
        day_start = today_start - timedelta(days=i)
        day_end   = day_start + timedelta(days=1)
        weekly_trend.append({
            'label':  day_start.strftime('%a %d'),
            'created': Task.objects.filter(created_at__gte=day_start, created_at__lt=day_end).count(),
             'closed':  Task.objects.filter(closed_at__gte=day_start, closed_at__lt=day_end).count(),
         })

    # 30-day trend (monthly)
    monthly_trend = []
    for i in range(29, -1, -1):
        day_start = today_start - timedelta(days=i)
        day_end   = day_start + timedelta(days=1)
        monthly_trend.append({
            'label':  day_start.strftime('%d %b'),
            'created': Task.objects.filter(created_at__gte=day_start, created_at__lt=day_end).count(),
            'closed':  Task.objects.filter(closed_at__gte=day_start, closed_at__lt=day_end).count(),
        })

    # 12-month trend (yearly)
    yearly_trend = []
    for i in range(11, -1, -1):
        y = now.year
        m = now.month - i
        while m <= 0:
            m += 12
            y -= 1
        m_start = now.replace(year=y, month=m, day=1, hour=0, minute=0, second=0, microsecond=0)
        m_next  = now.replace(year=y, month=m+1, day=1, hour=0, minute=0, second=0, microsecond=0) if m < 12 else now.replace(year=y+1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        yearly_trend.append({
            'label':   m_start.strftime('%b %Y'),
            'created': Task.objects.filter(created_at__gte=m_start, created_at__lt=m_next).count(),
            'closed':  Task.objects.filter(closed_at__gte=m_start, closed_at__lt=m_next).count(),
        })

     # 7-day trend (legacy, used by the table)
    trend = []
    for i in range(6, -1, -1):
        day_start = today_start - timedelta(days=i)
        day_end   = day_start + timedelta(days=1)
        created_count = Task.objects.filter(created_at__gte=day_start, created_at__lt=day_end).count()
        closed_count = Task.objects.filter(closed_at__gte=day_start, closed_at__lt=day_end).count()
        trend.append({
            'date':    day_start,
            'created': created_count,
            'closed':  closed_count,
            'open':    Task.objects.filter(
                          created_at__lt=day_end,
                      ).filter(
                          Q(closed_at__isnull=True) | Q(closed_at__gt=day_end)
                      ).count(),
            'net':     created_count - closed_count,
        })

    report = {
        'open':             Task.objects.filter(status='Open').count(),
        'in_progress':      Task.objects.filter(status='In Progress').count(),
        'closed_today':     Task.objects.filter(closed_at__gte=today_start).count(),
        'overdue':          Task.objects.filter(
                                status__in=['Open', 'Assigned', 'In Progress'],
                                created_at__lt=today_start - timedelta(days=7),
                            ).count(),
        'weekly_created':   Task.objects.filter(created_at__gte=week_start).count(),
        'weekly_closed':    Task.objects.filter(closed_at__gte=week_start).count(),
        'avg_resolution':   _calc_avg_resolution(),
        'monthly_created':  Task.objects.filter(created_at__gte=month_start).count(),
        'monthly_closed':    Task.objects.filter(closed_at__gte=month_start).count(),
        'sla_compliance':   _calc_sla_compliance(month_start),
        'trend':            trend,
        'weekly_trend':     json.dumps(weekly_trend),
        'monthly_trend':    json.dumps(monthly_trend),
        'yearly_trend':     json.dumps(yearly_trend),
    }
    cache.set(CACHE_REPORTS, report, TTL_REPORTS)
    return render(request, 'tasks/reports.html', {'report': report})


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
    if not cfg.host or not cfg.username:
        return {'ok': False, 'message': 'Email is not configured. Save SMTP credentials first.'}
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


CONNECTION_CHECK_CACHE_KEY = 'admin_page_conn_status'
CONNECTION_CHECK_CACHE_TTL = 300


def _run_test(fn, *args, **kwargs):
    try:
        return fn(*args, **kwargs)
    except Exception as e:
        return {'ok': False, 'message': f'Error: {e}'}


def _auto_check_connections():
    email_cfg = EmailConfig.get()
    n8n_cfg = N8nConfig.get()
    clickup_cfg = ClickUpConfig.get()
    whatsapp_cfg = WhatsAppConfig.get()
    telegram_cfg = TelegramConfig.get()
    database_cfg = DatabaseConfig.get()
    redis_cfg = RedisConfig.get()
    action_network_cfg = ActionNetworkConfig.get()

    results = {}
    with ThreadPoolExecutor(max_workers=6) as executor:
        futures = {
            executor.submit(_run_test, _test_email_config, email_cfg): 'email',
            executor.submit(_run_test, _test_n8n_config, n8n_cfg): 'n8n',
            executor.submit(_run_test, _test_clickup_config, clickup_cfg): 'clickup',
            executor.submit(_run_test, _test_whatsapp_config, whatsapp_cfg): 'whatsapp',
            executor.submit(_run_test, _test_telegram_config, telegram_cfg): 'telegram',
            executor.submit(_run_test, _test_database_config, database_cfg): 'database',
            executor.submit(_run_test, _test_redis_config, redis_cfg): 'redis',
            executor.submit(_run_test, _test_action_network_config, action_network_cfg): 'action_network',
        }
        for future in as_completed(futures):
            key = futures[future]
            results[key] = future.result()

    for key in ('email', 'n8n', 'clickup', 'whatsapp', 'telegram', 'database', 'redis', 'action_network'):
        results.setdefault(key, {'ok': False, 'message': 'Check failed'})

    return results


# ---------------------------------------------------------------------------
# n8n configuration views
# ---------------------------------------------------------------------------

@login_required
def admin_page(request):
    if request.method == 'POST' and request.POST.get('flush_cache'):
        cache.clear()

    conn_status = cache.get(CONNECTION_CHECK_CACHE_KEY)
    if conn_status is None:
        try:
            conn_status = _auto_check_connections()
            cache.set(CONNECTION_CHECK_CACHE_KEY, conn_status, CONNECTION_CHECK_CACHE_TTL)
        except Exception:
            conn_status = {}

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
        'conn_status':      conn_status,
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
    if not base_url:
        return {'ok': False, 'message': 'n8n is not configured. Save a base URL first.'}
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
    if not cfg.api_token:
        return {'ok': False, 'message': 'ClickUp is not configured. Save an API token first.'}
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
    if not url:
        return {'ok': False, 'message': 'Redis is not configured. Save a Redis URL first.'}
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


def _find_redis_server():
    candidates = [
        r'C:\redis\redis-server.exe',
        r'C:\Program Files\Redis\redis-server.exe',
        r'C:\Program Files\Redis-x64-5.0.14.1\redis-server.exe',
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    try:
        result = subprocess.run(
            ['where', 'redis-server'],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip().split('\n')[0]
    except Exception:
        pass
    return None


@login_required
@require_http_methods(['POST'])
def redis_config_start(request):
    """Start the local Redis server."""
    exe = _find_redis_server()
    if not exe:
        msg = {'ok': False, 'message': 'redis-server.exe not found. Install Redis or extract it to C:\\redis\\.'}
    else:
        try:
            subprocess.Popen(
                [exe, '--port', '6379', '--dir', os.path.dirname(exe)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NEW_CONSOLE,
            )
            import time
            time.sleep(1)
            cfg = RedisConfig.get()
            client = Redis.from_url(cfg.url, socket_connect_timeout=5, socket_timeout=5)
            client.ping()
            msg = {'ok': True, 'message': 'Redis server started successfully!'}
        except Exception as e:
            msg = {'ok': False, 'message': f'Failed to start Redis: {e}'}

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
    if not cfg.name:
        return {
            'ok': False,
            'message': 'Database is not configured. Save a database name first.',
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


def _test_action_network_config(cfg):
    """Test the Action Network API key by fetching the authenticated user's tags."""
    if not cfg.api_key:
        return {'ok': False, 'message': 'Action Network is not configured. Save an API key first.'}
    try:
        resp = requests.get(
            'https://actionnetwork.org/api/v2/',
            headers={'OSDI-API-Token': cfg.api_key},
            timeout=10,
        )
        if resp.status_code == 200:
            return {'ok': True, 'message': 'Action Network API key is valid.'}
        if resp.status_code in (401, 403):
            return {'ok': False, 'message': 'Unauthorized. The API key is invalid or has been revoked.'}
        return {'ok': False, 'message': f'Action Network responded with status {resp.status_code}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


def _test_whatsapp_config(cfg):
    if not cfg.api_token:
        return {'ok': False, 'message': 'WhatsApp is not configured. Save an API token first.'}
    try:
        headers = {
            'Authorization': f'Bearer {cfg.api_token}',
            'Content-Type': 'application/json',
        }
        target = cfg.phone_number_id or cfg.business_account_id
        if not target:
            return {'ok': False, 'message': 'WhatsApp is not configured. Save a Phone Number ID or Business Account ID first.'}
        resp = requests.get(
            f'https://graph.facebook.com/v18.0/{target}',
            headers=headers,
            timeout=10,
            params={'fields': 'id,name'},
        )
        if resp.status_code == 200:
            data = resp.json()
            name = data.get('name') or data.get('display_name') or target
            return {'ok': True, 'message': f'WhatsApp connected ({name}).'}
        if resp.status_code in (401, 403):
            return {'ok': False, 'message': 'Unauthorized. The API token is invalid or expired.'}
        return {'ok': False, 'message': f'WhatsApp responded with status {resp.status_code}.'}
    except Exception as e:
        return {'ok': False, 'message': f'Connection failed: {e}'}


def _test_telegram_config(cfg):
    if not cfg.bot_token:
        return {'ok': False, 'message': 'Telegram is not configured. Save a bot token first.'}
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

        if isinstance(data, list):
            items = data
            source = 'n8n'
        elif isinstance(data, dict):
            source = data.get('source', 'n8n')
            items = data.get('items', [])
            if not isinstance(items, list):
                items = [items]
        else:
            return JsonResponse({'status': 'error', 'message': 'Invalid payload format'}, status=400)

        if not items:
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
            email_from = item.get('email_from', '')
            dbname = item.get('dbname', '').strip()
            userid = item.get('userid', '').strip()

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
                        'email_from': email_from,
                        'email_subject': title,
                        'task_type': task_type,
                        'task_detail': description,
                        'priority': priority,
                        'status': status,
                        'assign_to': assign_to,
                        'source': source,
                        'closed_at': closed_at,
                        'dbname': dbname,
                        'userid': userid,
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
                        'dbname': item.get('dbname', ''),
                        'userid': item.get('userid', ''),
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
# Backup page
# ---------------------------------------------------------------------------

BACKUP_ROOT = Path('C:/www/n8n/backup')


@login_required
def backup_page(request):
    BACKUP_ROOT.mkdir(parents=True, exist_ok=True)

    message = ''
    message_type = 'info'
    backups = []

    if request.method == 'POST':
        action = request.POST.get('action', '')

        if action == 'backup_postgres':
            db_name = request.POST.get('db_name', 'taskdb')
            db_host = request.POST.get('db_host', 'localhost')
            db_port = request.POST.get('db_port', '5008')
            db_user = request.POST.get('db_user', 'postgres')
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_file = BACKUP_ROOT / f'postgres_{db_name}_{timestamp}.sql'

            pg_dump_path = shutil.which('pg_dump')
            if not pg_dump_path:
                pg_dump_path = r'C:\Program Files\PostgreSQL\18\bin\pg_dump.exe'

            try:
                env = os.environ.copy()
                env['PGPASSWORD'] = settings.DATABASES['default']['PASSWORD']
                result = subprocess.run(
                    [pg_dump_path, '-h', db_host, '-p', db_port, '-U', db_user, '-d', db_name, '-f', str(backup_file)],
                    capture_output=True, text=True, env=env, timeout=300
                )
                if result.returncode == 0:
                    message = f'PostgreSQL backup successful: {backup_file.name}'
                    message_type = 'success'
                else:
                    message = f'pg_dump failed: {result.stderr}'
                    message_type = 'danger'
            except Exception as e:
                message = f'Backup failed: {e}'
                message_type = 'danger'

        elif action == 'backup_redis':
            redis_url = request.POST.get('redis_url', 'redis://localhost:6379/0')

            try:
                r = Redis.from_url(redis_url, socket_connect_timeout=5, socket_timeout=5)
                r.ping()

                try:
                    r.bgsave()
                    message = (
                        'Redis BGSAVE triggered. The RDB file is created on the Redis server itself. '
                        'For Redis Cloud, download the RDB from your Redis Cloud provider dashboard. '
                        'For local Redis, the file is in the Redis data directory (dump.rdb).'
                    )
                    message_type = 'warning'
                except Exception as e:
                    message = (
                        f'Redis backup notice: {e}. '
                        'For Redis Cloud, download the RDB from your provider dashboard.'
                    )
                    message_type = 'warning'
            except Exception as e:
                message = f'Redis backup failed: {e}'
                message_type = 'danger'

        elif action == 'download':
            filename = request.POST.get('filename', '')
            filepath = BACKUP_ROOT / filename
            if filepath.exists() and filepath.is_file():
                with open(filepath, 'rb') as f:
                    response = HttpResponse(f.read(), content_type='application/octet-stream')
                    response['Content-Disposition'] = f'attachment; filename="{filename}"'
                    return response
            message = 'File not found.'
            message_type = 'danger'

    for f in sorted(BACKUP_ROOT.iterdir(), key=lambda x: x.stat().st_mtime, reverse=True):
        if f.is_file():
            backups.append({
                'name': f.name,
                'size': f.stat().st_size,
                'modified': datetime.fromtimestamp(f.stat().st_mtime),
            })

    return render(request, 'tasks/backup.html', {
        'message': message,
        'message_type': message_type,
        'backups': backups,
    })


# ---------------------------------------------------------------------------
# CSV / Excel Import with validation and editable preview
# ---------------------------------------------------------------------------

IMPORT_FIELD_MAP = {
    'email_from':    ['email from', 'from', 'email_from', 'from email', 'email', 'email address', 'sender', 'requester', 'nama', 'name', 'pegawai', 'staff', 'pic', 'contact'],
    'email_subject': ['subject', 'email subject', 'email_subject', 'title', 'judul', 'summary', 'ringkasan', 'kepada', 'to'],
    'task_type':     ['type', 'task type', 'task_type', 'category', 'kategori', 'tipe', 'jenis', 'group', 'kategori'],
    'task_detail':   ['detail', 'task detail', 'task_detail', 'description', 'deskripsi', 'desc', 'keterangan', 'details', 'work order', 'wo', 'aktivitas', 'activity', 'request', 'permintaan'],
    'priority':      ['priority', 'prio', 'prioritas', 'level', 'tingkat'],
    'status':        ['status', 'state', 'status task', 'keadaan'],
    'assign_to':     ['assign', 'assigned to', 'assign_to', 'team', 'assignee', 'tim', 'handler', 'pic', 'owner', 'pemilik', 'dba team', 'group'],
    'note':          ['note', 'notes', 'catatan', 'remark', 'remarks', 'komentar', 'comment', 'handler', 'pic', 'assigned by', 'ditugaskan'],
    'job_id':        ['job id', 'job_id', 'id', 'job', 'kode', 'ticket', 'no', 'no.', 'number', 'nomor', 'crq', 'change'],
    'create_at':     ['create at', 'create_at', 'created at', 'created_at', 'date', 'tanggal', 'tgl', 'created'],
    'dbname':        ['dbname', 'database', 'db', 'database name', 'nama database'],
    'userid':        ['userid', 'user id', 'user', 'user id', 'username', 'user name'],
}

IMPORT_REQUIRED_FIELDS = ['email_from', 'email_subject', 'task_type', 'task_detail', 'priority']

IMPORT_DEFAULTS = {
    'priority': 'Medium',
    'status': 'Open',
}


def _normalize_header(header):
    return header.strip().lower()


def _map_headers(raw_headers):
    mapped = {}
    for raw in raw_headers:
        norm = _normalize_header(raw)
        for field, aliases in IMPORT_FIELD_MAP.items():
            if norm in aliases:
                mapped[field] = raw
                break
    return mapped


def _parse_import_file(uploaded_file):
    filename = uploaded_file.name.lower()
    if filename.endswith('.csv'):
        text = uploaded_file.read().decode('utf-8-sig')
        reader = csv.DictReader(io.StringIO(text))
        raw_headers = reader.fieldnames or []
        rows = list(reader)
    elif filename.endswith(('.xlsx', '.xls')):
        wb = openpyxl.load_workbook(uploaded_file, read_only=True, data_only=True)
        ws = wb.active
        raw_headers = []
        rows = []
        for i, row in enumerate(ws.iter_rows(values_only=True)):
            if i == 0:
                raw_headers = [str(c) if c is not None else '' for c in row]
            else:
                rows.append({str(h) if h is not None else f'col_{j}': str(c) if c is not None else '' for j, (h, c) in enumerate(zip(raw_headers, row))})
        wb.close()
    else:
        raise ValueError('Unsupported file format. Please upload CSV or Excel (.xlsx/.xls).')
    return raw_headers, rows


def _validate_row(row, index, existing_job_ids, teams_list):
    errors = {}
    mapped = _map_headers(list(row.keys()))
    team_names = {t.name.lower(): t.name for t in teams_list}

    for field in IMPORT_REQUIRED_FIELDS:
        raw_key = mapped.get(field)
        value = row.get(raw_key, '').strip() if raw_key else ''
        if not value:
            errors[field] = 'This field is required.'

    if 'priority' not in errors or 'priority' in errors:
        priority = row.get(mapped.get('priority', ''), 'Medium').strip()
        if priority and priority not in PRIORITY_CHOICES:
            errors['priority'] = f'Must be one of: {", ".join(PRIORITY_CHOICES)}.'

    status = row.get(mapped.get('status', ''), 'Open').strip()
    if status and status not in STATUS_CHOICES:
        errors['status'] = f'Must be one of: {", ".join(STATUS_CHOICES)}.'

    assign_raw = row.get(mapped.get('assign_to', ''), '').strip()
    if assign_raw:
        if assign_raw.lower() not in team_names:
            errors['assign_to'] = f'Team "{assign_raw}" not found.'

    job_id = row.get(mapped.get('job_id', ''), '').strip()
    if job_id and job_id != 'auto':
        if job_id in existing_job_ids:
            errors['job_id'] = 'Duplicate job ID.'
        else:
            existing_job_ids.add(job_id)

    return errors, mapped


def _row_to_dict(row, mapped):
    return {
        'email_from':    row.get(mapped.get('email_from', ''), '').strip(),
        'email_subject': row.get(mapped.get('email_subject', ''), '').strip(),
        'task_type':     row.get(mapped.get('task_type', ''), '').strip(),
        'task_detail':   row.get(mapped.get('task_detail', ''), '').strip(),
        'priority':      row.get(mapped.get('priority', ''), 'Medium').strip() or 'Medium',
        'status':        row.get(mapped.get('status', ''), 'Open').strip() or 'Open',
        'assign_to':     row.get(mapped.get('assign_to', ''), '').strip(),
        'note':          row.get(mapped.get('note', ''), '').strip(),
        'job_id':        row.get(mapped.get('job_id', ''), '').strip(),
        'create_at':     row.get(mapped.get('create_at', ''), '').strip(),
        'dbname':        row.get(mapped.get('dbname', ''), '').strip(),
        'userid':        row.get(mapped.get('userid', ''), '').strip(),
    }


@login_required
def task_import_page(request):
    preview_rows = None
    preview_data_json = ''
    error_message = ''
    info_message = ''
    import_type = ''

    if request.method == 'POST':
        if request.POST.get('action') == 'confirm':
            return task_import_confirm(request)

        uploaded = request.FILES.get('import_file')
        if not uploaded:
            error_message = 'Please select a file to upload.'
        else:
            try:
                raw_headers, rows = _parse_import_file(uploaded)
                if not rows:
                    error_message = 'The file is empty or has no data rows.'
                else:
                    mapped = _map_headers(raw_headers)
                    required_missing = [f for f in IMPORT_REQUIRED_FIELDS if f not in mapped]
                    if required_missing:
                        error_message = (
                            f'Missing required column(s): {", ".join(required_missing)}. '
                            f'Please ensure your file has headers that match: '
                            f'{", ".join(IMPORT_REQUIRED_FIELDS)}.'
                        )
                    else:
                        teams_list = list(Team.objects.all())
                        existing_job_ids = set(Task.objects.values_list('job_id', flat=True))
                        preview_rows = []
                        has_errors = False
                        for idx, row in enumerate(rows):
                            errors, row_mapped = _validate_row(row, idx, existing_job_ids, teams_list)
                            if errors:
                                has_errors = True
                            preview_rows.append({
                                'index': idx,
                                'data': _row_to_dict(row, row_mapped),
                                'errors': errors,
                                'has_errors': bool(errors),
                            })
                        info_message = (
                            f'Parsed {len(rows)} row(s). '
                            f'{sum(1 for r in preview_rows if r["has_errors"])} row(s) have validation issues.'
                        )
                        preview_data_json = json.dumps([r['data'] for r in preview_rows])
                        import_type = 'preview'
            except ValueError as e:
                error_message = str(e)
            except Exception as e:
                error_message = f'Failed to parse file: {e}'

    if import_type != 'preview':
        preview_rows = None

    return render(request, 'tasks/task_import.html', {
        'preview_rows': preview_rows,
        'preview_data_json': preview_data_json,
        'error_message': error_message,
        'info_message': info_message,
        'import_type': import_type,
        'teams': Team.objects.filter(is_active=True),
        'status_choices': STATUS_CHOICES,
        'priority_choices': PRIORITY_CHOICES,
        'task_types': _get_task_types(),
    })


@login_required
def task_import_confirm(request):
    if request.method != 'POST':
        return redirect('task-import')

    preview_data_json = request.POST.get('preview_data', '[]')
    try:
        original_data = json.loads(preview_data_json)
    except json.JSONDecodeError:
        original_data = []

    if not original_data:
        return render(request, 'tasks/task_import.html', {
            'error_message': 'No data to import.',
            'import_type': '',
            'teams': Team.objects.filter(is_active=True),
            'status_choices': STATUS_CHOICES,
            'priority_choices': PRIORITY_CHOICES,
        })

    teams_list = list(Team.objects.all())
    existing_job_ids = set(Task.objects.values_list('job_id', flat=True))
    team_map = {t.name.lower(): t for t in teams_list}

    created = 0
    updated = 0
    skipped = 0
    errors = []

    for idx, original in enumerate(original_data):
        edited = {
            'email_from':    original.get('email_from', '').strip(),
            'email_subject': original.get('email_subject', '').strip(),
            'task_type':     original.get('task_type', '').strip(),
            'task_detail':   original.get('task_detail', '').strip(),
            'priority':      original.get('priority', 'Medium').strip() or 'Medium',
            'status':        original.get('status', 'Open').strip() or 'Open',
            'assign_to':     original.get('assign_to', '').strip(),
            'note':          original.get('note', '').strip(),
            'job_id':        original.get('job_id', '').strip(),
            'create_at':     original.get('create_at', '').strip(),
            'dbname':        original.get('dbname', '').strip(),
            'userid':        original.get('userid', '').strip(),
        }

        row_errors = []
        for field in IMPORT_REQUIRED_FIELDS:
            if not edited.get(field):
                row_errors.append(f'{field} is required.')

        if edited.get('priority') not in PRIORITY_CHOICES:
            row_errors.append(f'Priority must be one of: {", ".join(PRIORITY_CHOICES)}.')

        if edited.get('status') not in STATUS_CHOICES:
            row_errors.append(f'Status must be one of: {", ".join(STATUS_CHOICES)}.')

        assign_name = edited.get('assign_to', '').strip()
        if assign_name:
            if assign_name.lower() not in team_map:
                row_errors.append(f'Team "{assign_name}" not found.')
            else:
                edited['assign_to'] = team_map[assign_name.lower()]
        else:
            edited['assign_to'] = None

        job_id = edited.get('job_id', '').strip()
        if job_id and job_id != 'auto':
            if job_id in existing_job_ids:
                row_errors.append('Duplicate job ID.')
            else:
                existing_job_ids.add(job_id)
        else:
            edited['job_id'] = Task.get_next_job_id()

        if row_errors:
            skipped += 1
            errors.append({'row': idx + 1, 'errors': row_errors})
            continue

        try:
            task, task_created = Task.objects.update_or_create(
                job_id=edited['job_id'],
                defaults={
                    'email_from':    edited['email_from'],
                    'email_subject': edited['email_subject'],
                    'task_type':     edited['task_type'],
                    'task_detail':   edited['task_detail'],
                    'priority':      edited['priority'],
                    'status':        edited['status'],
                    'assign_to':     edited['assign_to'],
                    'note':          edited['note'],
                    'source':        'import',
                    'dbname':        edited.get('dbname', ''),
                    'userid':        edited.get('userid', ''),
                },
            )
            if task_created:
                created += 1
            else:
                updated += 1
            if edited.get('create_at'):
                try:
                    create_at = datetime.strptime(edited['create_at'], '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    try:
                        create_at = datetime.strptime(edited['create_at'], '%Y-%m-%d')
                    except ValueError:
                        create_at = None
                if create_at:
                    Task.objects.filter(job_id=edited['job_id']).update(created_at=create_at)
        except Exception as e:
            skipped += 1
            errors.append({'row': idx + 1, 'errors': [str(e)]})

    _invalidate_task_caches()
    result = {
        'created': created,
        'updated': updated,
        'skipped': skipped,
        'errors': errors,
        'total': len(original_data),
    }

    if request.headers.get('HX-Request'):
        status_class = 'alert-success' if skipped == 0 else 'alert-warning'
        icon = 'fa-circle-check' if skipped == 0 else 'fa-triangle-exclamation'
        html = (
            f'<div class="alert {status_class} py-2 mb-0">'
            f'<i class="fa {icon} me-1"></i>'
            f'Imported {created + updated} of {len(original_data)} rows '
            f'(created: {created}, updated: {updated}, skipped: {skipped}).'
        )
        if errors:
            html += '<hr class="my-1"><small class="text-danger">'
            html += '<br>'.join([f'Row {e["row"]}: {", ".join(e["errors"])}' for e in errors])
            html += '</small>'
        html += '</div>'
        return HttpResponse(html)
    return redirect('task-list')


@login_required
def task_import_template(request):
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="task_import_template.csv"'
    writer = csv.writer(response)
    writer.writerow(['job_id', 'email_from', 'email_subject', 'task_type', 'task_detail', 'priority', 'status', 'assign_to', 'note', 'create_at', 'dbname', 'userid'])
    writer.writerow(['XLS-2026080001', 'user@example.com', 'Sample task', 'General', 'Task details here', 'Medium', 'Open', 'IT Support', 'Optional note', '2026-08-04 10:00:00', 'postgres-prod', 'john.doe'])
    return response


# ---------------------------------------------------------------------------
# Authentication views
# ---------------------------------------------------------------------------

def logout_view(request):
    """Accepts GET and POST — logs out and redirects to /login/."""
    from django.http import HttpResponseRedirect
    logout(request)
    return HttpResponseRedirect('/login/')
