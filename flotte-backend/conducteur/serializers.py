from rest_framework import serializers
from fleet.models import Mission
from .models import PointGPS
from fleet.serializers import VehicleSerializer, DriverSerializer

class PointGPSSerializer(serializers.ModelSerializer):
    class Meta:
        model = PointGPS
        fields = ['id', 'mission', 'latitude', 'longitude', 'timestamp']

class MissionSerializer(serializers.ModelSerializer):
    vehicle_details = VehicleSerializer(source='vehicle', read_only=True)
    driver_details = DriverSerializer(source='driver', read_only=True)

    class Meta:
        model = Mission
        fields = [
            'id',
            'code',
            'vehicle',
            'vehicle_details',
            'driver',
            'driver_details',
            'date_depart',
            'date_arrivee',
            'lieu_depart',
            'lieu_arrivee',
            'distance_km',
            'raison',
            'statut',
            'reponse_conducteur',
        ]
        read_only_fields = ['distance_parcourue', 'created_at', 'updated_at', 'statut'] 