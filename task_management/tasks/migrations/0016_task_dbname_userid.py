from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0015_jobcounter'),
    ]

    operations = [
        migrations.AddField(
            model_name='task',
            name='dbname',
            field=models.CharField(blank=True, db_index=True, help_text='Database name if task relates to a specific database', max_length=255),
        ),
        migrations.AddField(
            model_name='task',
            name='userid',
            field=models.CharField(blank=True, db_index=True, help_text='User ID if task relates to a specific user', max_length=255),
        ),
    ]
