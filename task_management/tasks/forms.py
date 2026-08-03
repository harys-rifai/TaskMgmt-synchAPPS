from django import forms
from .models import DatabaseConfig


class DatabaseConfigForm(forms.ModelForm):
    class Meta:
        model = DatabaseConfig
        fields = ['engine', 'name', 'user', 'password', 'host', 'port', 'is_active']
        widgets = {
            'engine': forms.Select(attrs={'class': 'form-select form-select-sm'}),
            'name': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'taskdb'}),
            'user': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'postgres'}),
            'password': forms.PasswordInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'Password'}),
            'host': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'localhost'}),
            'port': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': '5008'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
