from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from fleet.models import Mission
from .models import PointGPS
from .serializers import MissionSerializer, PointGPSSerializer
from django.db.models import Q
from math import radians, cos, sin, asin, sqrt
from fleet.models import Affectation, Vehicle
from fleet.serializers import VehicleSerializer
from rest_framework.views import APIView

# Create your views here.

class MissionViewSet(viewsets.ModelViewSet):
    queryset = Mission.objects.all()
    serializer_class = MissionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Mission.objects.all()
        statut = self.request.query_params.get('statut')
        conducteur_id = self.request.query_params.get('conducteur')
        if statut:
            queryset = queryset.filter(statut=statut)
        if conducteur_id:
            queryset = queryset.filter(driver_id=conducteur_id)
        return queryset

    @action(detail=True, methods=['post'])
    def accepter(self, request, pk=None):
        mission = self.get_object()
        if mission.reponse_conducteur != 'en_attente':
            return Response({'error': 'Mission déjà traitée.'}, status=400)
        mission.reponse_conducteur = 'acceptee'
        mission.save()
        return Response(self.get_serializer(mission).data)

    @action(detail=True, methods=['post'])
    def refuser(self, request, pk=None):
        mission = self.get_object()
        if mission.reponse_conducteur != 'en_attente':
            return Response({'error': 'Mission déjà traitée.'}, status=400)
        mission.reponse_conducteur = 'refusee'
        mission.save()
        return Response(self.get_serializer(mission).data)

    @action(detail=True, methods=['post'])
    def terminer(self, request, pk=None):
        mission = self.get_object()
        if mission.statut not in ['acceptee', 'active']:
            return Response({'error': 'Mission non active.'}, status=400)
        # Calcul de la distance totale
        points = mission.points_gps.order_by('timestamp')
        total = 0.0
        last = None
        for p in points:
            if last:
                total += haversine(last.latitude, last.longitude, p.latitude, p.longitude)
            last = p
        mission.distance_parcourue = round(total, 2)
        mission.statut = 'terminee'
        mission.save()
        return Response(self.get_serializer(mission).data)

    @action(detail=False, methods=['get'])
    def historique(self, request):
        missions = self.get_queryset().filter(statut='terminee')
        serializer = self.get_serializer(missions, many=True)
        return Response(serializer.data)

class PointGPSViewSet(viewsets.ModelViewSet):
    queryset = PointGPS.objects.all()
    serializer_class = PointGPSSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            print("[ERROR] PointGPS serializer errors:", serializer.errors)
            return Response(serializer.errors, status=400)
        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class VehiculesAffectesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        try:
            conducteur = user.profile.driver
        except Exception:
            return Response({'error': 'Conducteur non trouvé.'}, status=404)
        affectations = Affectation.objects.filter(driver=conducteur, statut='actif')
        vehicules = [a.vehicle for a in affectations]
        serializer = VehicleSerializer(vehicules, many=True)
        return Response(serializer.data)

# Utilitaire pour calculer la distance entre deux points GPS (en km)
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # Rayon de la Terre en km
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return R * c
