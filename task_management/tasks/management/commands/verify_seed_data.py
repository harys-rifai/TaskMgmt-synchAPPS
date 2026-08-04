from django.core.management.base import BaseCommand
from django.core.cache import cache
from django.utils import timezone
from django.db.models import Count
from tasks.models import Task


class Command(BaseCommand):
    help = 'Verify seeded data distribution'

    def handle(self, *args, **options):
        cache.clear()
        now = timezone.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        jan1 = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)

        self.stdout.write('=== Monthly Distribution ===')
        for m in range(1, now.month + 1):
            m_start = now.replace(month=m, day=1, hour=0, minute=0, second=0, microsecond=0)
            if m < 12:
                m_next = now.replace(month=m + 1, day=1, hour=0, minute=0, second=0, microsecond=0)
            else:
                m_next = now.replace(year=now.year + 1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
            created = Task.objects.filter(created_at__gte=m_start, created_at__lt=m_next).count()
            closed = Task.objects.filter(status='Closed', closed_at__gte=m_start, closed_at__lt=m_next).count()
            label = m_start.strftime('%b %Y')
            self.stdout.write(f'  {label}: created={created}, closed={closed}')

        total = Task.objects.count()
        xls = Task.objects.filter(job_id__startswith='XLS').count()
        self.stdout.write(f'\nTotal tasks: {total}')
        self.stdout.write(f'XLS tasks: {xls}')

        earliest = Task.objects.order_by('created_at').first()
        latest = Task.objects.order_by('created_at').last()
        self.stdout.write(f'Earliest created_at: {earliest.created_at}')
        self.stdout.write(f'Latest created_at: {latest.created_at}')

        self.stdout.write('\n=== Task Type Distribution ===')
        for t in Task.objects.values('task_type').annotate(count=Count('id')).order_by('-count'):
            self.stdout.write(f'  {t["task_type"]}: {t["count"]}')

        self.stdout.write('\n=== Status Distribution ===')
        for t in Task.objects.values('status').annotate(count=Count('id')).order_by('-count'):
            self.stdout.write(f'  {t["status"]}: {t["count"]}')

        self.stdout.write('\n=== Weekly Trend (7 days) ===')
        for i in range(6, -1, -1):
            day_start = today_start - timezone.timedelta(days=i)
            day_end = day_start + timezone.timedelta(days=1)
            created = Task.objects.filter(created_at__gte=day_start, created_at__lt=day_end).count()
            closed = Task.objects.filter(status='Closed', closed_at__gte=day_start, closed_at__lt=day_end).count()
            label = day_start.strftime('%a %d %b')
            self.stdout.write(f'  {label}: created={created}, closed={closed}')
