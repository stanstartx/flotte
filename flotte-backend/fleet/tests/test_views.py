import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from fleet.models import Vehicle, Driver, Maintenance, Mission
from django.utils import timezone
from datetime import timedelta

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def user():
    return User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='testpass123'
    )

@pytest.fixture
def driver(user):
    return Driver.objects.create(
        user=user,
        permis='B',
        telephone='0123456789'
    )

@pytest.fixture
def vehicle():
    return Vehicle.objects.create(
        marque='Renault',
        modele='Clio',
        immatriculation='AB-123-CD',
        kilometrage=50000.0,
        assurance_expiration=timezone.now() + timedelta(days=365),
        visite_technique=timezone.now() + timedelta(days=180),
        actif=True
    )

@pytest.mark.django_db
class TestVehicleAPI:
    def test_list_vehicles(self, api_client, vehicle):
        url = reverse('vehicle-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['marque'] == 'Renault'

    def test_create_vehicle(self, api_client):
        url = reverse('vehicle-list')
        data = {
            'marque': 'Peugeot',
            'modele': '208',
            'immatriculation': 'EF-456-GH',
            'kilometrage': 0.0,
            'assurance_expiration': (timezone.now() + timedelta(days=365)).isoformat(),
            'visite_technique': (timezone.now() + timedelta(days=180)).isoformat(),
            'actif': True
        }
        response = api_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert Vehicle.objects.count() == 1
        assert Vehicle.objects.get().marque == 'Peugeot'

    def test_retrieve_vehicle(self, api_client, vehicle):
        url = reverse('vehicle-detail', args=[vehicle.id])
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data['marque'] == 'Renault'

@pytest.mark.django_db
class TestDriverAPI:
    def test_list_drivers(self, api_client, driver):
        url = reverse('driver-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['permis'] == 'B'

    def test_create_driver(self, api_client, user):
        url = reverse('driver-list')
        data = {
            'user': {
                'username': 'newdriver',
                'email': 'new@example.com',
                'password': 'newpass123'
            },
            'permis': 'C',
            'telephone': '9876543210'
        }
        response = api_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert Driver.objects.count() == 1
        assert Driver.objects.get().permis == 'C'

@pytest.mark.django_db
class TestMaintenanceAPI:
    def test_list_maintenances(self, api_client, vehicle):
        maintenance = Maintenance.objects.create(
            vehicle=vehicle,
            type_entretien='Vidange',
            date=timezone.now(),
            cout=100.0,
            commentaire='Vidange d\'huile'
        )
        url = reverse('maintenance-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['type_entretien'] == 'Vidange'

    def test_create_maintenance(self, api_client, vehicle):
        url = reverse('maintenance-list')
        data = {
            'vehicle': vehicle.id,
            'type_entretien': 'Révision',
            'date': timezone.now().isoformat(),
            'cout': 200.0,
            'commentaire': 'Révision complète'
        }
        response = api_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert Maintenance.objects.count() == 1
        assert Maintenance.objects.get().type_entretien == 'Révision'

@pytest.mark.django_db
class TestMissionAPI:
    def test_list_missions(self, api_client, vehicle, driver):
        mission = Mission.objects.create(
            vehicle=vehicle,
            driver=driver,
            description='Livraison',
            date_debut=timezone.now(),
            date_fin=timezone.now() + timedelta(hours=2),
            statut='prévu'
        )
        url = reverse('mission-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['description'] == 'Livraison'

    def test_create_mission(self, api_client, vehicle, driver):
        url = reverse('mission-list')
        data = {
            'vehicle': vehicle.id,
            'driver': driver.id,
            'description': 'Transport',
            'date_debut': timezone.now().isoformat(),
            'date_fin': (timezone.now() + timedelta(hours=2)).isoformat(),
            'statut': 'prévu'
        }
        response = api_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert Mission.objects.count() == 1
        assert Mission.objects.get().description == 'Transport' 