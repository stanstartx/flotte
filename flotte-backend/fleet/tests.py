import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from fleet.models import Vehicle, Driver, Maintenance, Mission
from django.utils import timezone
from datetime import timedelta
from rest_framework_simplejwt.tokens import RefreshToken

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
def authenticated_client(api_client, user):
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client

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
class TestVehicle:
    def test_create_vehicle(self, vehicle):
        assert vehicle.marque == 'Renault'
        assert vehicle.modele == 'Clio'
        assert vehicle.immatriculation == 'AB-123-CD'
        assert vehicle.kilometrage == 50000.0
        assert vehicle.actif is True

    def test_vehicle_str(self, vehicle):
        assert str(vehicle) == 'Renault Clio - AB-123-CD'

@pytest.mark.django_db
class TestDriver:
    def test_create_driver(self, driver):
        assert driver.permis == 'B'
        assert driver.telephone == '0123456789'
        assert driver.user.email == 'test@example.com'

    def test_driver_str(self, driver):
        assert str(driver) == driver.user.username

@pytest.mark.django_db
class TestVehicleAPI:
    def test_list_vehicles(self, authenticated_client, vehicle):
        url = reverse('vehicle-list')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['marque'] == 'Renault'

    def test_create_vehicle(self, authenticated_client):
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
        response = authenticated_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert Vehicle.objects.count() == 1
        assert Vehicle.objects.get().marque == 'Peugeot'

@pytest.mark.django_db
class TestDriverAPI:
    def test_list_drivers(self, authenticated_client, driver):
        url = reverse('driver-list')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['permis'] == 'B'

    def test_create_driver(self, authenticated_client, user):
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
        response = authenticated_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert Driver.objects.count() == 1
        assert Driver.objects.get().permis == 'C'
