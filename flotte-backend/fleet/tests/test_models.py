import pytest
from django.utils import timezone
from datetime import timedelta
from fleet.models import Vehicle, Driver, Maintenance, Mission
from django.contrib.auth.models import User

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
        assert str(driver) == 'testuser'

@pytest.mark.django_db
class TestMaintenance:
    def test_create_maintenance(self, vehicle):
        maintenance = Maintenance.objects.create(
            vehicle=vehicle,
            type_entretien='Vidange',
            date=timezone.now(),
            cout=100.0,
            commentaire='Vidange d\'huile'
        )
        assert maintenance.type_entretien == 'Vidange'
        assert maintenance.cout == 100.0
        assert maintenance.commentaire == 'Vidange d\'huile'

    def test_maintenance_str(self, vehicle):
        maintenance = Maintenance.objects.create(
            vehicle=vehicle,
            type_entretien='Vidange',
            date=timezone.now(),
            cout=100.0,
            commentaire='Vidange d\'huile'
        )
        assert 'Vidange' in str(maintenance)

@pytest.mark.django_db
class TestMission:
    def test_create_mission(self, vehicle, driver):
        mission = Mission.objects.create(
            vehicle=vehicle,
            driver=driver,
            description='Livraison',
            date_debut=timezone.now(),
            date_fin=timezone.now() + timedelta(hours=2),
            statut='prévu'
        )
        assert mission.description == 'Livraison'
        assert mission.statut == 'prévu'

    def test_mission_str(self, vehicle, driver):
        mission = Mission.objects.create(
            vehicle=vehicle,
            driver=driver,
            description='Livraison',
            date_debut=timezone.now(),
            date_fin=timezone.now() + timedelta(hours=2),
            statut='prévu'
        )
        assert 'Livraison' in str(mission) 