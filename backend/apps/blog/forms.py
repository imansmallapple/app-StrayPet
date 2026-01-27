from django import forms
from .models import Article
from .widgets import MarkdownTextarea


class ArticleAdminForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = '__all__'
        widgets = {
            'content': MarkdownTextarea()
        }
