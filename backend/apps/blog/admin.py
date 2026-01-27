from django.contrib import admin

# Register your models here.
from apps.blog.models import Category, Article, Tag
from .forms import ArticleAdminForm


# admin.site.register([Category, Article, Tag])

class CategoryTable(admin.TabularInline):
    model = Category
    extra = 1  # 多级分类


class ArticleTable(admin.TabularInline):
    model = Article
    extra = 1


class TagTable(admin.TabularInline):
    model = Article
    extra = 1


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'parent', 'sort', 'add_date', 'pub_date')
    list_editable = ('sort',)
    search_fields = ('name',)
    search_help_text = "Search by category name"
    list_filter = ('name',)


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    form = ArticleAdminForm
    list_display = ('title', 'category', 'add_date', 'pub_date')
    search_fields = ('title',)
    list_editable = ('category',)
    search_help_text = "Search by article title"
    list_filter = ('category',)


@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ('name', 'add_date', 'pub_date')
    search_fields = ('name',)
    search_help_text = "Search by tag name"
    list_filter = ('name',)

# admin.site.register(Category, CategoryAdmin)
