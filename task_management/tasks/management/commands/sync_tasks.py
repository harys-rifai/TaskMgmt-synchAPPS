import json
import os
import sys
from pathlib import Path

from django.core.management.base import BaseCommand
from django.db import IntegrityError
from django.utils import timezone

from tasks.models import Task, Team, TaskSync


class Command(BaseCommand):
    help = 'Sync tasks from external JSON. Accepts a JSON file path or raw JSON string.'

    def add_arguments(self, parser):
        parser.add_argument(
            'source',
            type=str,
            help='Source name (e.g. n8n, clickup, teams, whatsapp, telegram)',
        )
        parser.add_argument(
            'input',
            type=str,
            help='JSON file path or raw JSON array string',
        )

    def handle(self, *args, **options):
        source = options['source']
        input_val = options['input']

        if os.path.exists(input_val):
            with open(input_val, 'r', encoding='utf-8') as f:
                try:
                    items = json.load(f)
                except json.JSONDecodeError as e:
                    self.stderr.write(self.style.ERROR(f'Invalid JSON file: {e}'))
                    sys.exit(1)
        else:
            try:
                items = json.loads(input_val)
            except json.JSONDecodeError:
                self.stderr.write(self.style.ERROR(
                    'Input is not a valid file path or JSON string. '
                    'Provide a path to a JSON file or a raw JSON array string.'
                ))
                sys.exit(1)

        if not isinstance(items, list):
            self.stderr.write(self.style.ERROR('JSON must be an array of items.'))
            sys.exit(1)

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
            email_from = item.get('email_from', '')

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

        self.stdout.write(self.style.SUCCESS(
            f'Sync complete — created: {created}, updated: {updated}, skipped: {skipped}'
        ))
        if errors:
            self.stderr.write(self.style.WARNING('Errors:'))
            for err in errors:
                self.stderr.write(f"  {err['external_id']}: {err['error']}")
