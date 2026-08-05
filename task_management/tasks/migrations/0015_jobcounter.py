from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0014_alter_email_from_to_charfield'),
    ]

    operations = [
        migrations.CreateModel(
            name='JobCounter',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('period_yyyymm', models.CharField(max_length=6, unique=True)),
                ('last_number', models.IntegerField(default=0)),
            ],
            options={
                'db_table': 'task_job_counter',
            },
        ),
        migrations.RunSQL(
            sql="""
CREATE OR REPLACE FUNCTION "public"."generate_job_id"()
RETURNS "pg_catalog"."varchar" AS $BODY$
DECLARE
    v_period varchar(6);
    v_next_no integer;
BEGIN
    v_period := to_char(now(), 'YYYYMM');

    INSERT INTO task_job_counter (
        period_yyyymm,
        last_number
    )
    VALUES (
        v_period,
        1
    )
    ON CONFLICT (period_yyyymm)
    DO UPDATE SET
        last_number = task_job_counter.last_number + 1
    RETURNING task_job_counter.last_number
    INTO v_next_no;

    RETURN
        'XLS-' ||
        v_period ||
        lpad(v_next_no::text, 4, '0');
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
""",
            reverse_sql="DROP FUNCTION IF EXISTS generate_job_id();",
        ),
    ]
