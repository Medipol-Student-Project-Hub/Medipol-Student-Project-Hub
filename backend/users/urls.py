"""
URL routing for Users app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenBlacklistView
)

from .views import (
    CustomTokenObtainPairView,
    StudentRegistrationView,
    FacultyRegistrationView,
    CurrentUserView,
    StudentProfileViewSet,
    FacultyProfileViewSet,
    ChangePasswordView,
    ForgotPasswordView,
    ResetPasswordView,
    NotificationViewSet
)

router = DefaultRouter()
router.register(r'students', StudentProfileViewSet, basename='student')
router.register(r'faculty', FacultyProfileViewSet, basename='faculty')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    # Authentication endpoints
    path('register/student/', StudentRegistrationView.as_view(), name='register-student'),
    path('register/faculty/', FacultyRegistrationView.as_view(), name='register-faculty'),
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('logout/', TokenBlacklistView.as_view(), name='token_blacklist'),

    # User profile endpoints
    path('profile/', CurrentUserView.as_view(), name='current-user'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),

    # Password reset endpoints
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset-password'),

    # Router endpoints
    path('', include(router.urls)),
]
