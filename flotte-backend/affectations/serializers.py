from rest_framework import serializers
from fleet.serializers import VehicleSerializer, DriverSerializer
from .models import Affectation

class AffectationSerializer(serializers.ModelSerializer):
    vehicule_details = VehicleSerializer(source='vehicule', read_only=True)
    conducteur_details = DriverSerializer(source='conducteur', read_only=True)
    duree = serializers.IntegerField(read_only=True)
    distance_parcourue = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        read_only=True,
        required=False
    )

    class Meta:
        model = Affectation
        fields = [
            'id',
            'vehicule',
            'vehicule_details',
            'conducteur',
            'conducteur_details',
            'date_debut',
            'date_fin',
            'statut',
            'type_mission',
            'commentaire',
            'kilometrage_initial',
            'kilometrage_final',
            'created_at',
            'updated_at',
            'duree',
            'distance_parcourue'
        ]
        read_only_fields = ['created_at', 'updated_at', 'duree', 'distance_parcourue']

    def validate(self, data):
        # Vérifier les dates
        if data.get('date_fin') and data.get('date_debut'):
            if data['date_fin'] <= data['date_debut']:
                raise serializers.ValidationError(
                    "La date de fin doit être postérieure à la date de début"
                )

        # Vérifier les kilométrages
        if data.get('kilometrage_final') and data.get('kilometrage_initial'):
            if data['kilometrage_final'] < data['kilometrage_initial']:
                raise serializers.ValidationError(
                    "Le kilométrage final ne peut pas être inférieur au kilométrage initial"
                )

        # Vérifier le statut et le kilométrage final
        if data.get('statut') == 'terminee' and not data.get('kilometrage_final'):
            raise serializers.ValidationError(
                "Le kilométrage final est requis pour une affectation terminée"
            )

        return data 