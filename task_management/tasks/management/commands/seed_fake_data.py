import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.db import transaction, connection
from django.utils import timezone

from tasks.models import Task, Team


class Command(BaseCommand):
    help = 'Seed fake task data with random created_at from January 2026 to today, auto-generated job IDs, and task_type derived from assigned team.'

    PRIORITIES = ['High', 'Medium', 'Low']
    STATUSES = ['Open', 'Assigned', 'In Progress', 'Pending User',
                'Pending Vendor', 'Completed', 'Closed', 'Rejected', 'Cancelled']
    FROM_EMAILS = ['support@company.com', 'info@client.com',
                   'noreply@n8n.io', 'admin@team.io', 'user@domain.com',
                   'dev@startup.com', 'ops@company.com', 'hr@company.com']
    SUBJECTS = [
        'Task assignment request', 'Follow-up on ticket', 'Urgent: Server issue',
        'Data sync report', 'Weekly status update', 'Client onboarding',
        'Bug fix: API endpoint', 'Feature request: export', 'Payment processing issue',
        'Database backup needed', 'Security review', 'Performance optimisation',
        'Integration testing', 'Documentation update', 'Access request',
        'Network downtime', 'Application deployment', 'User access provisioning',
    ]

    def add_arguments(self, parser):
        parser.add_argument('--count', type=int, default=600,
                            help='Total number of fake tasks to create (default: 600)')

    def handle(self, *args, **options):
        count = options['count']
        now = timezone.now()
        jan_1 = now.replace(year=now.year, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)

        # Remove previously seeded data for idempotency
        Task.objects.filter(job_id__startswith='XLS').delete()
        self.stdout.write(f'Cleaned up old XLS tasks. Starting seed of {count} tasks...')

        # Get active teams
        teams = list(Team.objects.filter(is_active=True))
        if not teams:
            self.stdout.write(self.style.WARNING('No active teams found. Creating with unassigned.'))
            teams = []

        # Determine starting job counter
        last = Task.objects.filter(job_id__startswith='XLS').order_by('-job_id').first()
        start_num = 1
        if last:
            parts = last.job_id.split('-')
            if len(parts) == 2 and parts[1].isdigit():
                start_num = int(parts[1]) + 1

        tasks_to_create = []
        for i in range(count):
            team = random.choice(teams) if teams else None
            task_type = self._derive_task_type(team)

            # Random created_at between Jan 1 and now
            total_seconds = int((now - jan_1).total_seconds())
            random_seconds = random.randint(0, total_seconds)
            created_at = jan_1 + timedelta(seconds=random_seconds)

            status = random.choices(
                self.STATUSES,
                weights=[15, 10, 15, 5, 5, 10, 15, 10, 10]
            )[0]

            closed_at = None
            if status in ('Closed', 'Completed', 'Cancelled', 'Rejected') and random.random() > 0.2:
                closed_at = created_at + timedelta(hours=random.randint(1, 120))

            job_id = Task.get_next_job_id()

            task = Task(
                job_id=job_id,
                email_from=random.choice(self.FROM_EMAILS),
                email_subject=random.choice(self.SUBJECTS),
                task_type=task_type,
                task_detail='This is a seed task created for reporting trend data.',
                assign_to=team,
                priority=random.choices(self.PRIORITIES, weights=[20, 50, 30])[0],
                status=status,
                note=random.choice(self.SUBJECTS) + ' - additional context here.',
                source=random.choice(['email', 'teams', 'clickup', 'whatsapp', 'telegram']),
                external_id=f'ext-{random.randint(10000, 99999)}',
            )
            task._seed_created_at = created_at
            task._seed_closed_at = closed_at
            tasks_to_create.append(task)

        with transaction.atomic():
            Task.objects.bulk_create(tasks_to_create, batch_size=50)

            # Update created_at and closed_at via raw SQL
            # (bypasses auto_now_add / auto_now which can't be set during bulk_create)
            updates = []
            for task in tasks_to_create:
                updates.append((
                    task._seed_created_at,
                    task._seed_closed_at,
                    task.pk,
                ))

            with connection.cursor() as cursor:
                cursor.executemany(
                    'UPDATE tasks_task SET created_at = %s, closed_at = %s WHERE id = %s',
                    updates
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {len(tasks_to_create)} fake tasks '
                f'(Jan 2026 – today) with auto job IDs and team-derived task types.'
            )
        )

    def _derive_task_type(self, team):
        if not team:
            return random.choice(['Email', 'Webhook', 'Manual'])
        name = team.name.lower()
        if 'sap' in name:
            return 'SAP'
        if 'dba' in name or 'database' in name:
            return 'Database'
        if 'network' in name:
            return 'Network'
        if 'app' in name:
            return 'Application Support'
        if 'it' in name or 'support' in name:
            return 'IT Support'
        if 'sales' in name:
            return 'Sales'
        if 'hr' in name or 'human' in name:
            return 'HR'
        if 'finance' in name:
            return 'Finance'
        return team.name
