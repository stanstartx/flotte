from rest_framework import serializers
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
from django.contrib.auth.models import User, Group
from django.core.exceptions import ObjectDoesNotExist


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'is_active', 'password']
        extra_kwargs = {'password': {'write_only': True, 'required': True}}

    def create(self, validated_data):
        email = validated_data.get("email")
        password = validated_data.pop("password", None)

        user = User(
            username=email,   # <-- username forcé = email
            email=email,
            first_name=validated_data.get("first_name", ""),
            last_name=validated_data.get("last_name", ""),
            is_active=validated_data.get("is_active", True),
        )
        if password:
            user.set_password(password)
        user.save()

        conducteur_group = Group.objects.get(name='conducteur')
        user.groups.add(conducteur_group)
        return user

    def update(self, instance, validated_data):
        if 'password' in validated_data:
            password = validated_data.pop('password')
            instance.set_password(password)
        return super().update(instance, validated_data)



class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    photo = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['id', 'user', 'telephone', 'adresse', 'photo', 'role']

    def get_photo(self, obj):
        request = self.context.get('request')
        if obj.photo:
            url = obj.photo.url
            if request is not None:
                if not url.startswith('http'):
                    return request.build_absolute_uri(url)
                return url
            if url.startswith('/'):
                return f'http://localhost:8000{url}'
            return url
        return ''

    def create(self, validated_data):
        user_data = validated_data.pop('user')
        user = UserSerializer().create(user_data)
        profile = UserProfile.objects.get(user=user)
        profile.telephone = validated_data.get('telephone', '')
        profile.adresse = validated_data.get('adresse', '')
        profile.role = 'conducteur'
        profile.save()
        return profile

    def update(self, instance, validated_data):
        if 'user' in validated_data:
            user_data = validated_data.pop('user')
            user = instance.user
            if 'email' in user_data:
                user.email = user_data['email']
                user.username = user_data['email']  # garder synchro avec username
            if 'first_name' in user_data:
                user.first_name = user_data['first_name']
            if 'last_name' in user_data:
                user.last_name = user_data['last_name']
            if 'is_active' in user_data:
                user.is_active = user_data['is_active']
            if 'password' in user_data:
                user.set_password(user_data['password'])
            user.save()

        instance.telephone = validated_data.get('telephone', instance.telephone)
        instance.adresse = validated_data.get('adresse', instance.adresse)
        instance.save()
        return instance

    def set_password(self, instance, password):
        user = instance.user
        user.set_password(password)
        user.save()
        return instance


class DriverSerializer(serializers.ModelSerializer):
    user_profile = UserProfileSerializer(read_only=True)
    user_profile_id = serializers.PrimaryKeyRelatedField(
        queryset=UserProfile.objects.all(), write_only=True, required=False
    )
    user_profile_data = UserProfileSerializer(write_only=True, required=False)

    class Meta:
        model = Driver
        fields = [
            'id', 'user_profile', 'user_profile_id', 'user_profile_data',
            'permis', 'numero_permis', 'date_expiration_permis',
            'date_naissance', 'statut', 'notes'
        ]

    def create(self, validated_data):
        user_profile = validated_data.pop('user_profile_id', None)
        user_profile_data = validated_data.pop('user_profile_data', None)

        from .models import Driver

        if user_profile:
            if hasattr(user_profile, 'driver'):
                raise serializers.ValidationError("Un conducteur existe déjà pour ce profil utilisateur.")
            return Driver.objects.create(user_profile=user_profile, **validated_data)

        elif user_profile_data:
            user_data = user_profile_data.pop('user')
            email = user_data.get('email')

            try:
                user = User.objects.get(email=email)
                user.first_name = user_data.get('first_name', user.first_name)
                user.last_name = user_data.get('last_name', user.last_name)
                user.is_active = user_data.get('is_active', user.is_active)
                if 'password' in user_data:
                    user.set_password(user_data['password'])
                user.save()
            except ObjectDoesNotExist:
                password = user_data.get('password') or 'password123'
                user = User.objects.create_user(
                    username=email,
                    email=email,
                    first_name=user_data.get('first_name', ''),
                    last_name=user_data.get('last_name', ''),
                    is_active=user_data.get('is_active', True),
                    password=password,
                )

            user_profile, created = UserProfile.objects.get_or_create(
                user=user,
                defaults={
                    'telephone': user_profile_data.get('telephone', ''),
                    'adresse': user_profile_data.get('adresse', ''),
                    'role': user_profile_data.get('role', 'conducteur'),
                }
            )
            if hasattr(user_profile, 'driver'):
                raise serializers.ValidationError("Un conducteur existe déjà pour ce profil utilisateur.")
            user_profile.telephone = user_profile_data.get('telephone', user_profile.telephone)
            user_profile.adresse = user_profile_data.get('adresse', user_profile.adresse)
            user_profile.role = user_profile_data.get('role', user_profile.role)
            user_profile.save()

            return Driver.objects.create(user_profile=user_profile, **validated_data)

        else:
            raise serializers.ValidationError("user_profile_id ou user_profile_data requis")


class VehicleSerializer(serializers.ModelSerializer):
    consommation_moyenne = serializers.FloatField(read_only=True)

    class Meta:
        model = Vehicle
        fields = '__all__'


class DocumentAdministratifSerializer(serializers.ModelSerializer):
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)

    class Meta:
        model = DocumentAdministratif
        fields = ['id', 'code', 'vehicle', 'vehicle_details', 'numero_document',
                 'type_document', 'date_emission', 'date_expiration', 'fichier']


class EntretienSerializer(serializers.ModelSerializer):
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)

    class Meta:
        model = Entretien
        fields = ['id', 'code', 'vehicle', 'vehicle_details', 'type_entretien',
                 'date_entretien', 'cout', 'commentaires', 'kilometrage', 'garage']


class AlertSerializer(serializers.ModelSerializer):
    vehicle = serializers.SerializerMethodField()
    driver = serializers.SerializerMethodField()

    class Meta:
        model = Alert
        fields = ['code', 'vehicle', 'driver', 'type_alerte', 'message', 'niveau', 'date_alerte', 'resolue']

    def get_vehicle(self, obj):
        if obj.vehicle:
            return str(obj.vehicle)
        return None

    def get_driver(self, obj):
        if obj.driver:
            return str(obj.driver)
        return None


class AffectationSerializer(serializers.ModelSerializer):
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)
    driver_details = DriverSerializer(source='driver', read_only=True)

    class Meta:
        model = Affectation
        fields = ['id', 'code', 'vehicle', 'vehicle_details', 'driver',
                 'driver_details', 'date_debut', 'date_fin', 'statut',
                 'date_affectation', 'heure_affectation']


class MissionSerializer(serializers.ModelSerializer):
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)
    driver_details = DriverSerializer(source='driver', read_only=True)

    class Meta:
        model = Mission
        fields = [
            'id', 'code', 'vehicle', 'vehicle_details', 'driver',
            'driver_details', 'date_depart', 'date_arrivee',
            'lieu_depart', 'lieu_arrivee', 'distance_km', 'raison',
            'statut', 'reponse_conducteur'
        ]

    def validate(self, data):
        driver = data.get('driver')
        vehicle = data.get('vehicle')
        date_debut = data.get('date_depart')
        date_fin = data.get('date_arrivee')
        mission_id = self.instance.id if self.instance else None

        # Vérifie le conducteur
        if driver and date_debut and date_fin:
            conflits_conducteur = Mission.objects.filter(
                driver=driver,
                date_depart__lt=date_fin,
                date_arrivee__gt=date_debut
            )
            if mission_id:
                conflits_conducteur = conflits_conducteur.exclude(id=mission_id)
            if conflits_conducteur.exists():
                raise serializers.ValidationError({'driver': "Ce conducteur est déjà en mission sur cette période."})

        # Vérifie le véhicule
        if vehicle and date_debut and date_fin:
            conflits_vehicule = Mission.objects.filter(
                vehicle=vehicle,
                date_depart__lt=date_fin,
                date_arrivee__gt=date_debut
            )
            if mission_id:
                conflits_vehicule = conflits_vehicule.exclude(id=mission_id)
            if conflits_vehicule.exists():
                raise serializers.ValidationError({'vehicle': "Ce véhicule est déjà en mission sur cette période."})

        return data


class RapportSerializer(serializers.ModelSerializer):
    auteur_details = UserProfileSerializer(source='auteur', read_only=True)

    class Meta:
        model = Rapport
        fields = ['id', 'code', 'titre', 'description', 'type_rapport',
                 'date_rapport', 'auteur', 'auteur_details', 'fichier']


class CommentaireEcartSerializer(serializers.ModelSerializer):
    mission_details = MissionSerializer(source='mission', read_only=True)
    utilisateur_details = UserProfileSerializer(source='utilisateur', read_only=True)

    class Meta:
        model = CommentaireEcart
        fields = ['id', 'code', 'mission', 'mission_details', 'utilisateur',
                 'utilisateur_details', 'commentaire', 'date_commentaire']


class HistoriqueSerializer(serializers.ModelSerializer):
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)
    utilisateur_details = UserProfileSerializer(source='utilisateur', read_only=True)

    class Meta:
        model = Historique
        fields = ['id', 'code', 'vehicle', 'vehicle_details', 'utilisateur',
                 'utilisateur_details', 'evenement', 'description',
                 'date_evenement', 'heure_evenement']


class AssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Assignment
        fields = '__all__'


class MaintenanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Maintenance
        fields = '__all__'


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = '__all__'


class FuelLogSerializer(serializers.ModelSerializer):
    prix_litre = serializers.DecimalField(max_digits=5, decimal_places=3, read_only=True)
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)
    driver_details = DriverSerializer(source='driver', read_only=True)

    class Meta:
        model = FuelLog
        fields = '__all__'


class FinancialReportSerializer(serializers.ModelSerializer):
    total_depenses = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    kilometrage_total = serializers.FloatField(read_only=True)
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)

    class Meta:
        model = FinancialReport
        fields = '__all__'


class PositionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Position
        fields = ['id', 'driver', 'latitude', 'longitude', 'timestamp']
