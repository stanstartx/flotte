from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .auth_views import (
    register_user,
    get_user_role,
    login_user,
    logout_user,
    verify_token,
    change_password,
    forgot_password,
)
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
    all_drivers_positions,
    driver_trips_history,
    places_autocomplete,
    places_details,
    places_distance,
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
    path('drivers/positions/', all_drivers_positions, name='all-drivers-positions'),
    path('drivers/<int:driver_id>/trips/', driver_trips_history, name='driver-trips-history'),
    path('', include(router.urls)),
    
    # Endpoints d'authentification personnalisés
    path('auth/register/', register_user, name='register'),
    path('auth/role/', get_user_role, name='get_user_role'),
    path('auth/login/', login_user, name='login'),
    path('auth/logout/', logout_user, name='logout'),
    path('auth/verify/', verify_token, name='verify_token'),
    path('auth/change-password/', change_password, name='change_password'),
    path('auth/forgot-password/', forgot_password, name='forgot_password'),
    
    # Endpoints JWT standards (rest_framework_simplejwt)
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Autres endpoints
    path('api-auth/', include('rest_framework.urls')),
    path('user/', views.UserInfoView.as_view(), name='user-info'),
    path('send-alert-email/', views.send_alert_email, name='send_alert_email'),
    path('api/conducteur/', include('conducteur.urls')),
    path('available_vehicles/', views.available_vehicles, name='available_vehicles'),
    path('available_drivers/', views.available_drivers, name='available_drivers'),
    
    # Endpoints du dashboard
    path('dashboard/stats/', views.dashboard_stats, name='dashboard_stats'),
    path('dashboard/recent-activities/', views.recent_activities, name='recent_activities'),
    
    # Endpoint de recherche globale
    path('search/', views.global_search, name='global_search'),

    # Proxy Google Places
    path('places/autocomplete/', places_autocomplete, name='places_autocomplete'),
    path('places/details/', places_details, name='places_details'),
    path('places/distance/', places_distance, name='places_distance'),
]