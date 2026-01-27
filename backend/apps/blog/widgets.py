from django.forms import widgets
from django.forms.renderers import get_default_renderer
from django.utils.safestring import mark_safe


class MarkdownTextarea(widgets.Textarea):
    def render(self, name, value, attrs=None, renderer=None):
        context = self.get_context(name, value, attrs)
        default_render = super().render(name, value, attrs, renderer)
        return default_render + self.viewer_markdown(context)

    def viewer_markdown(self, context):
        renderer = get_default_renderer()
        return mark_safe(renderer.render('markdown.html', context))

    class Media:
        css = {
            'all': (
                'toastui/toastui-editor.min.css',
            )
        }
        js = (
            'toastui/toastui-editor-all.min.js',
            'toastui/i18n/en-us.ts'
        )
