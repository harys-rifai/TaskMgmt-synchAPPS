-- Analytics view: tasks_task_analytics
-- View ini menyediakan kolom "target_name" yang menggabungkan database name,
-- server name, IP address, atau aplikasi lain yang disebutkan dalam task_detail.
-- Digunakan untuk tagging report dan data analytics eksternal (BI tools, Metabase, dsb).
--
-- Cara pakai:
--   psql -U postgres -p 5008 -d taskdb -f analytics_view.sql
--
-- Atau query langsung:
--   SELECT * FROM task_task_analytics WHERE target_name != '—' LIMIT 20;

CREATE OR REPLACE VIEW task_task_analytics AS
SELECT
    t.id,
    t.job_id,
    t.email_from,
    t.email_subject,
    t.task_type,
    t.task_detail,
    t.priority,
    t.status,
    t.source,
    t.external_id,
    t.assign_to_id,
    team.name AS assign_to_name,
    -- target_name: mengekstrak target (IP, server, database, aplikasi) dari task_detail
    CASE
        -- IP address
        WHEN t.task_detail ~ '\m(\d{1,3}\.){3}\d{1,3}\M'
        THEN 'IP: ' || (SELECT c FROM (SELECT regexp_match(t.task_detail, '(\d{1,3}\.){3}\d{1,3}') AS m) s, unnest(s.m) AS c LIMIT 1)

        -- Database / server patterns
        WHEN lower(t.task_detail) ~ '(postgres|mysql|mongo|redis|database|db|api-ms)'
        THEN
            COALESCE(
                initcap(t.task_type),
                'Unknown Target'
            )

        -- fallback to task_type or team name
        WHEN t.assign_to_id IS NOT NULL THEN team.name
        ELSE COALESCE(t.task_type, '—')
    END AS target_name,

    t.created_at,
    t.updated_at,
    t.closed_at,

    -- Derived: days open (for SLA monitoring)
    CASE
        WHEN t.closed_at IS NOT NULL THEN EXTRACT(EPOCH FROM (t.closed_at - t.created_at)) / 3600
        ELSE EXTRACT(EPOCH FROM (NOW() - t.created_at)) / 3600
    END AS hours_open,

    -- Derived: overdue status (open > 48 hours = SLA hours)
    CASE
        WHEN t.status IN ('Open', 'Assigned', 'In Progress')
             AND t.created_at < NOW() - INTERVAL '48 hours'
        THEN TRUE
        ELSE FALSE
    END AS is_overdue
FROM tasks_task t
LEFT JOIN tasks_team team ON t.assign_to_id = team.id;

COMMENT ON VIEW task_task_analytics IS
    'Analytics view with computed target_name column for reporting. '
    'target_name combines database name, server name, IP address, '
    'or application identifier extracted from task_detail.';
