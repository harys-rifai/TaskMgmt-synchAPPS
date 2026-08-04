import logging
import requests
from django.core.mail import EmailMessage
from django.core.mail.backends.smtp import EmailBackend as SMTPBackend
from django.utils import timezone
from .models import TelegramConfig, WhatsAppConfig, EmailConfig


logger = logging.getLogger(__name__)

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
        resp = requests.post(
            f'https://api.telegram.org/bot{cfg.bot_token}/sendMessage',
            json={
                'chat_id': cfg.chat_id,
                'text': text,
                'parse_mode': 'HTML',
            },
            timeout=10,
        )
        if not resp.ok:
            logger.warning(
                'Telegram notification failed for task %s: HTTP %s — %s',
                task.job_id, resp.status_code, resp.text[:200],
            )
    except Exception as exc:
        logger.exception('Telegram notification error for task %s: %s', task.job_id, exc)


def send_email(task, event='created'):
    cfg = EmailConfig.get()
    if not cfg.is_active or not cfg.host or not cfg.username:
        return
    try:
        # Build an explicit SMTP backend from the saved config so the
        # notification always uses the credentials stored in EmailConfig,
        # independent of whatever Django's default EMAIL_* settings say.
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
        subject = (
            f'{TASK_NOTIFY_PREFIX} New Task: {task.job_id}'
            if event == 'created'
            else f'{TASK_NOTIFY_PREFIX} Task Updated: {task.job_id}'
        )
        mail = EmailMessage(
            subject=subject,
            body=_build_task_text(task, event),
            from_email=cfg.get_from_address(),
            to=[cfg.username],
            connection=backend,
        )
        mail.send()
    except Exception as exc:
        logger.exception('Email notification error for task %s: %s', task.job_id, exc)


def send_whatsapp(task, event='created'):
    cfg = WhatsAppConfig.get()
    if not cfg.is_active or not cfg.api_token or not cfg.phone_number_id:
        return

    # The recipient must be a real E.164 phone number stored separately from
    # the phone_number_id (which identifies the *sending* number, not the
    # destination).  We fall back to business_account_id if no dedicated
    # recipient field exists, but log a clear warning so the misconfiguration
    # is visible.
    to_number = getattr(cfg, 'to_phone_number', '').strip() or ''
    if not to_number:
        logger.warning(
            'WhatsApp notification skipped for task %s: no recipient phone number '
            'configured (to_phone_number is empty). Set a destination number in '
            'WhatsApp Configuration.',
            task.job_id,
        )
        return

    try:
        text = _build_task_text(task, event)
        resp = requests.post(
            f'https://graph.facebook.com/v18.0/{cfg.phone_number_id}/messages',
            headers={
                'Authorization': f'Bearer {cfg.api_token}',
                'Content-Type': 'application/json',
            },
            json={
                'messaging_product': 'whatsapp',
                'to': to_number,
                'type': 'text',
                'text': {'body': text},
            },
            timeout=10,
        )
        if not resp.ok:
            logger.warning(
                'WhatsApp notification failed for task %s: HTTP %s — %s',
                task.job_id, resp.status_code, resp.text[:200],
            )
    except Exception as exc:
        logger.exception('WhatsApp notification error for task %s: %s', task.job_id, exc)


def send_task_notifications(task, event='created'):
    send_telegram(task, event)
    send_email(task, event)
    send_whatsapp(task, event)
