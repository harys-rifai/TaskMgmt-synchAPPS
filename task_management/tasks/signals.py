from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .models import Task
from .notifications import send_task_notifications


@receiver(pre_save, sender=Task)
def task_pre_save(sender, instance, **kwargs):
    if instance.pk:
        try:
            old = Task.objects.only('status', 'assign_to_id').get(pk=instance.pk)
            instance._old_status = old.status
            instance._old_assign_to_id = old.assign_to_id
        except Task.DoesNotExist:
            instance._old_status = None
            instance._old_assign_to_id = None
    else:
        instance._old_status = None
        instance._old_assign_to_id = None


@receiver(post_save, sender=Task)
def on_task_changed(sender, instance, created, **kwargs):
    if created:
        send_task_notifications(instance, event='created')
        return

    old_status = getattr(instance, '_old_status', None)
    old_assign_to_id = getattr(instance, '_old_assign_to_id', None)

    status_changed = old_status is not None and old_status != instance.status
    assignee_changed = old_assign_to_id is not None and old_assign_to_id != instance.assign_to_id

    if status_changed or assignee_changed:
        send_task_notifications(instance, event='updated')
