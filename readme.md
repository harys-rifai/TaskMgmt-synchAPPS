# Task Management Email Automation — n8n + Django + PostgreSQL + Redis

Panduan lengkap untuk membangun sistem otomasi email manajemen tugas menggunakan n8n, Django, PostgreSQL, dan Redis di Windows.

## Fitur

- **Task Management**: CRUD tasks dengan job ID otomatis sequential (XLS-YYYYMM0001, XLS-YYYYMM0002, ...), multi-view (table/board/list/card), search, filter, CSV/Excel import dengan preview
- **Email Integration**: Konfigurasi SMTP via admin page (Gmail, Outlook, SendGrid, dll) dengan test connection
- **n8n Integration**: Workflow automation dengan test connection di admin, webhook endpoint `/webhooks/n8n/`
- **ClickUp Integration**: Sync tasks dari ClickUp dengan API token tersimpan di database
- **Redis Cache**: URL Redis, aktif/nonaktif, test connection, start Redis lokal otomatis, flush cache — semua dikonfigurasi via admin page
- **Database Configuration**: Konfigurasi koneksi database (PostgreSQL/SQLite3) dengan test connection via admin page
- **Auto-Assignment Rules**: Keyword-based team assignment dengan UI CRUD di admin page
- **External App Sync**: Sync dari Email, Teams, ClickUp, WhatsApp, Telegram, Action Network, n8n via API/webhook
- **Action Network Integration**: Webhook endpoint `/webhooks/action-network/` dan test connection
- **Backup**: Backup PostgreSQL & Redis via UI di halaman `/backup/`
- **Django Admin**: Test connection buttons untuk semua config (Email, n8n, ClickUp, Redis, Database, WhatsApp, Telegram, Action Network)

---

# Arsitektur

```text
Windows Server / Windows 10/11
      │
      ├── PostgreSQL (Port 5008)
      │   ├── Database n8n (n8n workflow engine)
      │   └── Database taskdb (Django task management)
      │
      ├── Redis (Port 6379)
      │   ├── n8n queue & cache
      │   └── Django cache / session
      │
      ├── Node.js
      │
      ├── n8n (Port 5678)
      │   ├── OpenAI
      │   ├── Azure OpenAI
      │   ├── Ollama
      │   └── Microsoft 365
      │
      └── Django API (Port 8000)
          ├── Task Service
          ├── User Service
          ├── Assignment Service
          └── Reporting Service
```

---

# Prasyarat

Pastikan Windows memiliki:

- Windows 10 atau Windows 11
- Administrator Access
- Minimal 8 GB RAM
- Internet Connection
- PostgreSQL 18+ terinstal
- Redis terinstal (atau Redis Cloud)

---

# 1. Install PostgreSQL

Download PostgreSQL:

https://www.postgresql.org/download/windows/

Install dengan konfigurasi berikut:

```text
User     : postgres
Password : Password09!
Port     : 5008
```

---

## Verifikasi PostgreSQL

Buka Command Prompt:

```cmd
psql --version
```

Contoh:

```text
psql (PostgreSQL) 18.x
```

---

## Buat Database

Buka SQL Shell (psql):

```cmd
psql -U postgres -p 5008
```

Masukkan password:

```text
Password09!
```

Buat database untuk n8n:

```sql
CREATE DATABASE n8n;
```

Buat database untuk Django:

```sql
CREATE DATABASE taskdb;
```

Verifikasi:

```sql
\l
```

Harus muncul:

```text
n8n
taskdb
```

Keluar:

```sql
\q
```

---

# 2. Install Redis

## Opsi A: Redis lokal (Windows)

Download Redis:

https://github.com/tporadowski/redis/releases

Install dan jalankan:

```cmd
redis-server.exe --port 6379
```

Verifikasi:

```cmd
redis-cli ping
```

Hasil yang diharapkan:

```text
PONG
```

## Opsi B: Redis Cloud (recommended untuk production)

Daftar di https://redis.io/cloud/

Gunakan connection string:

```text
redis://default:<password>@<host>:<port>
```

Contoh:

```text
redis-cli -u redis://default:Kp2MdJmmsJTBx6rLy5fmvmkJNKXWBrJR@redis-19062.c15.us-east-1-4.ec2.cloud.redislabs.com:19062
```

---

# 3. Install Node.js

Download versi LTS:

https://nodejs.org

Verifikasi:

```cmd
node -v
npm -v
```

Contoh:

```text
v22.x.x
10.x.x
```

---

# 4. Install n8n

Buka Command Prompt sebagai Administrator:

```cmd
npm install n8n -g
```

Verifikasi:

```cmd
n8n --version
```

---

# 5. Konfigurasi Environment Variables

Buat folder:

```text
C:\n8n
```

Buat file:

```text
C:\n8n\.env
```

Isi dengan konfigurasi berikut:

```env
DB_TYPE=postgresdb

DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5008
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=Password09!

N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

N8N_SECURE_COOKIE=false

GENERIC_TIMEZONE=Asia/Jakarta

OPENAI_API_KEY=YOUR_OPENAI_KEY

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
```

---

# 6. Menjalankan n8n

Buka Command Prompt:

```cmd
cd C:\n8n
```

Set environment:

```cmd
set DB_TYPE=postgresdb
set DB_POSTGRESDB_HOST=localhost
set DB_POSTGRESDB_PORT=5008
set DB_POSTGRESDB_DATABASE=n8n
set DB_POSTGRESDB_USER=postgres
set DB_POSTGRESDB_PASSWORD=Password09!
set REDIS_HOST=localhost
set REDIS_PORT=6379
```

Jalankan:

```cmd
n8n
```

---

# 7. Akses n8n

Buka browser:

```text
http://localhost:5678
```

Saat pertama kali login:

- Buat akun Admin
- Simpan username dan password

---

# 8. Menjalankan n8n Sebagai Service Windows

Install PM2:

```cmd
npm install pm2 -g
```

Jalankan:

```cmd
pm2 start n8n
```

Simpan konfigurasi:

```cmd
pm2 save
```

Aktifkan startup:

```cmd
pm2 startup
```

---

# 9. Integrasi OpenAI

Masuk ke:

```text
Settings → Credentials
```

Pilih:

```text
OpenAI API
```

Masukkan:

```text
API Key
```

Contoh:

```text
sk-xxxxxxxxxxxxxxxx
```

---

# 10. Integrasi Azure OpenAI

Masuk ke:

```text
Credentials
```

Buat credential baru:

```text
Azure OpenAI
```

Isi:

```text
Endpoint
API Key
Deployment Name
API Version
```

Contoh:

```text
Model : gpt-4o
```

---

# 11. Integrasi Ollama (AI Lokal)

Download:

https://ollama.com/download

Verifikasi:

```cmd
ollama --version
```

---

## Download Model

Llama 3:

```cmd
ollama pull llama3
```

Qwen:

```cmd
ollama pull qwen3
```

Mistral:

```cmd
ollama pull mistral
```

---

## Menjalankan Model

```cmd
ollama run llama3
```

API tersedia di:

```text
http://localhost:11434
```

---

## Koneksi dari n8n

Tambahkan:

```text
HTTP Request Node
```

Method:

```text
POST
```

URL:

```text
http://localhost:11434/api/generate
```

Request Body:

```json
{
  "model": "llama3",
  "prompt": "Buat ringkasan dokumen berikut"
}
```

---

# 12. Workflow AI Meeting Minutes

```text
Microsoft Teams
        │
        ▼
Meeting Transcript
        │
        ▼
OpenAI / Ollama
        │
        ▼
Summary
        │
        ▼
Action Items
        │
        ▼
Teams Channel
```

---

# 13. Workflow Email Classification

```text
Outlook Email
       │
       ▼
OpenAI
       │
       ▼
Priority Detection
       │
       ▼
Planner Task
```

---

# 14. Koneksi PostgreSQL dari DBeaver atau pgAdmin

### n8n Database

```text
Host     : localhost
Port     : 5008
Database : n8n
User     : postgres
Password : Password09!
```

### Django Database (taskdb)

```text
Host     : localhost
Port     : 5008
Database : taskdb
User     : postgres
Password : Password09!
```

---

# 15. Koneksi Redis

### Redis Lokal

```text
Host     : localhost
Port     : 6379
Password : (none)
DB       : 0
```

### Redis Cloud

```text
Host     : redis-19062.c15.us-east-1-4.ec2.cloud.redislabs.com
Port     : 19062
Password : Kp2MdJmmsJTBx6rLy5fmvmkJNKXWBrJR
DB       : 0
```

### Test Koneksi Redis

```cmd
redis-cli -u redis://default:Kp2MdJmmsJTBx6rLy5fmvmkJNKXWBrJR@redis-19062.c15.us-east-1-4.ec2.cloud.redislabs.com:19062 ping
```

Hasil yang diharapkan:

```text
PONG
```

---

# 16. Backup Database

Backup n8n:

```cmd
pg_dump -h localhost -p 5008 -U postgres -d n8n > n8n_backup.sql
```

Backup taskdb:

```cmd
pg_dump -h localhost -p 5008 -U postgres -d taskdb > taskdb_backup.sql
```

Restore n8n:

```cmd
psql -h localhost -p 5008 -U postgres -d n8n < n8n_backup.sql
```

Restore taskdb:

```cmd
psql -h localhost -p 5008 -U postgres -d taskdb < taskdb_backup.sql
```

## Backup via UI

Selain perintah manual di atas, aplikasi juga menyediakan halaman backup UI di:

```text
http://localhost:8000/backup/
```

Fitur:
- **Backup PostgreSQL**: Trigger `pg_dump` via UI, simpan ke `C:\www\n8n\backup\`
- **Backup Redis**: Trigger `BGSAVE` via UI (RDB file dibuat di Redis server)
- **Download**: Unduh file backup yang sudah ada
- **Daftar backup**: Lihat semua file backup yang tersedia

---

# 17. Django Task Management API

## Installasi

```bash
cd C:\www\n8n\task_management
pip install -r requirements.txt
```

## Database Setup

```sql
CREATE DATABASE taskdb;
```

## Migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

## Superuser

```bash
python manage.py createsuperuser
```

## Menjalankan Server

```bash
python manage.py runserver 0.0.0.0:8000
```

Atau gunakan script:

```cmd
start-django.cmd
```

---

## REST API Endpoints

### Task Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/task-api/tasks/` | List semua task |
| POST | `/task-api/tasks/` | Buat task baru |
| GET | `/task-api/tasks/{id}/` | Detail task |
| PATCH | `/task-api/tasks/{id}/` | Update task |
| DELETE | `/task-api/tasks/{id}/` | Hapus task |

### Team Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/task-api/teams/` | List semua team |
| POST | `/task-api/teams/` | Buat team baru |
| GET | `/task-api/teams/{id}/` | Detail team |
| PATCH | `/task-api/teams/{id}/` | Update team |
| DELETE | `/task-api/teams/{id}/` | Hapus team |

### Dashboard Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/task-api/tasks/dashboard/` | Metrics ringkasan |
| GET | `/task-api/tasks/by-status/` | Task per status |
| GET | `/task-api/tasks/by-priority/` | Task per priority |
| GET | `/task-api/tasks/by-team/` | Task per team |

---

## Contoh Request Buat Task (dari n8n)

```http
POST /task-api/tasks/
Content-Type: application/json

{
  "job_id": "XLS2608-0001",
  "email_from": "user@company.com",
  "email_subject": "SAP Access",
  "task_type": "Access Request",
  "task_detail": "Create SAP Access",
  "priority": "Medium",
  "status": "Open"
}
```

---

## Contoh Response

```json
{
  "id": 1,
  "job_id": "XLS2608-0001",
  "email_from": "user@company.com",
  "email_subject": "SAP Access",
  "task_type": "Access Request",
  "task_detail": "Create SAP Access",
  "assign_to": null,
  "priority": "Medium",
  "note": "",
  "status": "Open",
  "created_at": "2026-08-02T22:38:44+07:00",
  "updated_at": "2026-08-02T22:38:44+07:00",
  "closed_at": null
}
```

---

## Halaman Dashboard

| Halaman | URL | Description |
|---------|-----|-------------|
| Dashboard | `/dashboard/` | Executive summary |
| Tasks | `/tasks/` | Task list dengan search/filter, multi-view (table/board/list/card) |
| Create Task | `/tasks/create/` | Form buat task baru |
| Import | `/tasks/import/` | CSV/Excel import dengan validasi & editable preview |
| Assignment | `/assignment/` | Task allocation |
| Reports | `/reports/` | Daily/weekly/monthly reports |
| Backup | `/backup/` | Backup PostgreSQL & Redis via UI |
| Admin | `/admin-page/` | Konfigurasi integrasi, teams, rules, sync |
| Admin API | `/admin/` | Django admin panel |

## Admin Page (`/admin-page/`)

Halaman admin menyediakan konfigurasi terpusat untuk semua integrasi, dengan status koneksi real-time (auto-check setiap 5 menit) dan tombol Test Connection untuk masing-masing:

- **Teams**: Daftar tim yang dapat menerima task assignment
- **Auto-Assignment Rules**: Tambah/hapus keyword-based team assignment rules (CRUD via UI)
- **Email Configuration**: Konfigurasi SMTP (Gmail, Outlook, SendGrid, dll) dengan tombol Test Connection
- **n8n Configuration**: Base URL, API Key, dan test connection ke n8n instance
- **ClickUp Configuration**: API Token, Workspace ID, dan test connection ke ClickUp API
- **Database Configuration**: Engine (PostgreSQL/SQLite3), nama, user, password, host, port — dengan test connection
- **Redis Cache**: URL Redis, aktif/nonaktif, test connection, start Redis lokal otomatis (jika tidak berjalan), dan flush all cache
- **WhatsApp Configuration**: API Token, Phone Number ID, Business Account ID, to phone number, test connection
- **Telegram Configuration**: Bot Token, Chat ID, test connection
- **Action Network Configuration**: API Key, webhook URL, webhook secret, test connection
- **Sync**: Sinkronisasi task dari external apps (Email, Teams, ClickUp, WhatsApp, Telegram, Action Network, n8n) ke database via modal UI atau webhook

Semua kredensial (API key, token, password) disimpan di database via model konfigurasi, bukan di environment variables. Namun, untuk environment production, database password dan REDIS_URL tetap dibaca dari environment variables / settings.py pada saat startup; perubahan di admin page memerlukan restart server untuk diterapkan ke konfigurasi Django yang sedang berjalan.

## Task Sync dari External Apps

Endpoint: `POST /task-api/tasks/sync/`

Body:
```json
{
  "source": "clickup",
  "items": [
    {
      "external_id": "clickup-123",
      "title": "Fix login bug",
      "description": "Users cannot login with SSO",
      "status": "Open",
      "priority": "High",
      "assignee": "App Support"
    }
  ]
}
```

Supported sources: `email`, `teams`, `clickup`, `whatsapp`, `telegram`, `action_network`, `n8n`

Task yang sudah ada akan di-update berdasarkan `external_id`. Job ID di-generate otomatis (XLS-YYYYMM0001, XLS-YYYYMM0002, ...).

---

# 17b. CSV / Excel Import

Halaman import: `http://localhost:8000/tasks/import/`

Fitur:
- Upload CSV atau Excel (.xlsx/.xls) dengan header fleksibel (dukung bahasa Indonesia & Inggris)
- Validasi otomatis: required fields, priority/status enums, duplicate job_id, team existence
- **Editable preview**: perbaiki data sebelum konfirmasi import
- Download template CSV: `GET /tasks/import/template/`

Header yang didukung (dengan alias):
- `email_from` / from / email / requester / pic / contact
- `email_subject` / subject / title / judul
- `task_type` / type / category / kategori / tipe
- `task_detail` / detail / description / deskripsi / work order / wo
- `priority` / prio / prioritas / level
- `status` / state / status task / keadaan
- `assign_to` / assign / team / assignee / tim / owner / pemilik
- `job_id` / id / ticket / kode / crq / change / number / nomor
- `create_at` / date / tanggal / tgl / created

---

# 18. n8n Workflow — Email to Task

## Workflow JSON

File: `email-to-task-workflow.json`

Import ke n8n: **Workflows** → **Import** → pilih file

## Node-Konfigurasi

### Node 1: Microsoft Outlook Trigger
- Event: `New Email`
- Mailbox: `Shared Mailbox`

### Node 2: OpenAI Extract
- Method: `POST`
- URL: `https://api.openai.com/v1/chat/completions`
- Header: `Authorization: Bearer <OPENAI_API_KEY>`
- Body: kirim email subject + body untuk diekstrak

### Node 3: Parse AI Response
- Ekstrak `task_type`, `priority`, `task_detail`, `assign_to`, `note` dari response JSON

### Node 4: Send to Django API
- Method: `POST`
- URL: `http://localhost:8000/task-api/tasks/`
- Header: `Content-Type: application/json`
- Body: mapping field dari AI output

## Workflow Flow

```text
Outlook Trigger (New Email)
        ↓
OpenAI Extract (AI parses email → JSON)
        ↓
Parse AI Response (extract fields)
        ↓
Send to Django API (POST http://localhost:8000/task-api/tasks/)
        ↓
PostgreSQL (taskdb → tasks_task table)
```

### n8n Webhook Endpoint

n8n dapat juga mengirim data langsung ke Django via webhook:

```text
POST http://localhost:8000/webhooks/n8n/
Content-Type: application/json

{
  "source": "n8n",
  "items": [
    {
      "external_id": "ext-001",
      "title": "Task dari n8n",
      "description": "Detail task",
      "status": "Open",
      "priority": "Medium"
    }
  ]
}
```

---

# 19. Assignment Engine Rules

Aturan assignment otomatis dikelola via admin page (`/admin-page/`) dengan UI CRUD (tambah/hapus).
Rule default yang di-seed otomatis:

```text
Keyword              Team

SAP                  SAP Team
Database             DBA Team
VPN                  Network Team
Laptop               IT Support
Application          App Support
```

Rules diterapkan oleh assignment engine pada saat task dibuat atau di-sync dari external apps.

---

# 20. Reports & 7-Day Trend

Halaman: `http://localhost:8000/reports/`

Ringkasan kartu: Open, In Progress, Closed Today, Overdue, This Week (created/closed/avg resolution), This Month (created/closed/SLA compliance).

## 7-Day Trend

Tabel trend harian untuk 7 hari terakhir (dari hari ini ke 6 hari sebelumnya). Data otomatis diperbarui setiap 5 menit. Buka halaman `/reports/` untuk melihat data terkini — tanggal dan angka disesuaikan otomatis berdasarkan tanggal server.

## Calendar View

```text
         Thu      Fri      Sat      Sun      Mon      Tue      Wed
         30 Jul   31 Jul   1 Aug    2 Aug    3 Aug    4 Aug    5 Aug
       ┌────────┬────────┬────────┬────────┬────────┬────────┬────────┐
Created │  1     │  0     │  0     │  5     │  18    │  1     │  0     │
       ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
Closed  │  1     │  0     │  0     │  5     │  18    │  1     │  0     │
       ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
Net     │  —     │  —     │  —     │  —     │  —     │  —     │  —     │
       └────────┴────────┴────────┴────────┴────────┴────────┴────────┘
Open*   │  0     │  0     │  0     │  0     │  0     │  0     │  0     │
       └────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```

\* **Open (cumulative)**: Task yang masih terbuka (belum closed) hingga akhir hari itu

**Kolom:**
- **Created**: Jumlah task dibuat pada tanggal tersebut
- **Closed**: Jumlah task closed pada tanggal tersebut
- **Net**: Created − Closed (positif = bertambah, negatif = berkurang, — = nol)
- Open cumulative: Task yang masih terbuka sampai akhir hari di kolom \*

Data di atas adalah contoh ilustratif. Tanggal dan angka akan menyesuai otomatis dengan tanggal server saat halaman `/reports/` dibuka.

## Trend Charts

Di bawah tabel, tersedia 3 grafik:
- **Weekly Trend (7 days)**: Bar chart — created vs closed per hari
- **Monthly Trend (30 days)**: Bar chart — created vs closed per hari
- **Yearly Trend (12 months)**: Area chart — created vs closed per bulan

---

# 21. Scheduled Jobs

## Reminder (Setiap 4 Jam)

```sql
SELECT *
FROM tasks_task
WHERE status IN (
  'Open',
  'Assigned',
  'In Progress'
)
```

## Daily Summary (Jam 08:00 WIB)

Kirim ke Manager:

```text
Open Tasks      : <count>
In Progress     : <count>
Closed Yesterday: <count>
Overdue         : <count>
```

---

# Best Practice Production
✅ PostgreSQL sebagai database utama
✅ Redis sebagai cache dan message queue
✅ Gunakan Node.js LTS
✅ Jalankan n8n melalui PM2
✅ Backup PostgreSQL harian
✅ Aktifkan HTTPS menggunakan IIS Reverse Proxy atau Nginx
✅ Gunakan Azure OpenAI untuk enterprise
✅ Gunakan Ollama untuk data internal sensitif
✅ Aktifkan User Management dan MFA
✅ Batasi akses PostgreSQL hanya dari localhost
✅ Batasi akses Redis dengan password
✅ Monitoring menggunakan Grafana dan Prometheus
---
# Ringkasan Konfigurasi

```text
Application : n8n + Django

PostgreSQL  : localhost:5008
  - n8n DB    : n8n
  - Django DB : taskdb
  - User      : postgres
  - Password  : Password09!

Redis       : localhost:6379 (atau Redis Cloud)
  - Host      : redis-19062.c15.us-east-1-4.ec2.cloud.redislabs.com
  - Port      : 19062
  - Password  : Kp2MdJmmsJTBx6rLy5fmvmkJNKXWBrJR

n8n         : http://localhost:5678
Django API  : http://localhost:8000/task-api/
Django UI   : http://localhost:8000/dashboard/
Django Admin: http://localhost:8000/admin/

AI Options:
- OpenAI
- Azure OpenAI
- Ollama
Service	URL	Status
n8n	http://localhost:5678	Running
Django API	http://localhost:8000/task-api/	Ready
Django Dashboard	http://localhost:8000/dashboard/	Ready
PostgreSQL	localhost:5008	Running
Redis	localhost:6379

Dengan konfigurasi ini, n8n berjalan langsung di Windows tanpa Docker, menggunakan PostgreSQL pada port **5008** sebagai database utama untuk workflow dan task management, serta Redis untuk caching dan message queue. Setiap email otomatis berubah menjadi task terstruktur yang dapat dipantau, ditugaskan, dilaporkan, dan diaudit secara real-time.

---

# 22. Push ke GitHub

## Windows (Git Bash / WSL)

Jalankan `push.sh` dari Git Bash atau WSL:

```bash
cd /c/www/n8n
bash push.sh
```

## Windows (Command Prompt / PowerShell)

Jalankan `push.bat`:

```cmd
push.bat
```

### Manual Push

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/harys-rifai/TaskMgmt-synchAPPS.git
git branch -M main
git push -u origin main
```

---

# 23. Screenshots

<div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px">

<div align="center">

<img src="img/login.png" alt="Login" width="200"/>

**Login**

</div>

<div align="center">

<img src="img/dashboard.png" alt="Dashboard" width="200"/>

**Dashboard**

</div>

<div align="center">

<img src="img/task-board.png" alt="Task Board" width="200"/>

**Task Board**

</div>

<div align="center">

<img src="img/assign.png" alt="Assignment" width="200"/>

**Assignment**

</div>

<div align="center">

<img src="img/admin.png" alt="Admin" width="200"/>

**Admin**

</div>

<div align="center">

<img src="img/backup.png" alt="Backup" width="200"/>

**Backup**

</div>

</div>