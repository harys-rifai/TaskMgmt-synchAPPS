from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from django.contrib.auth import views as auth_views
from tasks import views as v


def root_redirect(request):
    """Handles GET and POST to root — always redirects to login."""
    from django.shortcuts import redirect
    return redirect('/login/')


urlpatterns = [
    path('admin/',          admin.site.urls),
    path('task-api/',       include('tasks.urls')),

    # Root — method-safe redirect to login
    path('',                root_redirect, name='home'),

    # Auth
    path('login/',          auth_views.LoginView.as_view(
                                template_name='tasks/login.html',
                                redirect_authenticated_user=True,
                            ), name='login'),
    path('logout/',         v.logout_view, name='logout'),

    # Dashboard
    path('dashboard/',      v.dashboard_page,       name='dashboard'),

    # Task list & HTMX partial (supports ?view=table|list|board|card)
    path('tasks/',          v.task_list_page,        name='task-list'),
    path('tasks/board/',    v.task_list_page,        name='task-board'),
    path('tasks/rows/',     v.task_rows_partial,     name='task-rows'),

    # Task import (CSV / Excel)
    path('tasks/import/',          v.task_import_page,     name='task-import'),
    path('tasks/import/confirm/',  v.task_import_confirm,  name='task-import-confirm'),
    path('tasks/import/template/', v.task_import_template, name='task-import-template'),

    # Task create
    path('tasks/create/',   v.task_create_page,      name='task-create'),
    path('tasks/create-modal/', v.task_create_modal, name='task-create-modal'),

    # Task detail / edit
    path('tasks/<int:pk>/',         v.task_detail_page,    name='task-detail'),
    path('tasks/<int:pk>/edit/',    v.task_edit_page,      name='task-edit'),

    # HTMX actions on a task
    path('tasks/<int:pk>/update-status/', v.task_update_status, name='task-update-status'),
    path('tasks/<int:pk>/add-note/',      v.task_add_note,      name='task-add-note'),
    path('tasks/<int:pk>/delete/',        v.task_delete,        name='task-delete'),
    path('tasks/<int:pk>/assign/',        v.task_assign_form,   name='task-assign-form'),
    path('tasks/<int:pk>/do-assign/',     v.task_do_assign,     name='task-do-assign'),
    path('tasks/<int:pk>/board-move/',    v.task_board_move,    name='task-board-move'),
    path('tasks/<int:pk>/attachments/<int:attachment_id>/delete/', v.task_attachment_delete, name='task-attachment-delete'),

    # HTMX dashboard partials
    path('partials/by-status/',   v.partial_by_status,   name='partial-by-status'),
    path('partials/by-priority/', v.partial_by_priority, name='partial-by-priority'),
    path('partials/by-team/',     v.partial_by_team,     name='partial-by-team'),

    # Other pages
    path('assignment/',     v.assignment_page,      name='assignment'),
    path('reports/',        v.reports_page,         name='reports'),
    path('admin-page/',     v.admin_page,           name='admin-page'),
    path('backup/',         v.backup_page,          name='backup'),

    # Email configuration
    path('admin-page/email/save/', v.email_config_save, name='email-config-save'),
    path('admin-page/email/test/', v.email_config_test, name='email-config-test'),

    # n8n configuration
    path('admin-page/n8n/save/', v.n8n_config_save, name='n8n-config-save'),
    path('admin-page/n8n/test/', v.n8n_config_test, name='n8n-config-test'),

    # ClickUp configuration
    path('admin-page/clickup/save/', v.clickup_config_save, name='clickup-config-save'),
    path('admin-page/clickup/test/', v.clickup_config_test, name='clickup-config-test'),
    path('admin-page/clickup/test/<int:pk>/', v.clickup_config_test, name='clickup-config-test-pk'),

    # Redis configuration
    path('admin-page/redis/save/', v.redis_config_save, name='redis-config-save'),
    path('admin-page/redis/test/', v.redis_config_test, name='redis-config-test'),

    # Database configuration
    path('admin-page/database/save/', v.database_config_save, name='database-config-save'),
    path('admin-page/database/test/', v.database_config_test, name='database-config-test'),

    # WhatsApp configuration
    path('admin-page/whatsapp/save/', v.whatsapp_config_save, name='whatsapp-config-save'),
    path('admin-page/whatsapp/test/', v.whatsapp_config_test, name='whatsapp-config-test'),

    # Telegram configuration
    path('admin-page/telegram/save/', v.telegram_config_save, name='telegram-config-save'),
    path('admin-page/telegram/test/', v.telegram_config_test, name='telegram-config-test'),

    # Assignment rules
    path('admin-page/rules/add/', v.assignment_rule_add, name='assignment-rule-add'),
    path('admin-page/rules/delete/<str:keyword>/', v.assignment_rule_delete, name='assignment-rule-delete'),

    # Webhooks
    path('webhooks/n8n/', v.n8n_webhook, name='n8n-webhook'),
    path('webhooks/action-network/', v.action_network_webhook, name='action-network-webhook'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
