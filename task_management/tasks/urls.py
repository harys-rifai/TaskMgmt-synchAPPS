from django.urls import path, include
from rest_framework.routers import DefaultRouter
from django.contrib.auth.views import LoginView, LogoutView
from . import views

router = DefaultRouter()
router.register(r'tasks', views.TaskViewSet, basename='task')
router.register(r'teams', views.TeamViewSet, basename='team')

urlpatterns = [
    path('', include(router.urls)),
    path('login/', LoginView.as_view(template_name='tasks/login.html'), name='login'),
    path('logout/', LogoutView.as_view(next_page='login'), name='logout'),
]