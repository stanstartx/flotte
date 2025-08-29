from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import Affectation
from .serializers import AffectationSerializer
from fleet.models import Vehicle, Driver

# Create your views here.

class AffectationViewSet(viewsets.ModelViewSet):
    queryset = Affectation.objects.all()
    serializer_class = AffectationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Affectation.objects.all()
        
        # Filtrage par statut
        statut = self.request.query_params.get('statut', None)
        if statut:
            queryset = queryset.filter(statut=statut)
        
        # Recherche
        search = self.request.query_params.get('q', None)
        if search:
            queryset = queryset.filter(
                Q(vehicule__immatriculation__icontains=search) |
                Q(conducteur__user_profile__user__username__icontains=search)
            )
        
        return queryset

    @action(detail=False, methods=['get'])
    def search(self, request):
        query = request.query_params.get('q', '')
        if not query:
            return Response(
                {'error': 'Le paramètre de recherche est requis'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        affectations = self.get_queryset().filter(
            Q(vehicule__immatriculation__icontains=query) |
            Q(conducteur__user_profile__user__username__icontains=query)
        )
        
        serializer = self.get_serializer(affectations, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def terminer(self, request, pk=None):
        affectation = self.get_object()
        kilometrage_final = request.data.get('kilometrage_final')
        
        if not kilometrage_final:
            return Response(
                {'error': 'Le kilométrage final est requis'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            kilometrage_final = float(kilometrage_final)
            if hasattr(affectation, 'kilometrage_initial') and kilometrage_final < affectation.kilometrage_initial:
                return Response(
                    {'error': 'Le kilométrage final ne peut pas être inférieur au kilométrage initial'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except ValueError:
            return Response(
                {'error': 'Le kilométrage final doit être un nombre valide'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        affectation.kilometrage_final = kilometrage_final
        affectation.statut = 'terminee'
        affectation.save()
        
        serializer = self.get_serializer(affectation)
        return Response(serializer.data)
