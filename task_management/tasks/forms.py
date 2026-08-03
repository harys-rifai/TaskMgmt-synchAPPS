from django import forms
from django.forms import widgets
from .models import DatabaseConfig


class PasswordShowHideWidget(widgets.PasswordInput):
    template_name = 'tasks/widgets/password_show_hide.html'

    def __init__(self, attrs=None, *args, **kwargs):
        default_attrs = {'class': 'form-control form-control-sm', 'placeholder': 'Password'}
        if attrs:
            default_attrs.update(attrs)
        super().__init__(attrs=default_attrs, *args, **kwargs)

    def get_context(self, name, value, attrs):
        context = super().get_context(name, value, attrs)
        context['widget']['has_value'] = bool(value)
        return context


class DatabaseConfigForm(forms.ModelForm):
    class Meta:
        model = DatabaseConfig
        fields = ['engine', 'name', 'user', 'password', 'host', 'port', 'is_active']
        widgets = {
            'engine': forms.Select(attrs={'class': 'form-select form-select-sm'}),
            'name': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'taskdb'}),
            'user': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'postgres'}),
            'password': PasswordShowHideWidget(attrs={'placeholder': 'Password'}),
            'host': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': 'localhost'}),
            'port': forms.TextInput(attrs={'class': 'form-control form-control-sm', 'placeholder': '5008'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
