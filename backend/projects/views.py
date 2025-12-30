from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q

from .models import Project, Milestone, JoinRequest
from .serializers import (
    ProjectListSerializer, ProjectDetailSerializer,
    ProjectCreateSerializer, ProjectUpdateSerializer,
    MilestoneSerializer, JoinRequestSerializer, JoinRequestResponseSerializer,
    FeedbackSerializer
)
from .permissions import (
    IsProjectOwnerOrReadOnly, IsProjectOwner,
    IsFacultyOrReadOnly, CanManageJoinRequest
)


class ProjectViewSet(viewsets.ModelViewSet):
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'category', 'tags']
    ordering_fields = ['posted_date', 'title', 'status']
    ordering = ['-posted_date']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return []  # No authentication required for viewing
        elif self.action in ['create', 'join']:
            return [IsAuthenticated()]  # Only authentication required for creation and joining
        else:
            return [IsAuthenticated(), IsProjectOwnerOrReadOnly()]  # Authentication + ownership for update/delete

    def get_queryset(self):
        queryset = Project.objects.select_related(
            'owner__user', 'supervisor__user'
        ).prefetch_related('milestones', 'team__members')

        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)

        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        skills = self.request.query_params.get('skills')
        if skills:
            skill_list = skills.split(',')
            for skill in skill_list:
                queryset = queryset.filter(required_skills__contains=skill.strip())

        if self.request.query_params.get('my_projects') == 'true':
            try:
                student = self.request.user.student_profile
                queryset = queryset.filter(owner=student)
            except AttributeError:
                queryset = queryset.none()

        if self.request.query_params.get('supervised') == 'true':
            try:
                faculty = self.request.user.faculty_profile
                queryset = queryset.filter(supervisor=faculty)
            except AttributeError:
                queryset = queryset.none()

        return queryset

    def get_serializer_class(self):
        if self.action == 'list':
            return ProjectListSerializer
        elif self.action == 'create':
            return ProjectCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return ProjectUpdateSerializer
        return ProjectDetailSerializer

    def perform_create(self, serializer):
        serializer.save()

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def join(self, request, pk=None):
        from users.models import Notification

        project = self.get_object()

        try:
            student = request.user.student_profile
        except AttributeError:
            return Response(
                {'error': 'Only students can join projects'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = JoinRequestSerializer(
            data={
                'project': project.id,
                'student': student.pk,
                'message': request.data.get('message', '')
            },
            context={'request': request}
        )

        if serializer.is_valid():
            join_request = serializer.save()

            # ✅ Notifications disabled for now - not working well
            # Notification.objects.create(
            #     recipient=project.owner.user,
            #     notification_type='join_request',
            #     title='New Join Request! 🙋',
            #     message=f'{student.user.name} wants to join your project "{project.title}"',
            #     link=f'/projects/{project.id}/requests'
            # )

            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated, IsProjectOwner])
    def requests(self, request, pk=None):
        project = self.get_object()
        join_requests = project.join_requests.select_related('student__user').all()

        status_filter = request.query_params.get('status')
        if status_filter:
            join_requests = join_requests.filter(status=status_filter)

        serializer = JoinRequestSerializer(join_requests, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsProjectOwner])
    def close(self, request, pk=None):
        project = self.get_object()
        project.close_project()
        return Response({
            'message': 'Project closed successfully',
            'project': ProjectDetailSerializer(project).data
        })

    @action(detail=True, methods=['get'])
    def milestones(self, request, pk=None):
        project = self.get_object()
        milestones = project.milestones.all()
        serializer = MilestoneSerializer(milestones, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsProjectOwner])
    def add_milestone(self, request, pk=None):
        project = self.get_object()
        serializer = MilestoneSerializer(data={**request.data, 'project': project.id})

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get', 'post'], permission_classes=[IsAuthenticated, IsFacultyOrReadOnly])
    def feedback(self, request, pk=None):
        project = self.get_object()

        if request.method == 'GET':
            feedbacks = project.feedbacks.select_related('faculty__user').all()
            serializer = FeedbackSerializer(feedbacks, many=True)
            return Response(serializer.data)

        try:
            faculty = request.user.faculty_profile
        except AttributeError:
            return Response(
                {'error': 'Only faculty can provide feedback'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = FeedbackSerializer(
            data={**request.data, 'project': project.id, 'faculty': faculty.pk}
        )

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def progress(self, request, pk=None):
        project = self.get_object()
        milestones = project.milestones.all()

        total_milestones = milestones.count()
        completed_milestones = milestones.filter(is_completed=True).count()
        progress_percentage = (completed_milestones / total_milestones * 100) if total_milestones > 0 else 0

        return Response({
            'project': ProjectDetailSerializer(project).data,
            'total_milestones': total_milestones,
            'completed_milestones': completed_milestones,
            'progress_percentage': round(progress_percentage, 2),
            'milestones': MilestoneSerializer(milestones, many=True).data
        })

    @action(detail=False, methods=['get'], url_path='my-projects', permission_classes=[IsAuthenticated])
    def my_projects(self, request):
        """
        Get projects related to the current user:
        - For students: Projects they own OR are team members of
        - For faculty: Projects they supervise
        """
        try:
            if request.user.user_type == 'student':
                student = request.user.student_profile

                # ✅ Get projects where student is owner OR team member
                from django.db.models import Q
                queryset = Project.objects.filter(
                    Q(owner=student) | Q(team__members=student)
                ).distinct().select_related(
                    'owner__user', 'supervisor__user'
                ).prefetch_related('milestones', 'team__members')

            elif request.user.user_type == 'faculty':
                faculty = request.user.faculty_profile
                queryset = Project.objects.filter(supervisor=faculty).select_related(
                    'owner__user', 'supervisor__user'
                ).prefetch_related('milestones', 'team__members')
            else:
                queryset = Project.objects.none()

            serializer = ProjectListSerializer(queryset, many=True)
            return Response(serializer.data)
        except AttributeError:
            return Response([], status=status.HTTP_200_OK)


class MilestoneViewSet(viewsets.ModelViewSet):
    queryset = Milestone.objects.select_related('project').all()
    serializer_class = MilestoneSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'student':
            try:
                student = user.student_profile
                return Milestone.objects.filter(
                    Q(project__owner=student) | Q(project__team__members=student)
                ).distinct()
            except AttributeError:
                pass
        return super().get_queryset()

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        milestone = self.get_object()

        project = milestone.project
        try:
            student = request.user.student_profile
            is_owner = project.owner == student
            is_member = project.team.members.filter(pk=student.pk).exists() if hasattr(project, 'team') else False

            if not (is_owner or is_member):
                return Response(
                    {'error': 'You do not have permission to mark this milestone as complete'},
                    status=status.HTTP_403_FORBIDDEN
                )
        except AttributeError:
            return Response(
                {'error': 'Only students can mark milestones as complete'},
                status=status.HTTP_403_FORBIDDEN
            )

        milestone.mark_complete()
        return Response({
            'message': 'Milestone marked as complete',
            'milestone': MilestoneSerializer(milestone).data
        })


class JoinRequestViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = JoinRequest.objects.select_related('project', 'student__user').all()
    serializer_class = JoinRequestSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        """Pass request context to serializer"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        """
        Return join requests where the current user is either:
        1. The student who sent the request (for students only)
        2. The owner of the project that received the request (students or faculty)
        """
        user = self.request.user

        if user.user_type == 'student':
            try:
                student = user.student_profile
                # Return requests I sent OR requests to projects I own
                return JoinRequest.objects.filter(
                    Q(student=student) | Q(project__owner=student)
                ).distinct().select_related('project__owner__user', 'student__user')
            except AttributeError:
                pass
        elif user.user_type == 'faculty':
            try:
                # Faculty can only see requests to projects they supervise/own
                # (Currently faculty can't own projects, but keeping for future)
                return JoinRequest.objects.none()
            except AttributeError:
                pass

        return JoinRequest.objects.none()

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, CanManageJoinRequest])
    def approve(self, request, pk=None):
        join_request = self.get_object()

        serializer = JoinRequestResponseSerializer(data=request.data)
        if serializer.is_valid():
            try:
                join_request.response_message = serializer.validated_data.get('response_message', '')
                join_request.approve()
                return Response({
                    'message': 'Join request approved successfully',
                    'request': JoinRequestSerializer(join_request).data
                })
            except Exception as e:
                return Response(
                    {'error': str(e)},
                    status=status.HTTP_400_BAD_REQUEST
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, CanManageJoinRequest])
    def reject(self, request, pk=None):
        join_request = self.get_object()

        serializer = JoinRequestResponseSerializer(data=request.data)
        if serializer.is_valid():
            try:
                join_request.response_message = serializer.validated_data.get('response_message', '')
                join_request.reject()
                return Response({
                    'message': 'Join request rejected',
                    'request': JoinRequestSerializer(join_request).data
                })
            except Exception as e:
                return Response(
                    {'error': str(e)},
                    status=status.HTTP_400_BAD_REQUEST
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
