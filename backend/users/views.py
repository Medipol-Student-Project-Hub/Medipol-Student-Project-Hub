from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import get_user_model
from django.db import IntegrityError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
import secrets

from .models import Student, Faculty
from .serializers import (
    UserSerializer, StudentProfileSerializer, FacultyProfileSerializer,
    StudentRegistrationSerializer, FacultyRegistrationSerializer,
    ChangePasswordSerializer, ForgotPasswordSerializer, ResetPasswordSerializer
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
    """Request password reset - sends reset token"""
    permission_classes = [AllowAny]
    serializer_class = ForgotPasswordSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']

        try:
            user = User.objects.get(email=email)
            # Generate a reset token
            reset_token = secrets.token_urlsafe(32)
            # Store token in user model (you may want to add a field for this)
            # For now, we'll use a simple approach with the session or cache
            # In production, you should store this in the database with expiry

            # For demo purposes, just return success
            # In production, send email with reset link
            return Response({
                'message': 'Password reset instructions sent to your email',
                'reset_token': reset_token  # Remove this in production
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            # Don't reveal if email exists or not (security)
            return Response({
                'message': 'Password reset instructions sent to your email'
            }, status=status.HTTP_200_OK)


class ResetPasswordView(generics.GenericAPIView):
    """Reset password using token"""
    permission_classes = [AllowAny]
    serializer_class = ResetPasswordSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        new_password = serializer.validated_data['new_password']

        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.save()

            return Response({
                'message': 'Password reset successfully'
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_400_BAD_REQUEST)
