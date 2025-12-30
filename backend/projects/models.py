from django.db import models
from django.utils import timezone
from django.core.exceptions import ValidationError
from users.models import Student, Faculty


class Project(models.Model):
    """
    Main project model representing student projects in the hub.

    A project can have multiple team members, milestones, and be supervised by faculty.
    Students can send join requests to projects they're interested in.
    """
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

    # Basic project information
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='other')
    posted_date = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')

    # Project ownership and supervision
    owner = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='owned_projects')
    supervisor = models.ForeignKey(
        Faculty, on_delete=models.SET_NULL, null=True, blank=True, related_name='supervised_projects'
    )

    # Project requirements and team configuration
    required_skills = models.JSONField(default=list, blank=True)
    max_team_size = models.PositiveIntegerField(default=5)
    start_date = models.DateField(null=True, blank=True)
    expected_duration = models.CharField(max_length=50, blank=True)
    tags = models.JSONField(default=list, blank=True)
    objectives = models.JSONField(default=list, blank=True)
    requirements = models.JSONField(default=list, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Project'
        verbose_name_plural = 'Projects'
        ordering = ['-posted_date']  # Show newest projects first
        indexes = [
            # Index for filtering by status and sorting by date
            models.Index(fields=['status', '-posted_date']),
            # Index for category filtering
            models.Index(fields=['category']),
        ]

    def __str__(self):
        return self.title

    def update_details(self, title, description):
        """Update project title and description."""
        self.title = title
        self.description = description
        self.save()

    def add_milestone(self, description, due_date):
        """Create a new milestone for this project."""
        milestone = Milestone.objects.create(
            project=self,
            description=description,
            due_date=due_date
        )
        return milestone

    def close_project(self):
        """Mark the project as completed."""
        self.status = 'completed'
        self.save()

    def get_team(self):
        """
        Get the team associated with this project.
        Returns None if no team exists yet.
        """
        return getattr(self, 'team', None)

    def get_current_team_size(self):
        """
        Count the number of members currently in the project team.
        Returns 0 if no team exists.
        """
        team = self.get_team()
        if team:
            return team.members.count()
        return 0

    def can_accept_members(self):
        """
        Check if the project can accept new team members.
        Returns True if current team size is below the maximum allowed.
        """
        return self.get_current_team_size() < self.max_team_size


class Milestone(models.Model):
    """
    Project milestone tracking.
    Used to break down projects into smaller, manageable goals with deadlines.
    """
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
        ordering = ['due_date']  # Sort by deadline, soonest first

    def __str__(self):
        # Show check mark if completed, circle if pending
        status = "✓" if self.is_completed else "○"
        return f"{status} {self.project.title} - {self.description[:50]}"

    def mark_complete(self):
        """
        Mark this milestone as completed and record the completion time.
        """
        self.is_completed = True
        self.completed_date = timezone.now()
        self.save()

    def clean(self):
        """
        Validation: Ensure new milestones have future due dates.
        """
        super().clean()
        if not self.pk and self.due_date < timezone.now().date():
            raise ValidationError('Milestone due date must be in the future.')


class JoinRequest(models.Model):
    """
    Represents a student's request to join a project team.

    Students can send join requests to projects they're interested in.
    Project owners can approve or reject these requests.
    The unique_together constraint prevents duplicate requests.
    """
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='join_requests')
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='join_requests')
    request_date = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    message = models.TextField(blank=True)  # Optional message from student
    response_message = models.TextField(blank=True)  # Optional response from project owner
    response_date = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'Join Request'
        verbose_name_plural = 'Join Requests'
        ordering = ['-request_date']  # Show newest requests first
        # Prevent duplicate requests from same student to same project
        unique_together = ['project', 'student']
        indexes = [
            # Index for filtering pending/approved/rejected requests
            models.Index(fields=['status', '-request_date']),
        ]

    def __str__(self):
        return f"{self.student.user.name} -> {self.project.title} ({self.status})"

    def approve(self):
        """
        Approve this join request and add the student to the project team.

        Process:
        1. Validate request status (must be pending)
        2. Create team if it doesn't exist yet
        3. Check if team has available slots
        4. Add student to team
        5. Update request status and timestamp

        Returns:
            bool: True if student was successfully added, False otherwise
        """
        from teams.models import Team
        from users.models import Notification

        # Only pending requests can be approved
        if self.status != 'pending':
            raise ValidationError('Only pending requests can be approved.')

        # Get or create the project team
        team = self.project.get_team()
        if not team:
            team = Team.objects.create(
                project=self.project,
                max_members=self.project.max_team_size
            )

        # Check if team has space for new members
        if not self.project.can_accept_members():
            raise ValidationError('Team is already full.')

        # Try to add the student to the team
        success = team.add_member(self.student)
        if success:
            # Update request status
            self.status = 'approved'
            self.response_date = timezone.now()
            self.save()

            # TODO: Re-enable notifications when notification system is fixed
            # Notification.objects.create(
            #     recipient=self.student.user,
            #     notification_type='join_request',
            #     title='Join Request Approved!',
            #     message=f'Your request to join "{self.project.title}" has been approved! Welcome to the team.',
            #     link=f'/projects/{self.project.id}'
            # )

            return True
        return False

    def reject(self):
        """
        Reject this join request.

        Updates the request status to rejected and records the response time.
        """
        from users.models import Notification

        # Only pending requests can be rejected
        if self.status != 'pending':
            raise ValidationError('Only pending requests can be rejected.')

        # Update request status
        self.status = 'rejected'
        self.response_date = timezone.now()
        self.save()

        # TODO: Re-enable notifications when notification system is fixed
        # Notification.objects.create(
        #     recipient=self.student.user,
        #     notification_type='join_request',
        #     title='Join Request Update',
        #     message=f'Your request to join "{self.project.title}" was not accepted this time. Keep exploring other projects!',
        #     link=f'/projects/{self.project.id}'
        # )

    def clean(self):
        """
        Validation rules for join requests:
        1. Students cannot request to join their own projects
        2. Students cannot send duplicate requests (except after rejection)
        """
        super().clean()

        # Prevent project owners from requesting to join their own project
        if self.student == self.project.owner:
            raise ValidationError('You cannot send a join request to your own project.')

        # Prevent duplicate requests (only for new requests)
        if not self.pk:
            # Check if student already has a pending or approved request
            existing = JoinRequest.objects.filter(
                project=self.project,
                student=self.student
            ).exclude(status='rejected').exists()
            if existing:
                raise ValidationError('You have already sent a request to this project.')


class Feedback(models.Model):
    """
    Faculty feedback on student projects.
    Allows professors to provide guidance and comments on project progress.
    """
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
    Individual task within a project.

    Tasks help teams break down project work into manageable pieces.
    Each task can be assigned to a specific team member with a priority and deadline.
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
    # Assignee can be null for unassigned tasks
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
        ordering = ['-created_at']  # Show newest tasks first
        indexes = [
            # Index for filtering tasks by project and status
            models.Index(fields=['project', 'status']),
            # Index for viewing a student's assigned tasks
            models.Index(fields=['assignee', 'status']),
        ]

    def __str__(self):
        return f"{self.project.title} - {self.title}"

    def mark_complete(self):
        """Mark this task as completed."""
        self.status = 'completed'
        self.save()


class Meeting(models.Model):
    """
    Project meeting scheduler.

    Teams can schedule both in-person and online meetings.
    Supports tracking participants and meeting details.
    """
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='meetings')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    date_time = models.DateTimeField()
    location = models.CharField(max_length=255, blank=True)  # For in-person meetings
    meeting_link = models.URLField(blank=True)  # For online meetings (Zoom, Teams, etc.)
    participants = models.ManyToManyField(Student, related_name='meetings', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Meeting'
        verbose_name_plural = 'Meetings'
        ordering = ['date_time']  # Sort by meeting time, soonest first
        indexes = [
            # Index for viewing a project's scheduled meetings
            models.Index(fields=['project', 'date_time']),
        ]

    def __str__(self):
        return f"{self.project.title} - {self.title} on {self.date_time.strftime('%Y-%m-%d %H:%M')}"
