from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AffectationViewSet

router = DefaultRouter()
router.register('', AffectationViewSet, basename='affectation')

urlpatterns = [
    path('', include(router.urls)),
] 