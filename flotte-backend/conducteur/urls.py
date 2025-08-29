from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MissionViewSet, PointGPSViewSet, VehiculesAffectesView

router = DefaultRouter()
router.register('missions', MissionViewSet, basename='mission')
router.register('gps', PointGPSViewSet, basename='gps')

urlpatterns = [
    path('', include(router.urls)),
    path('vehicules/', VehiculesAffectesView.as_view(), name='vehicules-affectes'),
] 