"""
URL routing for Projects app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    ProjectViewSet,
    MilestoneViewSet,
    JoinRequestViewSet
)

router = DefaultRouter()
# Register specific paths BEFORE the catch-all empty prefix
router.register(r'milestones', MilestoneViewSet, basename='milestone')
router.register(r'requests', JoinRequestViewSet, basename='joinrequest')
router.register(r'', ProjectViewSet, basename='project')

urlpatterns = [
    path('', include(router.urls)),
]
