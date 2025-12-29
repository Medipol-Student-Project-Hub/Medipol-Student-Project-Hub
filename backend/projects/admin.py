from django.contrib import admin
from .models import Project, Milestone, JoinRequest, Feedback, Task, Meeting


class MilestoneInline(admin.TabularInline):
    model = Milestone
    extra = 1
    fields = ['description', 'due_date', 'is_completed']


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'category', 'status', 'posted_date', 'get_team_size']
    list_filter = ['category', 'status', 'posted_date']
    search_fields = ['title', 'description', 'owner__user__name']
    ordering = ['-posted_date']
    inlines = [MilestoneInline]

    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'description', 'category', 'status')
        }),
        ('Team & Supervision', {
            'fields': ('owner', 'supervisor', 'max_team_size')
        }),
        ('Details', {
            'fields': ('required_skills', 'start_date', 'expected_duration', 'tags', 'objectives', 'requirements')
        }),
    )

    def get_team_size(self, obj):
        return f"{obj.get_current_team_size()}/{obj.max_team_size}"
    get_team_size.short_description = 'Team Size'

    def save_model(self, request, obj, form, change):
        """Auto-assign owner when creating project from admin panel"""
        if not change:  # Only on creation (not update)
            if not obj.pk and obj.owner_id is None:
                # If owner is not set, assign the current user (if they are a student)
                if hasattr(request.user, 'student_profile'):
                    obj.owner = request.user.student_profile
                elif not obj.owner:
                    # If admin is not a student and no owner is selected, raise error
                    from django.core.exceptions import ValidationError
                    raise ValidationError('Owner must be specified when creating a project.')
        super().save_model(request, obj, form, change)


@admin.register(Milestone)
class MilestoneAdmin(admin.ModelAdmin):
    list_display = ['project', 'description', 'due_date', 'is_completed', 'completed_date']
    list_filter = ['is_completed', 'due_date']
    search_fields = ['project__title', 'description']
    ordering = ['due_date']


@admin.register(JoinRequest)
class JoinRequestAdmin(admin.ModelAdmin):
    list_display = ['student', 'project', 'status', 'request_date', 'response_date']
    list_filter = ['status', 'request_date']
    search_fields = ['student__user__name', 'project__title']
    ordering = ['-request_date']


@admin.register(Feedback)
class FeedbackAdmin(admin.ModelAdmin):
    list_display = ['project', 'faculty', 'created_at']
    list_filter = ['created_at']
    search_fields = ['project__title', 'faculty__user__name', 'comments']
    ordering = ['-created_at']


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'project', 'status', 'priority', 'assignee', 'due_date', 'created_at']
    list_filter = ['status', 'priority', 'due_date', 'created_at']
    search_fields = ['title', 'description', 'project__title', 'assignee__user__name']
    ordering = ['-created_at']
    fieldsets = (
        ('Task Information', {
            'fields': ('project', 'title', 'description')
        }),
        ('Assignment', {
            'fields': ('assignee', 'status', 'priority', 'due_date')
        }),
    )


@admin.register(Meeting)
class MeetingAdmin(admin.ModelAdmin):
    list_display = ['title', 'project', 'date_time', 'location', 'created_at']
    list_filter = ['date_time', 'created_at']
    search_fields = ['title', 'description', 'project__title', 'location']
    ordering = ['date_time']
    filter_horizontal = ['participants']
    fieldsets = (
        ('Meeting Information', {
            'fields': ('project', 'title', 'description')
        }),
        ('Schedule', {
            'fields': ('date_time', 'location', 'meeting_link')
        }),
        ('Participants', {
            'fields': ('participants',)
        }),
    )
