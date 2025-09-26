# fleet/models.py

from django.db import models
from django.contrib.auth.models import User, Group
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
import uuid

def generate_code():
    return str(uuid.uuid4())[:8].upper()

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    telephone = models.CharField(max_length=20, blank=True)
    adresse = models.TextField(blank=True)
    photo = models.ImageField(upload_to='profiles/', null=True, blank=True)
    role = models.CharField(max_length=20, choices=[
        ('admin', 'Administrateur'),
        ('gestionnaire', 'Gestionnaire'),
        ('conducteur', 'Conducteur')
    ], default='conducteur')

    def __str__(self):
        return f"{self.user.username} - {self.role}"

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()

class Vehicle(models.Model):
    TYPE_CARBURANT_CHOICES = (
        ('essence', 'Essence'),
        ('diesel', 'Diesel'),
        ('electrique', 'Électrique'),
        ('hybride', 'Hybride'),
        ('autre', 'Autre'),
    )
    marque = models.CharField(max_length=100)
    modele = models.CharField(max_length=100)
    immatriculation = models.CharField(max_length=20, unique=True)
    kilometrage = models.FloatField()
    assurance_expiration = models.DateField(null=True, blank=True)
    visite_technique = models.DateField(null=True, blank=True)
    carte_grise = models.FileField(upload_to='docs/', null=True, blank=True)
    actif = models.BooleanField(default=True)
    type_vehicule = models.CharField(
        max_length=50,
        choices=[
            ('SUV', 'SUV'),
            ('Berline', 'Berline'),
            ('Break', 'Break'),
            ('Citadine', 'Citadine'),
            ('4x4', '4x4'),
            ('Camion', 'Camion'),
            ('Camionnette', 'Camionnette')
        ],
        default='SUV'
    )
    capacite_reservoir = models.FloatField(default=0)
    date_acquisition = models.DateField(null=True, blank=True)
    prix_acquisition = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    numero_chassis = models.CharField(max_length=50, unique=True, null=True, blank=True)
    couleur = models.CharField(max_length=50, null=True, blank=True)
    photo = models.ImageField(upload_to='vehicles/', null=True, blank=True)
    notes = models.TextField(blank=True)
    traccar_id = models.CharField(
        max_length=32,
        unique=True,
        null=True,
        blank=True,
        help_text="Identifiant Traccar (ex: 960049)"
    )
    type_carburant = models.CharField(
        max_length=20,
        choices=TYPE_CARBURANT_CHOICES,
        null=True,
        blank=True,
        help_text="Type de carburant du véhicule"
    )

    def __str__(self):
        return f"{self.marque} {self.modele} - {self.immatriculation}"

    @property
    def consommation_moyenne(self):
        pleins = FuelLog.objects.filter(vehicle=self).order_by('date')
        if len(pleins) < 2:
            return 0
        total_km = pleins.last().kilometrage - pleins.first().kilometrage
        total_litres = sum(plein.litres for plein in pleins)
        if total_km == 0:
            return 0
        return (total_litres * 100) / total_km

class Driver(models.Model):
    user_profile = models.OneToOneField(UserProfile, on_delete=models.CASCADE, related_name='driver')
    permis = models.CharField(max_length=50, choices=[
        ('A', 'A - Moto'),
        ('B', 'B - Voiture'),
        ('C', 'C - Poids lourd'),
        ('D', 'D - Transport en commun'),
        ('E', 'E - Remorque'),
        ('F', 'F - Tracteur agricole'),
        ('G', 'G - Engin de chantier')
    ], default='B')
    numero_permis = models.CharField(max_length=50, unique=True)
    date_expiration_permis = models.DateField(null=True, blank=True)
    date_naissance = models.DateField(null=True, blank=True)
    statut = models.CharField(max_length=20, choices=[
        ('actif', 'Actif'),
        ('inactif', 'Inactif'),
        ('en_conge', 'En congé')
    ], default='actif')
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"{self.user_profile.user.username} - {self.numero_permis}"

@receiver(post_save, sender=Driver)
def add_driver_to_conducteur_group(sender, instance, created, **kwargs):
    if created:
        user = instance.user_profile.user
        conducteur_group, _ = Group.objects.get_or_create(name='conducteur')
        user.groups.add(conducteur_group)

class Assignment(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE)
    mission = models.CharField(max_length=255)
    date_debut = models.DateTimeField()
    date_fin = models.DateTimeField(null=True, blank=True)
    type_affectation = models.CharField(max_length=50, choices=[('temporaire', 'Temporaire'), ('permanente', 'Permanente')])

    def __str__(self):
        return f"{self.vehicle} ➝ {self.driver} ({self.mission})"

class Maintenance(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    type_entretien = models.CharField(max_length=100)
    date = models.DateField()
    cout = models.FloatField()
    commentaire = models.TextField()

    def __str__(self):
        return f"{self.vehicle} - {self.type_entretien} ({self.date})"

class Expense(models.Model):
    TYPE_CHOICES = [
        ('carburant', 'Carburant'),
        ('entretien', 'Entretien'),
        ('assurance', 'Assurance'),
        ('peage', 'Péage'),
        ('amende', 'Amende'),
        ('autre', 'Autre')
    ]

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    montant = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField()
    description = models.TextField()
    justificatif = models.FileField(upload_to='expenses/', null=True, blank=True)
    kilometrage = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"{self.vehicle} - {self.type} ({self.date})"

class FuelLog(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True)
    date = models.DateField()
    litres = models.FloatField()
    cout = models.DecimalField(max_digits=10, decimal_places=2)
    kilometrage = models.FloatField(default=0)
    prix_litre = models.DecimalField(max_digits=5, decimal_places=3, default=0)
    station = models.CharField(max_length=100, blank=True)
    commentaire = models.TextField(blank=True)

    def __str__(self):
        return f"{self.vehicle} - {self.litres}L le {self.date}"

    def save(self, *args, **kwargs):
        if self.litres > 0:
            self.prix_litre = self.cout / self.litres
        super().save(*args, **kwargs)

class Alert(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='alertes', null=True, blank=True)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='alertes', null=True, blank=True)
    type_alerte = models.CharField(max_length=50, choices=[
        ('entretien', 'Entretien à venir'),
        ('assurance', 'Assurance expirée'),
        ('controle_technique', 'Contrôle technique'),
        ('permis', 'Permis de conduire'),
        ('autre', 'Autre')
    ], default='autre')
    message = models.TextField()
    niveau = models.CharField(max_length=20, choices=[
        ('info', 'Information'),
        ('warning', 'Avertissement'),
        ('critique', 'Critique')
    ], default='info')
    date_alerte = models.DateTimeField(default=timezone.now)
    resolue = models.BooleanField(default=False)

    def __str__(self):
        if self.vehicle:
            return f"{self.type_alerte} - {self.vehicle}"
        elif self.driver:
            return f"{self.type_alerte} - {self.driver}"
        return f"{self.type_alerte} - {self.code}"

class Mission(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE)
    date_depart = models.DateTimeField(default=timezone.now)
    date_arrivee = models.DateTimeField(null=True, blank=True)
    lieu_depart = models.CharField(max_length=255, default='')
    lieu_arrivee = models.CharField(max_length=255, default='')
    depart_latitude = models.FloatField(null=True, blank=True)
    depart_longitude = models.FloatField(null=True, blank=True)
    arrivee_latitude = models.FloatField(null=True, blank=True)
    arrivee_longitude = models.FloatField(null=True, blank=True)
    distance_km = models.FloatField(default=0)
    raison = models.TextField(default='')
    statut = models.CharField(
        max_length=20,
        choices=[
            ('en_attente', 'En attente'),
            ('acceptee', 'Acceptée'),
            ('refusee', 'Refusée'),
            ('en_cours', 'En cours'),
            ('terminee', 'Terminée'),
            ('planifiee', 'Planifiée'),
        ],
        default='en_attente'
    )
    reponse_conducteur = models.CharField(
        max_length=20,
        choices=[
            ('en_attente', 'En attente'),
            ('acceptee', 'Acceptée'),
            ('refusee', 'Refusée'),
        ],
        default='en_attente',
    )

    def __str__(self):
        return f"{self.raison} ({self.date_depart.date()})"

class FinancialReport(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    date_debut = models.DateField()
    date_fin = models.DateField()
    total_carburant = models.DecimalField(max_digits=10, decimal_places=2)
    total_entretien = models.DecimalField(max_digits=10, decimal_places=2)
    total_peages = models.DecimalField(max_digits=10, decimal_places=2)
    total_amendes = models.DecimalField(max_digits=10, decimal_places=2)
    total_autre = models.DecimalField(max_digits=10, decimal_places=2)
    kilometrage_debut = models.FloatField()
    kilometrage_fin = models.FloatField()
    consommation_moyenne = models.FloatField()

    def __str__(self):
        return f"Rapport {self.vehicle} ({self.date_debut} - {self.date_fin})"

    @property
    def total_depenses(self):
        return (self.total_carburant + self.total_entretien + 
                self.total_peages + self.total_amendes + self.total_autre)

    @property
    def kilometrage_total(self):
        return self.kilometrage_fin - self.kilometrage_debut

class DocumentAdministratif(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='documents')
    numero_document = models.CharField(max_length=50)
    type_document = models.CharField(max_length=50, choices=[
        ('carte_grise', 'Carte Grise'),
        ('assurance', 'Assurance'),
        ('controle_technique', 'Contrôle Technique'),
        ('autre', 'Autre')
    ])
    date_emission = models.DateField()
    date_expiration = models.DateField()
    fichier = models.FileField(upload_to='documents/')

    def __str__(self):
        return f"{self.type_document} - {self.vehicle}"

class Entretien(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='entretiens')
    type_entretien = models.CharField(max_length=50, choices=[
        ('vidange', 'Vidange'),
        ('pneus', 'Pneus'),
        ('freins', 'Freins'),
        ('autre', 'Autre')
    ])
    date_entretien = models.DateField()
    cout = models.DecimalField(max_digits=10, decimal_places=2)
    commentaires = models.TextField()
    kilometrage = models.FloatField()
    garage = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.type_entretien} - {self.vehicle} ({self.date_entretien})"

class Affectation(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE)
    date_debut = models.DateField()
    date_fin = models.DateField(null=True, blank=True)
    statut = models.CharField(max_length=20, choices=[
        ('actif', 'Actif'),
        ('termine', 'Terminé')
    ], default='actif')
    date_affectation = models.DateTimeField(auto_now_add=True)
    heure_affectation = models.TimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.vehicle} ➝ {self.driver} ({self.date_debut})"

class Rapport(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    titre = models.CharField(max_length=255)
    description = models.TextField()
    type_rapport = models.CharField(max_length=50, choices=[
        ('trajet', 'Trajet'),
        ('consommation', 'Consommation'),
        ('entretien', 'Entretien')
    ])
    date_rapport = models.DateField()
    auteur = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    fichier = models.FileField(upload_to='rapports/')

    def __str__(self):
        return f"{self.titre} ({self.date_rapport})"

class CommentaireEcart(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    mission = models.ForeignKey(Mission, on_delete=models.CASCADE)
    utilisateur = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    commentaire = models.TextField()
    date_commentaire = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Commentaire sur {self.mission} par {self.utilisateur}"

class Historique(models.Model):
    code = models.CharField(max_length=8, default=generate_code, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    utilisateur = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    evenement = models.CharField(max_length=50, choices=[
        ('modification', 'Modification'),
        ('affectation', 'Affectation'),
        ('entretien', 'Entretien')
    ])
    description = models.TextField()
    date_evenement = models.DateField(auto_now_add=True)
    heure_evenement = models.TimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.evenement} - {self.vehicle} ({self.date_evenement})"

class VehiclePosition(models.Model):
    vehicle = models.ForeignKey('Vehicle', on_delete=models.CASCADE, related_name='positions')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    timestamp = models.DateTimeField(auto_now_add=True)
    speed = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    heading = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    battery_level = models.IntegerField(null=True, blank=True)
    is_online = models.BooleanField(default=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.vehicle} - {self.timestamp}"

class Position(models.Model):
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='positions')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.driver} - {self.latitude}, {self.longitude} @ {self.timestamp}"