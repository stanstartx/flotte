# fleet/views.py

from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Sum, Avg
from django.utils import timezone
from datetime import timedelta
from .models import (
    Vehicle,
    Driver,
    Assignment,
    Maintenance,
    FuelLog,
    Alert,
    Mission,
    Expense,
    FinancialReport,
    UserProfile,
    DocumentAdministratif,
    Entretien,
    Affectation,
    Rapport,
    CommentaireEcart,
    Historique,
    Position
)
from .serializers import (
    VehicleSerializer,
    DriverSerializer,
    AssignmentSerializer,
    MaintenanceSerializer,
    FuelLogSerializer,
    AlertSerializer,
    MissionSerializer,
    ExpenseSerializer,
    FinancialReportSerializer,
    UserProfileSerializer,
    DocumentAdministratifSerializer,
    EntretienSerializer,
    AffectationSerializer,
    RapportSerializer,
    CommentaireEcartSerializer,
    HistoriqueSerializer,
    PositionSerializer
)
from rest_framework.views import APIView
from django.contrib.auth.models import User, Group
from django.core.mail import send_mail
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from rest_framework.permissions import IsAuthenticated
from rest_framework.generics import CreateAPIView, RetrieveAPIView
from django.utils.dateparse import parse_datetime
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.db import models
from .serializers import MissionSerializer
import logging
import os

try:
    import requests
except Exception:
    requests = None

# Configurer le logger
logger = logging.getLogger(__name__)

class UserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    @action(detail=True, methods=['get'])
    def get_driver_info(self, request, pk=None):
        profile = self.get_object()
        try:
            driver = Driver.objects.get(user_profile=profile)
            return Response(DriverSerializer(driver).data)
        except Driver.DoesNotExist:
            return Response({'message': 'Ce profil n\'est pas associé à un conducteur'}, 
                          status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['get'])
    def my_profile(self, request):
        profile = request.user.profile
        return Response(self.get_serializer(profile, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def upload_photo(self, request, pk=None):
        profile = self.get_object()
        photo = request.FILES.get('photo')
        if not photo:
            return Response({'error': 'Aucun fichier envoyé.'}, status=400)
        profile.photo = photo
        profile.save()
        return Response(self.get_serializer(profile, context={'request': request}).data)

class DriverViewSet(viewsets.ModelViewSet):
    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    @action(detail=True, methods=['get'])
    def user_info(self, request, pk=None):
        driver = self.get_object()
        return Response(UserProfileSerializer(driver.user_profile).data)

    def create(self, request, *args, **kwargs):
        content_type = request.content_type
        
        if 'multipart' in content_type:
            data = request.data.copy()
            for key in data:
                if isinstance(data[key], list) and key != 'photo':
                    data[key] = data[key][0]
                    
            if 'user_profile_data' in data:
                import json
                val = data['user_profile_data']
                if isinstance(val, str):
                    try:
                        data['user_profile_data'] = json.loads(val)
                    except Exception as e:
                        return Response({'error': 'user_profile_data mal formé'}, status=400)
                if not isinstance(data['user_profile_data'], dict):
                    return Response({'error': 'user_profile_data doit être un objet'}, status=400)
        else:
            data = request.data

        required_fields = ['user_profile_id', 'numero_permis']
        missing_fields = [field for field in required_fields if field not in data or not data[field]]
        
        if missing_fields:
            return Response({
                'error': f'Champs requis manquants: {", ".join(missing_fields)}'
            }, status=400)

        try:
            user_profile = UserProfile.objects.get(id=data['user_profile_id'])
        except UserProfile.DoesNotExist:
            return Response({'error': 'UserProfile non trouvé'}, status=400)
        except (ValueError, TypeError):
            return Response({'error': 'user_profile_id invalide'}, status=400)

        if Driver.objects.filter(numero_permis=data['numero_permis']).exists():
            return Response({'error': 'Ce numéro de permis existe déjà'}, status=400)

        serializer = self.get_serializer(data=data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            return Response(serializer.errors, status=400)
        
        instance = serializer.save()
        
        if 'multipart' in content_type:
            photo = request.FILES.get('photo')
            if photo and hasattr(instance, 'user_profile'):
                instance.user_profile.photo = photo
                instance.user_profile.save()
        
        return Response(
            self.get_serializer(instance, context={'request': request}).data, 
            status=status.HTTP_201_CREATED
        )

class VehicleViewSet(viewsets.ModelViewSet):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['get'])
    def details_complets(self, request, pk=None):
        vehicle = self.get_object()
        data = self.get_serializer(vehicle).data
        
        maintenances = Maintenance.objects.filter(vehicle=vehicle).order_by('-date')
        data['maintenances'] = MaintenanceSerializer(maintenances, many=True).data
        
        pleins = FuelLog.objects.filter(vehicle=vehicle).order_by('-date')
        data['pleins'] = FuelLogSerializer(pleins, many=True).data
        
        depenses = Expense.objects.filter(vehicle=vehicle).order_by('-date')
        data['depenses'] = ExpenseSerializer(depenses, many=True).data
        
        missions = Mission.objects.filter(vehicle=vehicle).order_by('-date_debut')
        data['missions'] = MissionSerializer(missions, many=True).data
        
        return Response(data)

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        total_vehicules = Vehicle.objects.count()
        vehicules_actifs = Vehicle.objects.filter(actif=True).count()
        total_kilometrage = Vehicle.objects.aggregate(total=Sum('kilometrage'))['total'] or 0
        
        depenses = Expense.objects.all()
        total_depenses = depenses.aggregate(total=Sum('montant'))['total'] or 0
        
        pleins = FuelLog.objects.all()
        total_litres = pleins.aggregate(total=Sum('litres'))['total'] or 0
        consommation_moyenne = 0
        if total_kilometrage > 0:
            consommation_moyenne = (total_litres * 100) / total_kilometrage
        
        return Response({
            'total_vehicules': total_vehicules,
            'vehicules_actifs': vehicules_actifs,
            'total_kilometrage': total_kilometrage,
            'total_depenses': total_depenses,
            'consommation_moyenne': consommation_moyenne
        })

    @action(detail=True, methods=['get'])
    def historique(self, request, pk=None):
        vehicle = self.get_object()
        date_debut = request.query_params.get('date_debut')
        date_fin = request.query_params.get('date_fin')
        
        if not all([date_debut, date_fin]):
            return Response({'error': 'date_debut et date_fin sont requis'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        maintenances = Maintenance.objects.filter(
            vehicle=vehicle,
            date__range=[date_debut, date_fin]
        ).order_by('-date')
        
        pleins = FuelLog.objects.filter(
            vehicle=vehicle,
            date__range=[date_debut, date_fin]
        ).order_by('-date')
        
        missions = Mission.objects.filter(
            vehicle=vehicle,
            date_debut__range=[date_debut, date_fin]
        ).order_by('-date_debut')
        
        return Response({
            'maintenances': MaintenanceSerializer(maintenances, many=True).data,
            'pleins': FuelLogSerializer(pleins, many=True).data,
            'missions': MissionSerializer(missions, many=True).data
        })

class AssignmentViewSet(viewsets.ModelViewSet):
    queryset = Assignment.objects.all()
    serializer_class = AssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]

class MaintenanceViewSet(viewsets.ModelViewSet):
    queryset = Maintenance.objects.all()
    serializer_class = MaintenanceSerializer
    permission_classes = [permissions.IsAuthenticated]

class FuelLogViewSet(viewsets.ModelViewSet):
    queryset = FuelLog.objects.all()
    serializer_class = FuelLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def consumption_stats(self, request):
        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response({'error': 'vehicle_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        vehicle = Vehicle.objects.get(id=vehicle_id)
        return Response({
            'consommation_moyenne': vehicle.consommation_moyenne,
            'total_carburant': FuelLog.objects.filter(vehicle=vehicle).aggregate(
                total=Sum('cout'))['total'] or 0,
            'total_litres': FuelLog.objects.filter(vehicle=vehicle).aggregate(
                total=Sum('litres'))['total'] or 0,
            'prix_moyen': FuelLog.objects.filter(vehicle=vehicle).aggregate(
                avg=Avg('prix_litre'))['avg'] or 0
        })

class AlertViewSet(viewsets.ModelViewSet):
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Alert.objects.filter(resolue=False).order_by('-date_alerte')
        return queryset

    def generate_alerts(self):
        today = timezone.now().date()
        
        Alert.objects.filter(resolue=False).delete()
        
        vehicles = Vehicle.objects.all()
        for vehicle in vehicles:
            if vehicle.assurance_expiration and (vehicle.assurance_expiration - today).days <= 30:
                Alert.objects.create(
                    vehicle=vehicle,
                    type_alerte='assurance',
                    message=f"L'assurance du véhicule {vehicle} expire le {vehicle.assurance_expiration}",
                    niveau='warning' if (vehicle.assurance_expiration - today).days > 7 else 'critique'
                )
            
            if vehicle.visite_technique and (vehicle.visite_technique - today).days <= 30:
                Alert.objects.create(
                    vehicle=vehicle,
                    type_alerte='controle_technique',
                    message=f"La visite technique du véhicule {vehicle} expire le {vehicle.visite_technique}",
                    niveau='warning' if (vehicle.visite_technique - today).days > 7 else 'critique'
                )

        drivers = Driver.objects.filter(statut='actif')
        for driver in drivers:
            if driver.date_expiration_permis:
                days_until_expiration = (driver.date_expiration_permis - today).days
                if days_until_expiration <= 30:
                    try:
                        full_name = driver.user_profile.user.get_full_name() or driver.user_profile.user.username
                        Alert.objects.create(
                            driver=driver,
                            type_alerte='permis',
                            message=f"Le permis de conduire de {full_name} expire le {driver.date_expiration_permis}",
                            niveau='warning' if days_until_expiration > 7 else 'critique'
                        )
                    except Exception as e:
                        print(f"Erreur lors de la création de l'alerte pour le conducteur {driver.id}: {str(e)}")

        documents = DocumentAdministratif.objects.all()
        for doc in documents:
            if (doc.date_expiration - today).days <= 30:
                Alert.objects.create(
                    vehicle=doc.vehicle,
                    type_alerte=doc.type_document,
                    message=f"Le document {doc.type_document} du véhicule {doc.vehicle} expire le {doc.date_expiration}",
                    niveau='warning' if (doc.date_expiration - today).days > 7 else 'critique'
                )

    @action(detail=False, methods=['get'])
    def generate(self, request):
        self.generate_alerts()
        return Response({'message': 'Alertes générées avec succès'})

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        alert = self.get_object()
        alert.resolue = True
        alert.save()
        return Response({'message': 'Alerte marquée comme résolue'})

    @action(detail=False, methods=['get'])
    def mes_alertes(self, request):
        user = request.user
        try:
            conducteur = user.profile.driver
        except Exception:
            return Response({'error': 'Conducteur non trouvé.'}, status=404)
        alertes_conducteur = Alert.objects.filter(driver=conducteur, resolue=False)
        maintenant = timezone.now()
        vehicules_affectes = Affectation.objects.filter(driver=conducteur, statut='actif').values_list('vehicle_id', flat=True)
        vehicules_missions = Mission.objects.filter(driver=conducteur, date_depart__gte=maintenant).values_list('vehicle_id', flat=True)
        vehicules_ids = set(list(vehicules_affectes) + list(vehicules_missions))
        alertes_vehicules = Alert.objects.filter(vehicle_id__in=vehicules_ids, resolue=False)
        alertes = list(alertes_conducteur) + list(alertes_vehicules)
        alertes = {a.id: a for a in alertes}.values()
        serializer = self.get_serializer(alertes, many=True)
        return Response(serializer.data)

class IsAdminOrDriver(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.user.is_superuser or request.user.groups.filter(name='admin').exists():
            return True
        return Driver.objects.filter(user_profile__user=request.user).exists()

class MissionViewSet(viewsets.ModelViewSet):
    queryset = Mission.objects.all()
    serializer_class = MissionSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminOrDriver]

    def get_queryset(self):
        queryset = super().get_queryset()
        driver_id = self.request.query_params.get('driver')

        if self.request.user.is_superuser or self.request.user.groups.filter(name='admin').exists():
            return queryset

        if driver_id:
            try:
                driver = Driver.objects.get(id=driver_id)
                queryset = queryset.filter(driver=driver)
            except Driver.DoesNotExist:
                queryset = queryset.none()
        elif self.request.user.is_authenticated:
            try:
                driver = Driver.objects.get(user_profile__user=self.request.user)
                queryset = queryset.filter(driver=driver)
            except Driver.DoesNotExist:
                queryset = queryset.none()
        return queryset

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        for mission in serializer.data:
            logger.info(f"Mission ID: {mission['id']}, Statut: {mission['statut']}, Réponse conducteur: {mission['reponse_conducteur']}")
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def me(self, request):
        try:
            driver = Driver.objects.get(user_profile__user=request.user)
            missions = Mission.objects.filter(driver=driver)
            serializer = self.get_serializer(missions, many=True)
            return Response(serializer.data)
        except Driver.DoesNotExist:
            return Response({'error': 'Conducteur non trouvé'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['post'])
    def accepter(self, request, pk=None):
        mission = self.get_object()
        try:
            driver = Driver.objects.get(user_profile__user=request.user)
            if mission.driver != driver:
                return Response({'error': 'Vous n\'êtes pas autorisé à accepter cette mission'}, status=status.HTTP_403_FORBIDDEN)
            if mission.reponse_conducteur != 'en_attente':
                return Response({'error': 'Mission déjà acceptée ou refusée'}, status=status.HTTP_400_BAD_REQUEST)
            mission.reponse_conducteur = 'acceptee'
            mission.statut = 'acceptee'
            mission.save()
            logger.info(f"Mission {mission.id} acceptée: statut={mission.statut}, reponse_conducteur={mission.reponse_conducteur}")
            return Response({'message': 'Mission acceptée'}, status=status.HTTP_200_OK)
        except Driver.DoesNotExist:
            return Response({'error': 'Conducteur non trouvé'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['post'])
    def refuser(self, request, pk=None):
        mission = self.get_object()
        try:
            driver = Driver.objects.get(user_profile__user=request.user)
            if mission.driver != driver:
                return Response({'error': 'Vous n\'êtes pas autorisé à refuser cette mission'}, status=status.HTTP_403_FORBIDDEN)
            if mission.reponse_conducteur != 'en_attente':
                return Response({'error': 'Mission déjà acceptée ou refusée'}, status=status.HTTP_400_BAD_REQUEST)
            mission.reponse_conducteur = 'refusee'
            mission.statut = 'refusee'
            mission.save()
            logger.info(f"Mission {mission.id} refusée: statut={mission.statut}, reponse_conducteur={mission.reponse_conducteur}")
            return Response({'message': 'Mission refusée'}, status=status.HTTP_200_OK)
        except Driver.DoesNotExist:
            return Response({'error': 'Conducteur non trouvé'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['post'])
    def terminer(self, request, pk=None):
        mission = self.get_object()
        try:
            driver = Driver.objects.get(user_profile__user=request.user)
            if mission.driver != driver:
                return Response({'error': 'Vous n\'êtes pas autorisé à terminer cette mission'}, status=status.HTTP_403_FORBIDDEN)
            if mission.statut not in ['acceptee', 'en_cours']:
                return Response({'error': 'Mission non acceptée ou déjà terminée'}, status=status.HTTP_400_BAD_REQUEST)
            mission.statut = 'terminee'
            mission.date_arrivee = timezone.now()
            commentaire = request.data.get('commentaire')
            if commentaire:
                CommentaireEcart.objects.create(
                    mission=mission,
                    utilisateur=request.user.profile,
                    commentaire=commentaire
                )
            mission.save()
            logger.info(f"Mission {mission.id} terminée: statut={mission.statut}, reponse_conducteur={mission.reponse_conducteur}")
            return Response({'message': 'Mission terminée'}, status=status.HTTP_200_OK)
        except Driver.DoesNotExist:
            return Response({'error': 'Conducteur non trouvé'}, status=status.HTTP_404_NOT_FOUND)

class ExpenseViewSet(viewsets.ModelViewSet):
    queryset = Expense.objects.all()
    serializer_class = ExpenseSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_vehicle(self, request):
        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response({'error': 'vehicle_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        expenses = Expense.objects.filter(vehicle_id=vehicle_id)
        serializer = self.get_serializer(expenses, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        expense_type = request.query_params.get('type')
        if not expense_type:
            return Response({'error': 'type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        expenses = Expense.objects.filter(type=expense_type)
        serializer = self.get_serializer(expenses, many=True)
        return Response(serializer.data)

class FinancialReportViewSet(viewsets.ModelViewSet):
    queryset = FinancialReport.objects.all()
    serializer_class = FinancialReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['post'])
    def generate_report(self, request):
        vehicle_id = request.data.get('vehicle_id')
        date_debut = request.data.get('date_debut')
        date_fin = request.data.get('date_fin')

        if not all([vehicle_id, date_debut, date_fin]):
            return Response({'error': 'vehicle_id, date_debut, and date_fin are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            vehicle = Vehicle.objects.get(id=vehicle_id)
        except Vehicle.DoesNotExist:
            return Response({'error': 'Vehicle not found'}, status=status.HTTP_404_NOT_FOUND)

        total_carburant = Expense.objects.filter(
            vehicle=vehicle, type='carburant',
            date__range=[date_debut, date_fin]
        ).aggregate(Sum('montant'))['montant__sum'] or 0

        total_entretien = Entretien.objects.filter(
            vehicle=vehicle,
            date_entretien__range=[date_debut, date_fin]
        ).aggregate(Sum('cout'))['cout__sum'] or 0

        total_peages = Expense.objects.filter(
             vehicle=vehicle, type='peage',
             date__range=[date_debut, date_fin]
        ).aggregate(Sum('montant'))['montant__sum'] or 0

        total_amendes = Expense.objects.filter(
             vehicle=vehicle, type='amende',
             date__range=[date_debut, date_fin]
        ).aggregate(Sum('montant'))['montant__sum'] or 0

        total_autre = Expense.objects.filter(
             vehicle=vehicle, type='autre',
             date__range=[date_debut, date_fin]
        ).aggregate(Sum('montant'))['montant__sum'] or 0

        fuel_logs_in_period = FuelLog.objects.filter(
            vehicle=vehicle,
            date__range=[date_debut, date_fin]
        ).order_by('date', 'kilometrage')

        kilometrage_debut = fuel_logs_in_period.first().kilometrage if fuel_logs_in_period.exists() else vehicle.kilometrage
        kilometrage_fin = fuel_logs_in_period.last().kilometrage if fuel_logs_in_period.exists() else vehicle.kilometrage
        
        total_litres = fuel_logs_in_period.aggregate(Sum('litres'))['litres__sum'] or 0
        kilometrage_parcouru = kilometrage_fin - kilometrage_debut
        consommation_moyenne = (total_litres * 100) / kilometrage_parcouru if kilometrage_parcouru > 0 else 0

        report = FinancialReport.objects.create(
            vehicle=vehicle,
            date_debut=date_debut,
            date_fin=date_fin,
            total_carburant=total_carburant,
            total_entretien=total_entretien,
            total_peages=total_peages,
            total_amendes=total_amendes,
            total_autre=total_autre,
            kilometrage_debut=kilometrage_debut,
            kilometrage_fin=kilometrage_fin,
            consommation_moyenne=consommation_moyenne
        )

        serializer = self.get_serializer(report)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class DocumentAdministratifViewSet(viewsets.ModelViewSet):
    queryset = DocumentAdministratif.objects.all()
    serializer_class = DocumentAdministratifSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_vehicle(self, request):
        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response({'error': 'vehicle_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        documents = DocumentAdministratif.objects.filter(vehicle_id=vehicle_id)
        serializer = self.get_serializer(documents, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        document_type = request.query_params.get('type')
        if not document_type:
            return Response({'error': 'type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        documents = DocumentAdministratif.objects.filter(type_document=document_type)
        serializer = self.get_serializer(documents, many=True)
        return Response(serializer.data)

class EntretienViewSet(viewsets.ModelViewSet):
    queryset = Entretien.objects.all()
    serializer_class = EntretienSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_vehicle(self, request):
        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response({'error': 'vehicle_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        entretiens = Entretien.objects.filter(vehicle_id=vehicle_id)
        serializer = self.get_serializer(entretiens, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        entretien_type = request.query_params.get('type')
        if not entretien_type:
            return Response({'error': 'type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        entretiens = Entretien.objects.filter(type_entretien=entretien_type)
        serializer = self.get_serializer(entretiens, many=True)
        return Response(serializer.data)

class RapportViewSet(viewsets.ModelViewSet):
    queryset = Rapport.objects.all()
    serializer_class = RapportSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        rapport_type = request.query_params.get('type')
        if not rapport_type:
            return Response({'error': 'type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        rapports = Rapport.objects.filter(type_rapport=rapport_type)
        serializer = self.get_serializer(rapports, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_auteur(self, request):
        auteur_id = request.query_params.get('auteur_id')
        if not auteur_id:
            return Response({'error': 'auteur_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        rapports = Rapport.objects.filter(auteur_id=auteur_id)
        serializer = self.get_serializer(rapports, many=True)
        return Response(serializer.data)

class CommentaireEcartViewSet(viewsets.ModelViewSet):
    queryset = CommentaireEcart.objects.all()
    serializer_class = CommentaireEcartSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_mission(self, request):
        mission_id = request.query_params.get('mission_id')
        if not mission_id:
            return Response({'error': 'mission_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        commentaires = CommentaireEcart.objects.filter(mission_id=mission_id)
        serializer = self.get_serializer(commentaires, many=True)
        return Response(serializer.data)

class HistoriqueViewSet(viewsets.ModelViewSet):
    queryset = Historique.objects.all()
    serializer_class = HistoriqueSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_vehicle(self, request):
        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response({'error': 'vehicle_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        historiques = Historique.objects.filter(vehicle_id=vehicle_id)
        serializer = self.get_serializer(historiques, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_evenement(self, request):
        evenement_type = request.query_params.get('type')
        if not evenement_type:
            return Response({'error': 'type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        historiques = Historique.objects.filter(evenement=evenement_type)
        serializer = self.get_serializer(historiques, many=True)
        return Response(serializer.data)

class UserInfoView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = user.profile

        user_data = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'profile_id': profile.id,
            'role': profile.role,
            'telephone': profile.telephone,
            'adresse': profile.adresse,
        }
        return Response(user_data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@csrf_exempt
def send_alert_email(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            to_email = data.get('to')
            subject = data.get('subject')
            body = data.get('body')

            if not all([to_email, subject, body]):
                return JsonResponse({
                    'error': 'Tous les champs sont requis'
                }, status=400)

            send_mail(
                subject=subject,
                message='',
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[to_email],
                html_message=body,
                fail_silently=False,
            )

            return JsonResponse({
                'message': 'Email envoyé avec succès'
            }, status=200)

        except Exception as e:
            return JsonResponse({
                'error': str(e)
            }, status=500)

    return JsonResponse({
        'error': 'Méthode non autorisée'
    }, status=405)

class ManagerViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.filter(role='gestionnaire')
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        user_data = request.data.get('user', {})
        telephone = request.data.get('telephone', '')
        adresse = request.data.get('adresse', '')
        photo = request.data.get('photo', None)
        password = user_data.get('password')
        if not password:
            return Response({'error': 'Le mot de passe est requis.'}, status=400)
        user = User.objects.create_user(
            username=user_data.get('username'),
            email=user_data.get('email'),
            password=password,
            first_name=user_data.get('first_name', ''),
            last_name=user_data.get('last_name', '')
        )
        group = Group.objects.get(name='gestionnaire')
        user.groups.add(group)
        profile = UserProfile.objects.get(user=user)
        profile.telephone = telephone
        profile.adresse = adresse
        profile.role = 'gestionnaire'
        if photo:
            profile.photo = photo
        profile.save()
        serializer = self.get_serializer(profile)
        return Response(serializer.data, status=201)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        user = instance.user
        self.perform_destroy(instance)
        user.delete()
        return Response(status=204)

class PositionListCreateAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        driver_id = request.GET.get('driver')
        if not driver_id:
            return Response({'error': 'driver est requis'}, status=400)
        positions = Position.objects.filter(driver_id=driver_id).order_by('-timestamp')
        serializer = PositionSerializer(positions, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = PositionSerializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            print("[ERROR] Position serializer errors:", serializer.errors)
            return Response(serializer.errors, status=400)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

@api_view(['GET'])
def available_vehicles(request):
    date_debut = request.GET.get('date_debut')
    date_fin = request.GET.get('date_fin')
    if not date_debut or not date_fin:
        return Response({'error': 'date_debut et date_fin requis'}, status=400)
    date_debut = parse_datetime(date_debut)
    date_fin = parse_datetime(date_fin)
    if not date_debut or not date_fin:
        return Response({'error': 'Format de date invalide'}, status=400)
    missions = Mission.objects.filter(date_depart__lt=date_fin, date_arrivee__gt=date_debut)
    vehicules_occupes = missions.values_list('vehicle_id', flat=True)
    vehicules_dispos = Vehicle.objects.exclude(id__in=vehicules_occupes)
    serializer = VehicleSerializer(vehicules_dispos, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def available_drivers(request):
    date_debut = request.GET.get('date_debut')
    date_fin = request.GET.get('date_fin')
    if not date_debut or not date_fin:
        return Response({'error': 'date_debut et date_fin requis'}, status=400)
    date_debut = parse_datetime(date_debut)
    date_fin = parse_datetime(date_fin)
    if not date_debut or not date_fin:
        return Response({'error': 'Format de date invalide'}, status=400)
    missions = Mission.objects.filter(date_depart__lt=date_fin, date_arrivee__gt=date_debut)
    conducteurs_occupes = missions.values_list('driver_id', flat=True)
    conducteurs_dispos = Driver.objects.exclude(id__in=conducteurs_occupes)
    serializer = DriverSerializer(conducteurs_dispos, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_profile_me(request):
    user = request.user
    profile = getattr(user, 'profile', None)
    if not profile:
        return Response({'error': 'Profil utilisateur introuvable.'}, status=404)
    return Response(UserProfileSerializer(profile).data)

class LastPositionAPIView(RetrieveAPIView):
    serializer_class = PositionSerializer
    permission_classes = [IsAuthenticated]

    def get(self, accomplishing, *args, **kwargs):
        driver_id = self.kwargs['driver_id']
        position = Position.objects.filter(driver_id=driver_id).order_by('-timestamp').first()
        if not position:
            return Response({'detail': 'Aucune position trouvée pour ce conducteur.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = self.get_serializer(position)
        return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    try:
        total_vehicles = Vehicle.objects.count()
        active_vehicles = Vehicle.objects.filter(actif=True).count()
        
        total_drivers = Driver.objects.count()
        active_drivers = Driver.objects.filter(statut='actif').count()
        
        total_missions = Mission.objects.count()
        pending_missions = Mission.objects.filter(statut='en_attente').count()
        active_missions = Mission.objects.filter(statut='en_cours').count()
        
        total_alerts = Alert.objects.count()
        critical_alerts = Alert.objects.filter(niveau='critique', resolue=False).count()
        
        from datetime import datetime, timedelta
        thirty_days_ago = datetime.now() - timedelta(days=30)
        
        recent_expenses = Expense.objects.filter(date__gte=thirty_days_ago)
        total_recent_expenses = sum(expense.montant for expense in recent_expenses)
        
        recent_fuel = FuelLog.objects.filter(date__gte=thirty_days_ago)
        total_recent_fuel = sum(fuel.cout for fuel in recent_fuel)
        
        return Response({
            'vehicles': {
                'total': total_vehicles,
                'active': active_vehicles
            },
            'drivers': {
                'total': total_drivers,
                'active': active_drivers
            },
            'missions': {
                'total': total_missions,
                'pending': pending_missions,
                'active': active_missions
            },
            'alerts': {
                'total': total_alerts,
                'critical Ascertainable': critical_alerts
            },
            'finances': {
                'recent_expenses': float(total_recent_expenses),
                'recent_fuel': float(total_recent_fuel),
                'period_days': 30
            }
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_activities(request):
    try:
        recent_missions = Mission.objects.order_by('-date_depart')[:10]
        mission_data = []
        for mission in recent_missions:
            mission_data.append({
                'id': mission.id,
                'code': mission.code,
                'vehicle': f"{mission.vehicle.marque} {mission.vehicle.modele}",
                'driver': mission.driver.user_profile.user.username,
                'status': mission.statut,
                'date': mission.date_depart,
                'distance': mission.distance_km
            })
        
        recent_alerts = Alert.objects.order_by('-date_alerte')[:10]
        alert_data = []
        for alert in recent_alerts:
            alert_data.append({
                'id': alert.id,
                'code': alert.code,
                'type': alert.type_alerte,
                'message': alert.message,
                'niveau': alert.niveau,
                'date': alert.date_alerte,
                'resolue': alert.resolue
            })
        
        recent_expenses = Expense.objects.order_by('-date')[:10]
        expense_data = []
        for expense in recent_expenses:
            expense_data.append({
                'id': expense.id,
                'vehicle': f"{expense.vehicle.marque} {expense.vehicle.modele}",
                'type': expense.type,
                'montant': float(expense.montant),
                'date': expense.date,
                'description': expense.description
            })
        
        return Response({
            'missions': mission_data,
            'alerts': alert_data,
            'expenses': expense_data
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def global_search(request):
    query = request.GET.get('q', '').strip()
    if not query or len(query) < 2:
        return Response({'error': 'La recherche doit contenir au moins 2 caractères'}, status=400)
    
    try:
        results = {
            'vehicles': [],
            'drivers': [],
            'missions': []
        }
        
        vehicles = Vehicle.objects.filter(
            models.Q(marque__icontains=query) |
            models.Q(modele__icontains=query) |
            models.Q(immatriculation__icontains=query) |
            models.Q(numero_chassis__icontains=query)
        )[:5]
        
        for vehicle in vehicles:
            results['vehicles'].append({
                'id': vehicle.id,
                'marque': vehicle.marque,
                'modele': vehicle.modele,
                'immatriculation': vehicle.immatriculation,
                'type': 'vehicle'
            })
        
        drivers = Driver.objects.filter(
            models.Q(user_profile__user__username__icontains=query) |
            models.Q(user_profile__user__email__icontains=query) |
            models.Q(numero_permis__icontains=query)
        )[:5]
        
        for driver in drivers:
            results['drivers'].append({
                'id': driver.id,
                'username': driver.user_profile.user.username,
                'email': driver.user_profile.user.email,
                'numero_permis': driver.numero_permis,
                'type': 'driver'
            })
        
        missions = Mission.objects.filter(
            models.Q(code__icontains=query) |
            models.Q(raison__icontains=query) |
            models.Q(lieu_depart__icontains=query) |
            models.Q(lieu_arrivee__icontains=query)
        )[:5]
        
        for mission in missions:
            results['missions'].append({
                'id': mission.id,
                'code': mission.code,
                'raison': mission.raison,
                'statut': mission.statut,
                'date_depart': mission.date_depart,
                'type': 'mission'
            })
        
        return Response(results)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def all_drivers_positions(request):
    drivers = Driver.objects.all()
    result = []
    
    for driver in drivers:
        last_position = Position.objects.filter(driver=driver).order_by('-timestamp').first()
        
        is_online = False
        if last_position:
            time_diff = timezone.now() - last_position.timestamp
            is_online = time_diff.total_seconds() < 300
        
        driver_data = {
            'id': driver.id,
            'username': driver.user_profile.user.username if driver.user_profile else 'Inconnu',
            'first_name': driver.user_profile.user.first_name if driver.user_profile and driver.user_profile.user else '',
            'last_name': driver.user_profile.user.last_name if driver.user_profile and driver.user_profile.user else '',
            'is_online': is_online,
            'last_position': {
                'latitude': float(last_position.latitude) if last_position else None,
                'longitude': float(last_position.longitude) if last_position else None,
                'timestamp': last_position.timestamp if last_position else None,
            } if last_position else None
        }
        result.append(driver_data)
    
    return Response(result)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def driver_trips_history(request, driver_id):
    try:
        driver = Driver.objects.get(id=driver_id)
    except Driver.DoesNotExist:
        return Response({'error': 'Conducteur non trouvé'}, status=404)
    
    missions = Mission.objects.filter(driver=driver).order_by('-date_depart')
    
    trips_data = []
    for mission in missions:
        trip_data = {
            'id': mission.id,
            'raison': mission.raison,
            'lieu_depart': mission.lieu_depart,
            'lieu_arrivee': mission.lieu_arrivee,
            'date_depart': mission.date_depart,
            'date_arrivee': mission.date_arrivee,
            'statut': mission.statut,
            'distance_km': mission.distance_km,
        }
        trips_data.append(trip_data)
    
    return Response(trips_data)

# -----------------------------
# Google Places Proxy Endpoints
# -----------------------------

def _require_requests():
    if requests is None:
        raise RuntimeError("Le module 'requests' n'est pas installé. Ajoutez-le à requirements.txt et réinstallez.")

def _google_api_key():
    # Priorité aux variables d'environnement
    key = os.environ.get('GOOGLE_MAPS_API_KEY') or getattr(settings, 'GOOGLE_MAPS_API_KEY', None)
    if not key:
        raise RuntimeError("Clé Google Maps absente. Définissez GOOGLE_MAPS_API_KEY dans l'env ou settings.")
    return key

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def places_autocomplete(request):
    """Proxy pour /place/autocomplete/json afin d'éviter CORS côté Web."""
    _require_requests()
    key = _google_api_key()
    query = request.GET.get('input', '').strip()
    language = request.GET.get('language', 'fr')
    components = request.GET.get('components', None)
    types = request.GET.get('types', 'geocode')

    if len(query) < 2:
        return Response({'predictions': []})

    params = {
        'input': query,
        'key': key,
        'language': language,
        'types': types,
    }
    if components:
        params['components'] = components

    url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
    r = requests.get(url, params=params, timeout=10)
    return Response(r.json(), status=r.status_code)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def places_details(request):
    """Proxy pour /place/details/json (retourne geometry)."""
    _require_requests()
    key = _google_api_key()
    place_id = request.GET.get('place_id')
    language = request.GET.get('language', 'fr')
    fields = request.GET.get('fields', 'geometry')
    if not place_id:
        return Response({'error': 'place_id requis'}, status=400)
    params = {
        'place_id': place_id,
        'key': key,
        'language': language,
        'fields': fields,
    }
    url = 'https://maps.googleapis.com/maps/api/place/details/json'
    r = requests.get(url, params=params, timeout=10)
    return Response(r.json(), status=r.status_code)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def places_distance(request):
    """Proxy pour Distance Matrix."""
    _require_requests()
    key = _google_api_key()
    origins = request.GET.get('origins')
    destinations = request.GET.get('destinations')
    language = request.GET.get('language', 'fr')
    units = request.GET.get('units', 'metric')
    if not origins or not destinations:
        return Response({'error': 'origins et destinations requis'}, status=400)
    params = {
        'origins': origins,
        'destinations': destinations,
        'key': key,
        'language': language,
        'units': units,
    }
    url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
    r = requests.get(url, params=params, timeout=10)
    return Response(r.json(), status=r.status_code)