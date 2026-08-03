import requests
from django.core.mail import EmailMessage
from django.conf import settings
from django.utils import timezone
from .models import TelegramConfig, WhatsAppConfig, EmailConfig


TASK_NOTIFY_PREFIX = '[TaskMgmt]'


def _build_task_text(task, event='created'):
    status = task.get_status_display() if hasattr(task, 'get_status_display') else task.status
    assignee = task.assign_to.name if task.assign_to else 'Unassigned'
    updated = timezone.localtime(task.updated_at).strftime('%Y-%m-%d %H:%M')
    header = 'New Task Created' if event == 'created' else 'Task Updated'
    lines = [
        f'{header}',
        f'Job ID   : {task.job_id}',
        f'Subject  : {task.email_subject}',
        f'Type     : {task.task_type}',
        f'Priority : {task.priority}',
        f'Status   : {status}',
        f'Assignee : {assignee}',
        f'From     : {task.email_from}',
        f'Detail   : {task.task_detail}',
        f'Updated  : {updated}',
    ]
    return '\n'.join(lines)


def send_telegram(task, event='created'):
    cfg = TelegramConfig.get()
    if not cfg.is_active or not cfg.bot_token or not cfg.chat_id:
        return
    try:
        text = _build_task_text(task, event)
        requests.post(
            f'https://api.telegram.org/bot{cfg.bot_token}/sendMessage',
            json={
                'chat_id': cfg.chat_id,
                'text': text,
                'parse_mode': 'HTML',
            },
            timeout=10,
        )
    except Exception:
        pass


def send_email(task, event='created'):
    cfg = EmailConfig.get()
    if not cfg.is_active or not cfg.host or not cfg.username:
        return
    try:
        backend = EmailMessage(
            subject=f'{TASK_NOTIFY_PREFIX} New Task: {task.job_id}' if event == 'created' else f'{TASK_NOTIFY_PREFIX} Task Updated: {task.job_id}',
            body=_build_task_text(task, event),
            from_email=cfg.get_from_address(),
            to=[cfg.username],
        )
        backend.send(fail_silently=True)
    except Exception:
        pass


def send_whatsapp(task, event='created'):
    cfg = WhatsAppConfig.get()
    if not cfg.is_active or not cfg.api_token or not cfg.phone_number_id:
        return
    try:
        text = _build_task_text(task, event)
        requests.post(
            f'https://graph.facebook.com/v18.0/{cfg.phone_number_id}/messages',
            headers={
                'Authorization': f'Bearer {cfg.api_token}',
                'Content-Type': 'application/json',
            },
            json={
                'messaging_product': 'whatsapp',
                'to': cfg.phone_number_id,
                'text': {'body': text},
            },
            timeout=10,
        )
    except Exception:
        pass


def send_task_notifications(task, event='created'):
    send_telegram(task, event)
    send_email(task, event)
    send_whatsapp(task, event)
