-- Setup Database untuk n8n
-- Jalankan dengan: psql -U postgres -p 5008 -f setup-db.sql

-- Buat database n8n (jika belum ada)
SELECT 'CREATE DATABASE n8n'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'n8n'
)\gexec

-- Verifikasi database berhasil dibuat
\l n8n
