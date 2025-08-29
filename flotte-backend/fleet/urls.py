from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .auth_views import register_user, get_user_role, login_user
from . import views



from .views import (
    VehicleViewSet,
    DriverViewSet,
    AssignmentViewSet,
    MaintenanceViewSet,
    FuelLogViewSet,
    AlertViewSet,
    MissionViewSet,
    ExpenseViewSet,
    FinancialReportViewSet,
    UserProfileViewSet,
    DocumentAdministratifViewSet,
    EntretienViewSet,
    RapportViewSet,
    CommentaireEcartViewSet,
    HistoriqueViewSet,
    UserInfoView,
    ManagerViewSet,
    PositionListCreateAPIView,
    LastPositionAPIView,
)

router = DefaultRouter()
router.register(r'userprofiles', views.UserProfileViewSet)
router.register(r'vehicles', views.VehicleViewSet)
router.register(r'drivers', views.DriverViewSet)
router.register(r'assignments', views.AssignmentViewSet)
router.register(r'maintenances', views.MaintenanceViewSet)
router.register(r'fuel-logs', views.FuelLogViewSet)
router.register(r'alerts', AlertViewSet, basename='alert')
router.register(r'missions', views.MissionViewSet)
router.register(r'expenses', views.ExpenseViewSet)
router.register(r'reports', views.FinancialReportViewSet)
router.register(r'documents', views.DocumentAdministratifViewSet)
router.register(r'entretiens', views.EntretienViewSet)
router.register(r'rapports', views.RapportViewSet)
router.register(r'commentaires', views.CommentaireEcartViewSet)
router.register(r'historique', views.HistoriqueViewSet)
router.register(r'managers', views.ManagerViewSet, basename='manager')

urlpatterns = [
    path('userprofiles/my_profile/', views.user_profile_me, name='my-profile'),
    path('positions/', PositionListCreateAPIView.as_view(), name='positions-list-create'),
    path('positions/last/<int:driver_id>/', LastPositionAPIView.as_view(), name='position-last'),
    path('', include(router.urls)),
    path('auth/register/', register_user, name='register'),
    path('auth/role/', get_user_role, name='get_user_role'),
    path('auth/login/', login_user, name='login'),
    path('api-auth/', include('rest_framework.urls')),
    path('user/', views.UserInfoView.as_view(), name='user-info'),
    path('send-alert-email/', views.send_alert_email, name='send_alert_email'),
    path('api/conducteur/', include('conducteur.urls')),
    path('available_vehicles/', views.available_vehicles, name='available_vehicles'),
    path('available_drivers/', views.available_drivers, name='available_drivers'),
]
