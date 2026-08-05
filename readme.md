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
- **Data Analytics**: Target Name analytics di dashboard (database name, server, IP — dikelompokkan & ter-tag untuk report)
- **Django Admin**: Test connection buttons untuk semua config (Email, n8n, ClickUp, Redis, Database, WhatsApp, Telegram, Action Network)
 
![Banner](https://qrangers.com/wp-content/uploads/2021/09/Banner-Introduction-to-3D-Animation.png)

<h1 align="center">Hi ✌️, I'm Harys Rifai</h1>
<h3 align="center">Problem-solving journey | Beginner developer from Jakarta</h3>
<img align="right" alt="Coding" width="400" src="https://user-images.githubusercontent.com/74038190/212749447-bfb7e725-6987-49d9-ae85-2015e3e7cc41.gif"

<p align="left"> <img src="https://komarev.com/ghpvc/?username=harys-rifai&label=Profile%20views&color=0e75b6&style=flat" alt="harys-rifai" /> </p>

<h2>💫 About Me</h2>

<p>
  Backend Developer and <strong>Database Architect</strong> with experience in building
  scalable, secure, and high-performance systems using <strong>Python</strong> and
  <strong>Django</strong>. Skilled in database architecture, data modeling, query optimization,
  API integration, real-time systems, and automation workflows.
</p>

<p>
  Experienced with <strong>PostgreSQL, IBM Db2, MariaDB, CynosDB, Redis, Oracle Database,
  and Microsoft SQL Server</strong>, focusing on performance tuning, indexing strategies,
  data migration, and enterprise-grade data solutions.
</p>

<p>
  Passionate about solving complex technical challenges and continuously expanding expertise in
  <strong>System Design, Distributed Systems, AI-Powered Automation, Cloud Infrastructure,
  and Scalable SaaS Architecture</strong>.
</p>


## 🌐 Socials:  [![LinkedIn](https://img.shields.io/badge/LinkedIn-%230077B5.svg?logo=linkedin&logoColor=white)](https://linkedin.com/in/haris-rifai) [![email](https://img.shields.io/badge/Email-D14836?logo=gmail&logoColor=white)](mailto:harysrifai@gmail.com) 

# 💻 Tech Stack:
![C](https://img.shields.io/badge/c-%2300599C.svg?style=for-the-badge&logo=c&logoColor=white) ![C++](https://img.shields.io/badge/c++-%2300599C.svg?style=for-the-badge&logo=c%2B%2B&logoColor=white) ![JavaScript](https://img.shields.io/badge/javascript-%23323330.svg?style=for-the-badge&logo=javascript&logoColor=%23F7DF1E) ![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white) ![HTML5](https://img.shields.io/badge/html5-%23E34F26.svg?style=for-the-badge&logo=html5&logoColor=white) ![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54) ![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white) ![Netlify](https://img.shields.io/badge/netlify-%23000000.svg?style=for-the-badge&logo=netlify&logoColor=#00C7B7) ![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white) ![DigitalOcean](https://img.shields.io/badge/DigitalOcean-%230167ff.svg?style=for-the-badge&logo=digitalOcean&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase) ![Vercel](https://img.shields.io/badge/vercel-%23000000.svg?style=for-the-badge&logo=vercel&logoColor=white) ![Render](https://img.shields.io/badge/Render-%46E3B7.svg?style=for-the-badge&logo=render&logoColor=white) ![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white) ![Django](https://img.shields.io/badge/django-%23092E20.svg?style=for-the-badge&logo=django&logoColor=white) ![DjangoREST](https://img.shields.io/badge/DJANGO-REST-ff1709?style=for-the-badge&logo=django&logoColor=white&color=ff1709&labelColor=gray) ![Socket.io](https://img.shields.io/badge/Socket.io-black?style=for-the-badge&logo=socket.io&badgeColor=010101) ![RabbitMQ](https://img.shields.io/badge/rabbitmq-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white) ![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white) ![Gunicorn](https://img.shields.io/badge/gunicorn-%298729.svg?style=for-the-badge&logo=gunicorn&logoColor=white) ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white) ![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white) ![MongoDB](https://img.shields.io/badge/MongoDB-%234ea94b.svg?style=for-the-badge&logo=mongodb&logoColor=white) ![MySQL](https://img.shields.io/badge/mysql-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white) ![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-a08021?style=for-the-badge&logo=firebase&logoColor=ffcd34) ![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white) ![Pandas](https://img.shields.io/badge/pandas-%23150458.svg?style=for-the-badge&logo=pandas&logoColor=white) ![NumPy](https://img.shields.io/badge/numpy-%23013243.svg?style=for-the-badge&logo=numpy&logoColor=white) ![GitLab CI](https://img.shields.io/badge/gitlab%20CI-%23181717.svg?style=for-the-badge&logo=gitlab&logoColor=white) ![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white) ![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white) ![GitLab](https://img.shields.io/badge/gitlab-%23181717.svg?style=for-the-badge&logo=gitlab&logoColor=white) ![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white) ![Swagger](https://img.shields.io/badge/-Swagger-%23Clojure?style=for-the-badge&logo=swagger&logoColor=white) ![Postman](https://img.shields.io/badge/Postman-FF6C37?style=for-the-badge&logo=postman&logoColor=white) ![Notion](https://img.shields.io/badge/Notion-%23000000.svg?style=for-the-badge&logo=notion&logoColor=white) ![Trello](https://img.shields.io/badge/Trello-%23026AA7.svg?style=for-the-badge&logo=Trello&logoColor=white) ![Twilio](https://img.shields.io/badge/Twilio-F22F46?style=for-the-badge&logo=Twilio&logoColor=white)
# 📊 GitHub Stats:
![](https://github-readme-stats.shion.dev/api?username=harys-rifai&theme=dark&hide_border=true&include_all_commits=true&count_private=true)<br/>
![](https://streak-stats.demolab.com/?user=harys-rifai&theme=dark&hide_border=true)<br/>
![](https://github-readme-stats.shion.dev/api/top-langs/?username=harys-rifai&theme=dark&hide_border=true&include_all_commits=true&count_private=true&layout=compact)

## 🏆 GitHub Trophies
![](https://github-profile-trophy.vercel.app/?username=harys-rifai&theme=merko&no-frame=true&no-bg=true&margin-w=4)
 

https://github.com/harys-rifai

<!-- Proudly created with GPRM ( https://gprm.itsvg.in ) -->

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