# Desain Sistem Task Management Email Automation
## n8n + Django + PostgreSQL + Outlook + Microsoft Teams + AI

---

# 1. Tujuan Sistem

Membangun aplikasi internal yang mampu:

- Membaca email masuk dari Outlook Shared Mailbox
- Mengekstrak pekerjaan menggunakan AI
- Menyimpan task ke PostgreSQL
- Menampilkan dashboard monitoring task
- Melakukan assignment pekerjaan
- Mengelola status pekerjaan
- Mengirim notifikasi ke Microsoft Teams
- Menyediakan reporting dan KPI untuk Manager

# 2. Arsitektur Sistem

```text
┌─────────────────────┐
│ Microsoft Outlook   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│       n8n           │
│                     │
│ Email Trigger       │
│ AI Extraction       │
│ Assignment Rules    │
└──────────┬──────────┘
           │ REST API
           ▼
┌─────────────────────┐
│      Django API     │
│                     │
│ Task Service        │
│ User Service        │
│ Assignment Service  │
│ Reporting Service   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│    PostgreSQL       │
│     Port 5008       │
└──────────┬──────────┘
           │
           ├─────────────► Dashboard
           │
           └─────────────► Reports
                         └─► Teams Notification
```

---

# 3. Technology Stack

## Backend

```text
Python 3.12
Django 5.x
Django REST Framework
```

## Database

```text
PostgreSQL
Port : 5008
```

## Workflow

```text
n8n
```

## AI

```text
Azure OpenAI
OpenAI
Ollama
```

## Frontend

```text
Django Template
Bootstrap 5
HTMX (Optional)
```

## Authentication

```text
Django Authentication
Microsoft Entra ID (Optional)
```

---

# 4. PostgreSQL Configuration

```text
Host      : localhost
Port      : 5008

Database  : taskdb

User      : postgres
Password  : Password09!
```

---

# 5. Install Django

## Create Virtual Environment

```bash
python -m venv venv
```

Activate:

```bash
venv\Scripts\activate
```

---

## Install Packages

```bash
pip install django
pip install djangorestframework
pip install psycopg2-binary
pip install django-filter
pip install drf-yasg
```

---

## Create Project

```bash
django-admin startproject task_management
```

```bash
cd task_management
```

Create app:

```bash
python manage.py startapp tasks
```

---

# 6. Database Settings

Edit:

```python
settings.py
```

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'taskdb',
        'USER': 'postgres',
        'PASSWORD': 'Password09!',
        'HOST': 'localhost',
        'PORT': '5008',
    }
}
```

---

# 7. Database Schema

## Team

```python
class Team(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(blank=True)
    is_active = models.BooleanField(default=True)
```

---

## Task

```python
class Task(models.Model):

    job_id = models.CharField(
        max_length=50,
        unique=True
    )

    email_from = models.EmailField()

    email_subject = models.TextField()

    task_type = models.CharField(
        max_length=100
    )

    task_detail = models.TextField()

    assign_to = models.ForeignKey(
        Team,
        on_delete=models.SET_NULL,
        null=True
    )

    priority = models.CharField(
        max_length=20
    )

    note = models.TextField(
        blank=True,
        null=True
    )

    status = models.CharField(
        max_length=30,
        default='Open'
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    closed_at = models.DateTimeField(
        null=True,
        blank=True
    )
```

---

# 8. User Role

## Administrator

```text
Manage semua task
Manage user
Manage team
Dashboard KPI
```

---

## Manager

```text
View semua task
Assign task
Close task
Generate report
```

---

## Team Member

```text
View assigned task
Update status
Add note
```

---

## Requestor

```text
View own task only
```

---

# 9. Status Workflow

```text
Open
Assigned
In Progress
Pending User
Pending Vendor
Completed
Closed
Rejected
Cancelled
```

---

# 10. REST API

## Create Task

```http
POST /api/tasks/
```

Request:

```json
{
  "job_id":"JOB-20260802-0001",
  "email_from":"user@company.com",
  "email_subject":"SAP Access",
  "task_type":"Access Request",
  "task_detail":"Create SAP Access",
  "priority":"Medium",
  "status":"Open"
}
```

---

## Task List

```http
GET /api/tasks/
```

---

## Task Detail

```http
GET /api/tasks/{id}
```

---

## Update Status

```http
PATCH /api/tasks/{id}
```

---

# 11. n8n Integration

## Workflow

```text
Outlook Trigger

  ↓

Get Email

  ↓

OpenAI

  ↓

Convert to JSON Task

  ↓

HTTP Request

  ↓

Django API

  ↓

PostgreSQL
```

---

# 12. Outlook Email Trigger

Node:

```text
Microsoft Outlook Trigger
```

Event:

```text
New Email
```

Mailbox:

```text
Shared Mailbox
```

---

# 13. AI Prompt

```text
Analyze this email.

Return JSON only.

{
 "task_type":"",
 "priority":"",
 "task_detail":"",
 "assign_to":"",
 "note":""
}
```

---

## Example Output

```json
{
 "task_type":"Database Support",
 "priority":"High",
 "task_detail":"Create database for reporting application",
 "assign_to":"DBA Team",
 "note":"Finance Department"
}
```

---

# 14. Send Data to Django

n8n HTTP Request Node

Method:

```http
POST
```

URL:

```text
http://localhost:8000/task-api/tasks/
```

Headers:

```json
{
  "Content-Type": "application/json"
}
```

Body:

```json
{
  "job_id":"JOB-20260802-0001",
  "email_from":"{{email_from}}",
  "email_subject":"{{email_subject}}",
  "task_type":"{{task_type}}",
  "task_detail":"{{task_detail}}",
  "priority":"{{priority}}",
  "status":"Open"
}
```

---

## Import Workflow JSON

Workflow file:

```text
C:\www\n8n\email-to-task-workflow.json
```

Steps:

1. Open n8n at `http://localhost:5678`
2. Click **Workflows** → **Import**
3. Select `email-to-task-workflow.json`
4. Configure credentials:
   - **Outlook Trigger**: Microsoft Outlook OAuth2 (Shared Mailbox)
   - **OpenAI Extract**: HTTP Header Auth with `Authorization: Bearer <OPENAI_API_KEY>`
5. Activate the workflow

---

# 15. Assignment Engine

## Rules

```text
Keyword              Team

SAP                  SAP Team
Database             DBA Team
VPN                  Network Team
Laptop               IT Support
Application          App Support
```

---

## Django Auto Mapping

```text
Task Created

↓

Keyword Detection

↓

Assign Team

↓

Update Record
```

---

# 16. Dashboard

## Main Metrics

```text
Open Tasks
Assigned Tasks
In Progress Tasks
Closed Tasks
High Priority Tasks
Overdue Tasks
```

---

## Dashboard Widgets

```text
Task by Team

Task by Status

Task by Priority

Task Trend

SLA Compliance
```

---

# 17. Dashboard Pages

## Dashboard

```text
Executive Summary
```

---

## Task Management

```text
Task List
Task Detail
Task Update
```

---

## Assignment

```text
Task Allocation
Team Capacity
```

---

## Reports

```text
Daily Report
Weekly Report
Monthly Report
```

---

## Admin

```text
User Management
Team Management
Assignment Rules
```

---

# 18. Teams Notification

Saat task dibuat:

```text
New Task Created

Job ID: JOB-20260802-0001

Priority : High

Assign To : DBA Team

Task:
Create database for reporting application
```

---

# 19. Scheduled Jobs

## Reminder

Setiap 4 Jam

```sql
SELECT *
FROM tasks_task
WHERE status IN (
'Open',
'Assigned',
'In Progress'
)
```

---

## Daily Summary

Jam:

```text
08:00 WIB
```

Kirim ke Manager:

```text
Open Tasks      : 25
In Progress     : 14
Closed Yesterday: 10
Overdue         : 2
```

---

# 20. Future Enhancement

## Phase 2

```text
Azure Entra ID SSO
```

---

## Phase 3

```text
Chatbot Teams
```

User bertanya:

```text
Show my open tasks
```

Bot mengambil data dari Django.

---

## Phase 4

```text
AI Assignment
AI Priority Detection
AI SLA Prediction
AI Summary
```

---

# Hasil Akhir

Sistem ini akan menghasilkan platform internal mirip mini-Jira/ServiceNow dengan workflow:

```text
Outlook Email
      │
      ▼
n8n Workflow
      │
      ▼
AI Analysis
      │
      ▼
Django REST API
      │
      ▼
PostgreSQL
      │
      ▼
Dashboard
      │
      ▼
Microsoft Teams Notification
```

Dengan desain ini, setiap email otomatis berubah menjadi task terstruktur yang dapat dipantau, ditugaskan, dilaporkan, dan diaudit secara real-time.

---

# Implementasi Backend Django

## Status

```text
Django Project  : task_management
Django App      : tasks
Database        : PostgreSQL (taskdb)
Port Database   : 5008
API Base URL    : http://localhost:8000/task-api/
Admin URL       : http://localhost:8000/admin/
```

---

## Struktur Proyek

```text
C:\www\n8n\task_management\
├── task_management\
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── tasks\
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── migrations\
│       ├── __init__.py
│       └── 0001_initial.py
├── manage.py
└── requirements.txt
```

---

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
  "job_id": "JOB-20260802-0001",
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
  "job_id": "JOB-20260802-0001",
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

## Dashboard Frontend

### Technology

```text
Django Templates
Bootstrap 5
HTMX (for dynamic updates without full page reload)
```

### Pages

| Page | URL | Description |
|------|-----|-------------|
| Dashboard | `/dashboard/` | Executive summary with metrics and charts |
| Task List | `/tasks/` | Full task list with search and filters |
| Task Detail | `/tasks/{id}/` | Task details with status update and note |
| Assignment | `/assignment/` | Task allocation and team management |
| Reports | `/reports/` | Daily, weekly, and monthly reports |
| Admin | `/admin-page/` | User, team, and assignment rules management |

### Dashboard Features

- Real-time metrics (Open, Assigned, In Progress, Closed, High Priority, Overdue)
- Task breakdown by status, priority, and team (loaded via HTMX)
- Recent tasks table with quick links
- Status update form (HTMX POST without page reload)
- Note adding (HTMX POST without page reload)

### Key Template Files

```text
tasks/templates/tasks/
├── base.html          # Base layout with Bootstrap 5 + HTMX
├── dashboard.html     # Executive summary dashboard
├── task_list.html     # Task list with search/filter
├── task_detail.html   # Task detail with status/note forms
├── assignment.html    # Task allocation and team view
├── reports.html       # Reporting dashboard
└── admin_page.html    # Admin management page
```

---

# Email → n8n Router → Teams + Telegram Configuration

## Overview

This configuration connects Outlook email to n8n, routes incoming emails based on keywords, and sends notifications to both Microsoft Teams and Telegram.

## Architecture

```text
Outlook Email (Shared Mailbox)
        │
        ▼
n8n Outlook Trigger
        │
        ▼
Router (Code Node - Keyword Detection)
        │
        ├── High Priority ──► Teams + Telegram + Django API
        ├── SAP Team ────────► Teams + Telegram + Django API
        ├── DBA Team ────────► Teams + Telegram + Django API
        ├── Network Team ────► Teams + Telegram + Django API
        ├── IT Support ──────► Teams + Telegram + Django API
        ├── App Support ─────► Teams + Telegram + Django API
        └── General ─────────► Teams + Telegram + Django API
```

## Assignment Rules (Router)

```text
Keyword              Route          Priority

urgent/critical      high           High
SAP                  sap            High
Database/DBA         database       Medium
VPN                  network        Medium
Laptop/hardware      it             Medium
Application/App      app            Low
(default)            general        Low
```

## n8n Workflow Nodes

### Node 1: Outlook Trigger

```text
Type: Microsoft Outlook Trigger
Event: New Email
Mailbox: Shared Mailbox
```

### Node 2: Router (Code Node)

A JavaScript code node that analyzes the email subject and body for keywords and assigns a route and priority.

```javascript
const email = $input.first().json;
const subject = email.subject || '';
const body = email.body || '';
const from = email.from || '';

let priority = 'Low';
let route = 'general';

const subjectLower = subject.toLowerCase();
const bodyLower = body.toLowerCase();

if (subjectLower.includes('urgent') || subjectLower.includes('critical') || bodyLower.includes('urgent') || bodyLower.includes('critical')) {
  priority = 'High';
  route = 'high';
} else if (subjectLower.includes('sap') || bodyLower.includes('sap')) {
  priority = 'High';
  route = 'sap';
} else if (subjectLower.includes('database') || bodyLower.includes('database') || subjectLower.includes('dba') || bodyLower.includes('dba')) {
  priority = 'Medium';
  route = 'database';
} else if (subjectLower.includes('vpn') || bodyLower.includes('vpn')) {
  priority = 'Medium';
  route = 'network';
} else if (subjectLower.includes('laptop') || bodyLower.includes('laptop') || subjectLower.includes('hardware') || bodyLower.includes('hardware')) {
  priority = 'Medium';
  route = 'it';
} else if (subjectLower.includes('application') || bodyLower.includes('application') || subjectLower.includes('app') || bodyLower.includes('app')) {
  priority = 'Low';
  route = 'app';
}

return [{
  json: {
    ...email,
    priority,
    route,
    subject,
    body,
    from,
    task_type: route,
  }
}];
```

### Node 3-9: Switch Nodes

Each route has a Switch node that filters emails by route value:

| Node | Route Value |
|------|-------------|
| High Priority | `high` |
| SAP Team | `sap` |
| DBA Team | `database` |
| Network Team | `network` |
| IT Support | `it` |
| App Support | `app` |
| General | `general` |

### Node 10: Teams Notification

```text
Type: HTTP Request
Method: POST
URL: https://graph.microsoft.com/v1.0/teams/{team_id}/channels/{channel_id}/messages
Auth: OAuth2 (Microsoft Graph)
Body: HTML message with task details
```

Teams message format:

```html
<h3>New Task Created</h3>
<p><b>Job ID:</b> {{ job_id }}</p>
<p><b>Priority:</b> {{ priority }}</p>
<p><b>Assign To:</b> {{ assign_to }}</p>
<p><b>Subject:</b> {{ subject }}</p>
<p><b>Detail:</b> {{ task_detail }}</p>
```

### Node 11: Telegram Notification

```text
Type: HTTP Request
Method: POST
URL: https://api.telegram.org/bot{token}/sendMessage
Auth: HTTP Header Auth
Body: JSON with chat_id and message text
```

Telegram message format:

```
New Task Created

Job ID: {{ job_id }}
Priority: {{ priority }}
Assign To: {{ assign_to }}
Subject: {{ subject }}
Detail: {{ task_detail }}
```

### Node 12: Format Task Data

A code node that generates the job_id and formats the task data for Django API.

### Node 13: Send to Django API

```text
Type: HTTP Request
Method: POST
URL: http://localhost:8000/task-api/tasks/
Body: JSON task data
```

## Credential Setup

### Microsoft Outlook OAuth2

1. Go to n8n → Settings → Credentials
2. Create new credential: `Microsoft Outlook OAuth2 API`
3. Configure:
   - Client ID: from Azure AD App Registration
   - Client Secret: from Azure AD App Registration
   - Tenant ID: your Azure AD tenant
   - Scope: `Mail.Read`
4. Share the Shared Mailbox with the Azure AD app

### Microsoft Teams OAuth2

1. Use the same Azure AD app
2. Add scope: `ChannelMessage.Send`

### Telegram Bot

1. Create a bot via @BotFather on Telegram
2. Get the bot token
3. Get the chat ID (use @userinfobot or get it from the chat)
4. In n8n, use HTTP Header Auth with the bot token

## Import Workflow

File: `email-router-teams-telegram-workflow.json`

Steps:
1. Open n8n at `http://localhost:5678`
2. Click **Workflows** → **Import**
3. Select `email-router-teams-telegram-workflow.json`
4. Configure credentials for each node
5. Activate the workflow

---

## Complete System Flow

```text
Outlook Email (Shared Mailbox)
        │
        ▼
n8n Outlook Trigger
        │
        ▼
Router (Keyword Detection → Route + Priority)
        │
        ├──► Teams Notification
        ├──► Telegram Notification
        │
        ▼
Django API (POST /task-api/tasks/)
        │
        ▼
PostgreSQL (taskdb → tasks_task)
        │
        ▼
Dashboard (http://localhost:8000/dashboard/)
```

---

# Ringkasan Konfigurasi Lengkap

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

Email       : Outlook Shared Mailbox
Teams       : Microsoft Teams (via Graph API)
Telegram    : Telegram Bot API
Router      : n8n Code + Switch nodes
AI          : OpenAI / Azure OpenAI / Ollama
```

---

# Authentication (Login / Logout)

## Overview

The Django dashboard at `http://localhost:8000/dashboard/` requires authentication. Unauthenticated users are redirected to the login page.

## Login

- URL: `http://localhost:8000/login/`
- Default superuser: `admin` / `admin123`
- After login, user is redirected to `/dashboard/`

## Logout

- URL: `http://localhost:8000/logout/`
- After logout, user is redirected to `/login/`

## Protected Pages

All dashboard pages require authentication:

| Page | URL | Auth Required |
|------|-----|---------------|
| Dashboard | `/dashboard/` | Yes |
| Task List | `/tasks/` | Yes |
| Task Detail | `/tasks/{id}/` | Yes |
| Task Edit | `/tasks/{id}/edit/` | Yes |
| Assignment | `/assignment/` | Yes |
| Reports | `/reports/` | Yes |
| Admin | `/admin-page/` | Yes |

## Creating Additional Users

```bash
cd C:\www\n8n\task_management
python manage.py createsuperuser
```

Or via Django shell:

```python
from django.contrib.auth.models import User
User.objects.create_user('manager', 'manager@company.com', 'password123')
```

## Login Required Decorator

All template views use `@login_required`:

```python
from django.contrib.auth.decorators import login_required

@login_required
def dashboard_page(request):
    ...
```

## Session Storage

Sessions are stored in Redis for performance:

```python
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
```