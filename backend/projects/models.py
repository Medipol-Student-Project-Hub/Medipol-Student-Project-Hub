from django.db import models
from django.utils import timezone
from django.core.exceptions import ValidationError
from users.models import Student, Faculty


class Project(models.Model):
    STATUS_CHOICES = (
        ('draft', 'Draft'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    )

    CATEGORY_CHOICES = (
        ('engineering', 'Engineering'),
        ('design', 'Design'),
        ('health', 'Health Sciences'),
        ('business', 'Business'),
        ('ai', 'Artificial Intelligence'),
        ('web', 'Web Development'),
        ('mobile', 'Mobile Development'),
        ('research', 'Research'),
        ('other', 'Other'),
    )

    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='other')
    posted_date = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')

    owner = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='owned_projects')
    supervisor = models.ForeignKey(
        Faculty, on_delete=models.SET_NULL, null=True, blank=True, related_name='supervised_projects'
    )

    required_skills = models.JSONField(default=list, blank=True)
    max_team_size = models.PositiveIntegerField(default=5)
    start_date = models.DateField(null=True, blank=True)
    expected_duration = models.CharField(max_length=50, blank=True)
    tags = models.JSONField(default=list, blank=True)
    objectives = models.JSONField(default=list, blank=True)  # Project objectives
    requirements = models.JSONField(default=list, blank=True)  # Project requirements

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Project'
        verbose_name_plural = 'Projects'
        ordering = ['-posted_date']
        indexes = [
            models.Index(fields=['status', '-posted_date']),
            models.Index(fields=['category']),
        ]

    def __str__(self):
        return self.title

    def update_details(self, title, description):
        self.title = title
        self.description = description
        self.save()

    def add_milestone(self, description, due_date):
        milestone = Milestone.objects.create(
            project=self,
            description=description,
            due_date=due_date
        )
        return milestone

    def close_project(self):
        self.status = 'completed'
        self.save()

    def get_team(self):
        return getattr(self, 'team', None)

    def get_current_team_size(self):
        team = self.get_team()
        if team:
            return team.members.count()
        return 0

    def can_accept_members(self):
        return self.get_current_team_size() < self.max_team_size


class Milestone(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='milestones')
    description = models.TextField()
    due_date = models.DateField()
    is_completed = models.BooleanField(default=False)
    completed_date = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Milestone'
        verbose_name_plural = 'Milestones'
        ordering = ['due_date']

    def __str__(self):
        status = "✓" if self.is_completed else "○"
        return f"{status} {self.project.title} - {self.description[:50]}"

    def mark_complete(self):
        self.is_completed = True
        self.completed_date = timezone.now()
        self.save()

    def clean(self):
        super().clean()
        if not self.pk and self.due_date < timezone.now().date():
            raise ValidationError('Milestone due date must be in the future.')


class JoinRequest(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='join_requests')
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='join_requests')
    request_date = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    message = models.TextField(blank=True)
    response_message = models.TextField(blank=True)
    response_date = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'Join Request'
        verbose_name_plural = 'Join Requests'
        ordering = ['-request_date']
        unique_together = ['project', 'student']
        indexes = [
            models.Index(fields=['status', '-request_date']),
        ]

    def __str__(self):
        return f"{self.student.user.name} -> {self.project.title} ({self.status})"

    def approve(self):
        from teams.models import Team
        from users.models import Notification

        if self.status != 'pending':
            raise ValidationError('Only pending requests can be approved.')

        team = self.project.get_team()
        if not team:
            team = Team.objects.create(
                project=self.project,
                max_members=self.project.max_team_size
            )

        if not self.project.can_accept_members():
            raise ValidationError('Team is already full.')

        success = team.add_member(self.student)
        if success:
            self.status = 'approved'
            self.response_date = timezone.now()
            self.save()

            # ✅ Create notification for student
            Notification.objects.create(
                recipient=self.student.user,
                notification_type='join_request',
                title='Join Request Approved! 🎉',
                message=f'Your request to join "{self.project.title}" has been approved! Welcome to the team.',
                link=f'/projects/{self.project.id}'
            )

            return True
        return False

    def reject(self):
        from users.models import Notification

        if self.status != 'pending':
            raise ValidationError('Only pending requests can be rejected.')

        self.status = 'rejected'
        self.response_date = timezone.now()
        self.save()

        # ✅ Create notification for student
        Notification.objects.create(
            recipient=self.student.user,
            notification_type='join_request',
            title='Join Request Update',
            message=f'Your request to join "{self.project.title}" was not accepted this time. Keep exploring other projects!',
            link=f'/projects/{self.project.id}'
        )

    def clean(self):
        super().clean()

        if self.student == self.project.owner:
            raise ValidationError('You cannot send a join request to your own project.')

        if not self.pk:
            existing = JoinRequest.objects.filter(
                project=self.project,
                student=self.student
            ).exclude(status='rejected').exists()
            if existing:
                raise ValidationError('You have already sent a request to this project.')


class Feedback(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='feedbacks')
    faculty = models.ForeignKey(Faculty, on_delete=models.CASCADE, related_name='given_feedbacks')
    comments = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Feedback'
        verbose_name_plural = 'Feedbacks'
        ordering = ['-created_at']

    def __str__(self):
        return f"Feedback on {self.project.title} by {self.faculty.user.name}"


class Task(models.Model):
    """
    Represents a task within a project
    """
    STATUS_CHOICES = (
        ('todo', 'To Do'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('blocked', 'Blocked'),
    )

    PRIORITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    )

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='tasks')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='todo')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    assignee = models.ForeignKey(
        Student,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_tasks'
    )
    due_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Task'
        verbose_name_plural = 'Tasks'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['project', 'status']),
            models.Index(fields=['assignee', 'status']),
        ]

    def __str__(self):
        return f"{self.project.title} - {self.title}"

    def mark_complete(self):
        self.status = 'completed'
        self.save()


class Meeting(models.Model):
    """
    Represents a meeting for a project
    """
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='meetings')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    date_time = models.DateTimeField()
    location = models.CharField(max_length=255, blank=True)
    meeting_link = models.URLField(blank=True)  # For online meetings
    participants = models.ManyToManyField(Student, related_name='meetings', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Meeting'
        verbose_name_plural = 'Meetings'
        ordering = ['date_time']
        indexes = [
            models.Index(fields=['project', 'date_time']),
        ]

    def __str__(self):
        return f"{self.project.title} - {self.title} on {self.date_time.strftime('%Y-%m-%d %H:%M')}"
