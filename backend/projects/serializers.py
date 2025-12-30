from rest_framework import serializers
from .models import Project, Milestone, JoinRequest, Feedback, Task, Meeting
from users.serializers import StudentProfileSerializer, FacultyProfileSerializer


class MilestoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = Milestone
        fields = [
            'id', 'project', 'description', 'due_date', 'is_completed',
            'completed_date', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'completed_date', 'created_at', 'updated_at']

    def validate_due_date(self, value):
        from django.utils import timezone
        if not self.instance and value < timezone.now().date():
            raise serializers.ValidationError("Milestone due date must be in the future.")
        return value


class JoinRequestSerializer(serializers.ModelSerializer):
    student_info = StudentProfileSerializer(source='student', read_only=True)
    project_info = serializers.SerializerMethodField()
    is_sent_by_me = serializers.SerializerMethodField()

    class Meta:
        model = JoinRequest
        fields = [
            'id', 'project', 'student', 'student_info', 'project_info',
            'request_date', 'status', 'message', 'response_message', 'response_date',
            'is_sent_by_me'
        ]
        read_only_fields = ['id', 'request_date', 'status', 'response_date', 'student_info']

    def get_project_info(self, obj):
        return {
            'id': obj.project.id,
            'title': obj.project.title,
            'owner': obj.project.owner.user.name,
            'owner_id': obj.project.owner.user.id
        }

    def get_is_sent_by_me(self, obj):
        """Check if this request was sent by the current user"""
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            user = request.user
            if user.user_type == 'student':
                try:
                    return obj.student.user.id == user.id
                except AttributeError:
                    pass
        return False

    def validate(self, attrs):
        project = attrs.get('project')
        student = attrs.get('student')

        if student == project.owner:
            raise serializers.ValidationError({"error": "You cannot send a join request to your own project."})

        existing = JoinRequest.objects.filter(
            project=project,
            student=student
        ).exclude(status='rejected').exists()
        if existing:
            raise serializers.ValidationError({"error": "You have already sent a join request to this project."})

        if not project.can_accept_members():
            raise serializers.ValidationError({"error": "This project's team is already full."})

        return attrs


class JoinRequestResponseSerializer(serializers.Serializer):
    response_message = serializers.CharField(required=False, allow_blank=True)


class FeedbackSerializer(serializers.ModelSerializer):
    faculty_info = FacultyProfileSerializer(source='faculty', read_only=True)

    class Meta:
        model = Feedback
        fields = [
            'id', 'project', 'faculty', 'faculty_info', 'comments',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'faculty', 'faculty_info', 'created_at', 'updated_at']


class ProjectListSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source='owner.user.name', read_only=True)
    current_team_size = serializers.SerializerMethodField()
    supervisor_name = serializers.CharField(source='supervisor.user.name', read_only=True, allow_null=True)

    class Meta:
        model = Project
        fields = [
            'id', 'title', 'description', 'category', 'status', 'posted_date',
            'owner_name', 'current_team_size', 'max_team_size', 'supervisor_name',
            'required_skills', 'tags'
        ]

    def get_current_team_size(self, obj):
        return obj.get_current_team_size()


class ProjectDetailSerializer(serializers.ModelSerializer):
    owner_info = StudentProfileSerializer(source='owner', read_only=True)
    supervisor_info = FacultyProfileSerializer(source='supervisor', read_only=True)
    milestones = MilestoneSerializer(many=True, read_only=True)
    tasks = serializers.SerializerMethodField()
    meetings = serializers.SerializerMethodField()
    current_team_size = serializers.SerializerMethodField()
    available_slots = serializers.SerializerMethodField()
    team_members = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = [
            'id', 'title', 'description', 'category', 'status', 'posted_date',
            'owner', 'owner_info', 'supervisor', 'supervisor_info',
            'required_skills', 'max_team_size', 'current_team_size', 'available_slots',
            'start_date', 'expected_duration', 'tags', 'objectives', 'requirements',
            'milestones', 'tasks', 'meetings', 'team_members',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'posted_date', 'owner', 'created_at', 'updated_at']

    def get_current_team_size(self, obj):
        return obj.get_current_team_size()

    def get_available_slots(self, obj):
        return obj.max_team_size - obj.get_current_team_size()

    def get_tasks(self, obj):
        from .serializers import TaskSerializer
        tasks = obj.tasks.all()
        return TaskSerializer(tasks, many=True).data

    def get_meetings(self, obj):
        from .serializers import MeetingSerializer
        meetings = obj.meetings.all()
        return MeetingSerializer(meetings, many=True).data

    def get_team_members(self, obj):
        team = obj.get_team()
        if team:
            members = team.members.all()
            return StudentProfileSerializer(members, many=True).data
        return []


class ProjectCreateSerializer(serializers.ModelSerializer):
    supervisor_name = serializers.CharField(required=False, allow_blank=True, write_only=True)

    class Meta:
        model = Project
        fields = [
            'title', 'description', 'category', 'status', 'supervisor', 'supervisor_name',
            'required_skills', 'max_team_size', 'start_date', 'expected_duration',
            'tags', 'objectives', 'requirements'
        ]
        extra_kwargs = {
            'supervisor': {'required': False, 'allow_null': True}
        }

    def validate_max_team_size(self, value):
        if value < 1 or value > 20:
            raise serializers.ValidationError("Team size must be between 1 and 20.")
        return value

    def validate(self, attrs):
        """Handle supervisor field - accept either ID or name"""
        supervisor_name = attrs.pop('supervisor_name', None)

        # If supervisor_name is provided but supervisor ID is not
        if supervisor_name and not attrs.get('supervisor'):
            from users.models import Faculty
            # Try to find faculty by name (case-insensitive)
            try:
                faculty = Faculty.objects.filter(
                    user__name__icontains=supervisor_name
                ).first()
                if faculty:
                    attrs['supervisor'] = faculty
                # If not found, we'll just ignore it (supervisor is optional)
            except Exception:
                pass

        return attrs

    def create(self, validated_data):
        from teams.models import Team
        from users.models import Student

        request = self.context.get('request')
        user = request.user

        # ✅ Both students and faculty can create projects
        if user.user_type == 'student':
            try:
                owner = user.student_profile
            except AttributeError:
                raise serializers.ValidationError("Student profile not found.")
        elif user.user_type == 'faculty':
            # ✅ Faculty can create projects!
            # Faculty user becomes the supervisor, and we need a student as owner
            owner_id = self.context.get('request').data.get('owner_id')
            if owner_id:
                try:
                    owner = Student.objects.get(pk=owner_id)
                except Student.DoesNotExist:
                    raise serializers.ValidationError("Invalid owner_id. Student not found.")
            else:
                # If no owner_id provided, use the first available student as placeholder
                # Faculty will be set as supervisor automatically
                owner = Student.objects.first()
                if not owner:
                    raise serializers.ValidationError(
                        "No students found in system. Please create a student account first."
                    )
        else:
            raise serializers.ValidationError("Only students and faculty can create projects.")

        project = Project.objects.create(owner=owner, **validated_data)

        Team.objects.create(project=project, max_members=project.max_team_size)

        return project


class ProjectUpdateSerializer(serializers.ModelSerializer):
    supervisor_name = serializers.CharField(required=False, allow_blank=True, write_only=True)

    class Meta:
        model = Project
        fields = [
            'title', 'description', 'category', 'status', 'supervisor', 'supervisor_name',
            'required_skills', 'max_team_size', 'start_date', 'expected_duration',
            'tags', 'objectives', 'requirements'
        ]
        extra_kwargs = {
            'supervisor': {'required': False, 'allow_null': True}
        }

    def validate_max_team_size(self, value):
        if self.instance:
            current_size = self.instance.get_current_team_size()
            if value < current_size:
                raise serializers.ValidationError(
                    f"Cannot set max team size below current member count ({current_size})."
                )
        return value

    def validate(self, attrs):
        """Handle supervisor field - accept either ID or name"""
        supervisor_name = attrs.pop('supervisor_name', None)

        # If supervisor_name is provided but supervisor ID is not
        if supervisor_name and not attrs.get('supervisor'):
            from users.models import Faculty
            # Try to find faculty by name (case-insensitive)
            try:
                faculty = Faculty.objects.filter(
                    user__name__icontains=supervisor_name
                ).first()
                if faculty:
                    attrs['supervisor'] = faculty
            except Exception:
                pass

        return attrs


class TaskSerializer(serializers.ModelSerializer):
    """Serializer for Task model"""
    assignee_name = serializers.CharField(source='assignee.user.name', read_only=True, allow_null=True)
    project_title = serializers.CharField(source='project.title', read_only=True)

    class Meta:
        model = Task
        fields = [
            'id', 'project', 'project_title', 'title', 'description',
            'status', 'priority', 'assignee', 'assignee_name',
            'due_date', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class MeetingSerializer(serializers.ModelSerializer):
    """Serializer for Meeting model"""
    project_title = serializers.CharField(source='project.title', read_only=True)
    participant_names = serializers.SerializerMethodField()

    class Meta:
        model = Meeting
        fields = [
            'id', 'project', 'project_title', 'title', 'description',
            'date_time', 'location', 'meeting_link', 'participants',
            'participant_names', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_participant_names(self, obj):
        return [p.user.name for p in obj.participants.all()]
