from rest_framework import generics, status, viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import Student, Faculty, Notification
from .serializers import (
    UserSerializer, StudentProfileSerializer, FacultyProfileSerializer,
    StudentRegistrationSerializer, FacultyRegistrationSerializer,
    ChangePasswordSerializer, NotificationSerializer
)
from .permissions import IsOwnerOrReadOnly, IsStudent, IsFaculty

User = get_user_model()


class CustomTokenObtainPairView(TokenObtainPairView):
    """Custom login view that returns user data along with tokens"""

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)

        if response.status_code == 200:
            # Get user from email
            email = request.data.get('email')
            try:
                user = User.objects.get(email=email)
                user_data = UserSerializer(user).data

                # Add profile data
                if user.user_type == 'student':
                    try:
                        student_profile = StudentProfileSerializer(user.student_profile).data
                        user_data['student_profile'] = student_profile
                    except AttributeError:
                        pass
                elif user.user_type == 'faculty':
                    try:
                        faculty_profile = FacultyProfileSerializer(user.faculty_profile).data
                        user_data['faculty_profile'] = faculty_profile
                    except AttributeError:
                        pass

                # Add user data to response
                response.data['user'] = user_data
            except User.DoesNotExist:
                pass

        return response


class StudentRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = StudentRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        from django.db import IntegrityError

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = serializer.save()
        except IntegrityError:
            return Response({
                'email': ['A user with this email already exists.']
            }, status=status.HTTP_400_BAD_REQUEST)

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)

        # Get student profile data
        student_profile = StudentProfileSerializer(user.student_profile).data

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                **UserSerializer(user).data,
                'student_profile': student_profile
            }
        }, status=status.HTTP_201_CREATED)


class FacultyRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = FacultyRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        from django.db import IntegrityError

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = serializer.save()
        except IntegrityError:
            return Response({
                'email': ['A user with this email already exists.']
            }, status=status.HTTP_400_BAD_REQUEST)

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)

        # Get faculty profile data
        faculty_profile = FacultyProfileSerializer(user.faculty_profile).data

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                **UserSerializer(user).data,
                'faculty_profile': faculty_profile
            }
        }, status=status.HTTP_201_CREATED)


class CurrentUserView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def retrieve(self, request, *args, **kwargs):
        user = self.get_object()
        user_data = UserSerializer(user).data

        # Add profile data based on user type
        if user.user_type == 'student':
            try:
                student_profile = StudentProfileSerializer(user.student_profile).data
                user_data['student_profile'] = student_profile
            except AttributeError:
                pass
        elif user.user_type == 'faculty':
            try:
                faculty_profile = FacultyProfileSerializer(user.faculty_profile).data
                user_data['faculty_profile'] = faculty_profile
            except AttributeError:
                pass

        return Response(user_data)


class StudentProfileViewSet(viewsets.ModelViewSet):
    queryset = Student.objects.select_related('user').all()
    serializer_class = StudentProfileSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        queryset = super().get_queryset()

        department = self.request.query_params.get('department')
        if department:
            queryset = queryset.filter(department__icontains=department)

        year = self.request.query_params.get('year')
        if year:
            queryset = queryset.filter(year=year)

        skills = self.request.query_params.get('skills')
        if skills:
            skill_list = skills.split(',')
            for skill in skill_list:
                queryset = queryset.filter(skills__contains=skill.strip())

        return queryset

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def me(self, request):
        try:
            student = request.user.student_profile
            serializer = self.get_serializer(student)
            return Response(serializer.data)
        except AttributeError:
            return Response(
                {'error': 'User is not a student'},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['put', 'patch'], permission_classes=[IsAuthenticated, IsStudent])
    def update_profile(self, request):
        try:
            student = request.user.student_profile
            serializer = self.get_serializer(student, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        except AttributeError:
            return Response(
                {'error': 'User is not a student'},
                status=status.HTTP_400_BAD_REQUEST
            )


class FacultyProfileViewSet(viewsets.ModelViewSet):
    queryset = Faculty.objects.select_related('user').all()
    serializer_class = FacultyProfileSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        queryset = super().get_queryset()

        department = self.request.query_params.get('department')
        if department:
            queryset = queryset.filter(department__icontains=department)

        title = self.request.query_params.get('title')
        if title:
            queryset = queryset.filter(title__icontains=title)

        return queryset

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def me(self, request):
        try:
            faculty = request.user.faculty_profile
            serializer = self.get_serializer(faculty)
            return Response(serializer.data)
        except AttributeError:
            return Response(
                {'error': 'User is not faculty'},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['put', 'patch'], permission_classes=[IsAuthenticated, IsFaculty])
    def update_profile(self, request):
        try:
            faculty = request.user.faculty_profile
            serializer = self.get_serializer(faculty, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        except AttributeError:
            return Response(
                {'error': 'User is not faculty'},
                status=status.HTTP_400_BAD_REQUEST
            )


class ChangePasswordView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ChangePasswordSerializer

    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user

        if not user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'old_password': 'Wrong password'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(serializer.validated_data['new_password'])
        user.save()

        return Response({
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)


class ForgotPasswordView(generics.GenericAPIView):
    """
    Request password reset email
    POST /api/users/forgot-password/
    Body: { "email": "user@example.com" }
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        email = request.data.get('email')

        if not email:
            return Response(
                {'email': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(email=email)

            # TODO: Implement actual email sending with reset token
            # For now, we'll return success (in production, send email with token)
            # You can use Django's built-in PasswordResetTokenGenerator
            # from django.contrib.auth.tokens import default_token_generator
            # token = default_token_generator.make_token(user)

            # In production: Send email with reset link containing token
            # send_mail(
            #     subject='Password Reset Request',
            #     message=f'Click here to reset: https://yourapp.com/reset/{token}',
            #     from_email=settings.DEFAULT_FROM_EMAIL,
            #     recipient_list=[email],
            # )

            return Response({
                'message': 'Password reset instructions have been sent to your email',
                'email': email,
                # TODO: Remove this in production!
                'debug_note': 'Email sending not implemented yet. In production, user would receive email.'
            }, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            # Security: Don't reveal if email exists or not
            return Response({
                'message': 'If an account with this email exists, password reset instructions have been sent',
            }, status=status.HTTP_200_OK)


class ResetPasswordView(generics.GenericAPIView):
    """
    Reset password with token
    POST /api/users/reset-password/
    Body: { "token": "...", "new_password": "..." }
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        token = request.data.get('token')
        new_password = request.data.get('new_password')

        if not token or not new_password:
            return Response(
                {'error': 'Token and new password are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # TODO: Implement token validation and password reset
        # from django.contrib.auth.tokens import default_token_generator
        # from django.utils.http import urlsafe_base64_decode
        #
        # try:
        #     uid = urlsafe_base64_decode(uidb64).decode()
        #     user = User.objects.get(pk=uid)
        #
        #     if default_token_generator.check_token(user, token):
        #         user.set_password(new_password)
        #         user.save()
        #         return Response({'message': 'Password reset successful'})
        #     else:
        #         return Response({'error': 'Invalid token'}, status=400)
        # except:
        #     return Response({'error': 'Invalid request'}, status=400)

        return Response({
            'message': 'Password reset functionality not fully implemented yet',
            'debug_note': 'Token validation needs to be implemented'
        }, status=status.HTTP_501_NOT_IMPLEMENTED)


class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing notifications
    """
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer
    queryset = Notification.objects.all()

    def get_queryset(self):
        """Get only notifications for the current user"""
        return Notification.objects.filter(recipient=self.request.user)

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get count of unread notifications"""
        count = Notification.objects.filter(
            recipient=request.user,
            is_read=False
        ).count()
        return Response({'unread_count': count})

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark a notification as read"""
        notification = self.get_object()
        notification.mark_as_read()
        return Response({'status': 'notification marked as read'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read for the current user"""
        Notification.objects.filter(
            recipient=request.user,
            is_read=False
        ).update(is_read=True)
        return Response({'status': 'all notifications marked as read'})
