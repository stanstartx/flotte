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
from rest_framework.parsers import MultiPartParser, FormParser


class UserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [FormParser, MultiPartParser]

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

    @action(detail=True, methods=['get'])
    def user_info(self, request, pk=None):
        driver = self.get_object()
        return Response(UserProfileSerializer(driver.user_profile).data)

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        data = dict(data)  # QueryDict -> dict (toutes les valeurs sont des listes)
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
        serializer = self.get_serializer(data=data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            return Response(serializer.errors, status=400)
        # Création du conducteur
        instance = serializer.save()
        # Gestion de la photo
        photo = request.FILES.get('photo')
        if photo and hasattr(instance, 'user_profile'):
            instance.user_profile.photo = photo
            instance.user_profile.save()
        # Retourne la réponse avec le contexte request pour l'URL absolue de la photo
        return Response(self.get_serializer(instance, context={'request': request}).data, status=status.HTTP_201_CREATED)


class VehicleViewSet(viewsets.ModelViewSet):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['get'])
    def details_complets(self, request, pk=None):
        vehicle = self.get_object()
        data = self.get_serializer(vehicle).data
        
        # Ajouter les données des maintenances
        maintenances = Maintenance.objects.filter(vehicle=vehicle).order_by('-date')
        data['maintenances'] = MaintenanceSerializer(maintenances, many=True).data
        
        # Ajouter les données des pleins de carburant
        pleins = FuelLog.objects.filter(vehicle=vehicle).order_by('-date')
        data['pleins'] = FuelLogSerializer(pleins, many=True).data
        
        # Ajouter les données des dépenses
        depenses = Expense.objects.filter(vehicle=vehicle).order_by('-date')
        data['depenses'] = ExpenseSerializer(depenses, many=True).data
        
        # Ajouter les données des missions
        missions = Mission.objects.filter(vehicle=vehicle).order_by('-date_debut')
        data['missions'] = MissionSerializer(missions, many=True).data
        
        return Response(data)

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        total_vehicules = Vehicle.objects.count()
        vehicules_actifs = Vehicle.objects.filter(actif=True).count()
        total_kilometrage = Vehicle.objects.aggregate(total=Sum('kilometrage'))['total'] or 0
        
        # Calculer les dépenses totales
        depenses = Expense.objects.all()
        total_depenses = depenses.aggregate(total=Sum('montant'))['total'] or 0
        
        # Calculer la consommation moyenne globale
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
        
        # Récupérer toutes les activités du véhicule
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
        """Génère automatiquement les alertes basées sur les données du système"""
        today = timezone.now().date()
        
        # Supprimer les anciennes alertes non résolues
        Alert.objects.filter(resolue=False).delete()
        
        # Alertes pour les véhicules
        vehicles = Vehicle.objects.all()
        for vehicle in vehicles:
            # Alerte pour l'assurance
            if vehicle.assurance_expiration and (vehicle.assurance_expiration - today).days <= 30:
                Alert.objects.create(
                    vehicle=vehicle,
                    type_alerte='assurance',
                    message=f"L'assurance du véhicule {vehicle} expire le {vehicle.assurance_expiration}",
                    niveau='warning' if (vehicle.assurance_expiration - today).days > 7 else 'critique'
                )
            
            # Alerte pour la visite technique
            if vehicle.visite_technique and (vehicle.visite_technique - today).days <= 30:
                Alert.objects.create(
                    vehicle=vehicle,
                    type_alerte='controle_technique',
                    message=f"La visite technique du véhicule {vehicle} expire le {vehicle.visite_technique}",
                    niveau='warning' if (vehicle.visite_technique - today).days > 7 else 'critique'
                )

        # Alertes pour les conducteurs
        drivers = Driver.objects.filter(statut='actif')  # Ne prendre que les conducteurs actifs
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

        # Alertes pour les documents administratifs
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
        """Endpoint pour générer les alertes"""
        self.generate_alerts()
        return Response({'message': 'Alertes générées avec succès'})

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Marquer une alerte comme résolue"""
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
        # Alertes liées au conducteur
        alertes_conducteur = Alert.objects.filter(driver=conducteur, resolue=False)
        # Véhicules affectés ou en mission future
        maintenant = timezone.now()
        vehicules_affectes = Affectation.objects.filter(driver=conducteur, statut='actif').values_list('vehicle_id', flat=True)
        vehicules_missions = Mission.objects.filter(driver=conducteur, date_depart__gte=maintenant).values_list('vehicle_id', flat=True)
        vehicules_ids = set(list(vehicules_affectes) + list(vehicules_missions))
        alertes_vehicules = Alert.objects.filter(vehicle_id__in=vehicules_ids, resolue=False)
        alertes = list(alertes_conducteur) + list(alertes_vehicules)
        # Supprimer les doublons éventuels
        alertes = {a.id: a for a in alertes}.values()
        serializer = self.get_serializer(alertes, many=True)
        return Response(serializer.data)


class MissionViewSet(viewsets.ModelViewSet):
    queryset = Mission.objects.all()
    serializer_class = MissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        now = timezone.now()
        for mission in queryset:
            if mission.date_arrivee and mission.date_arrivee < now:
                mission.statut = 'terminee'
            elif mission.date_depart > now:
                mission.statut = 'planifiee'
            elif mission.date_depart <= now <= (mission.date_arrivee or now):
                mission.statut = 'en_cours'
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


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

        # Calculate financial data
        total_carburant = Expense.objects.filter(
            vehicle=vehicle, type='carburant',
            date__range=[date_debut, date_fin]
        ).aggregate(Sum('montant'))['montant__sum'] or 0

        total_entretien = Entretien.objects.filter(
            vehicle=vehicle,
            date_entretien__range=[date_debut, date_fin]
        ).aggregate(Sum('cout'))['cout__sum'] or 0 # Assuming 'cout' field in Entretien

        # Add other expense types as needed (peage, amende, autre)
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


        # Calculate mileage
        # This requires tracking mileage at the start and end of the report period
        # For simplicity, let's assume we can get min/max mileage from FuelLogs or other relevant records
        # A more robust solution would involve dedicated mileage tracking entries
        fuel_logs_in_period = FuelLog.objects.filter(
            vehicle=vehicle,
            date__range=[date_debut, date_fin]
        ).order_by('date', 'kilometrage')

        kilometrage_debut = fuel_logs_in_period.first().kilometrage if fuel_logs_in_period.exists() else vehicle.kilometrage # Approximation
        kilometrage_fin = fuel_logs_in_period.last().kilometrage if fuel_logs_in_period.exists() else vehicle.kilometrage # Approximation
        
        # Consider mileage from other events like Maintenance if they record it

        # Calculate average consumption
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
                message='',  # Version texte vide car nous utilisons HTML
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
        # Créer l'utilisateur
        user = User.objects.create_user(
            username=user_data.get('username'),
            email=user_data.get('email'),
            password=password,
            first_name=user_data.get('first_name', ''),
            last_name=user_data.get('last_name', '')
        )
        # Ajouter au groupe gestionnaire
        group = Group.objects.get(name='gestionnaire')
        user.groups.add(group)
        # Créer le profil
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
    # Véhicules occupés sur la période
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

    def get(self, request, *args, **kwargs):
        driver_id = self.kwargs['driver_id']
        position = Position.objects.filter(driver_id=driver_id).order_by('-timestamp').first()
        if not position:
            return Response({'detail': 'Aucune position trouvée pour ce conducteur.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = self.get_serializer(position)
        return Response(serializer.data)
