from django.db import models
from fleet.models import Vehicle, Driver
from django.core.exceptions import ValidationError

class Affectation(models.Model):
    STATUT_CHOICES = [
        ('active', 'Active'),
        ('terminee', 'Terminée'),
        ('planifiee', 'Planifiée'),
    ]

    TYPE_MISSION_CHOICES = [
        ('livraison', 'Livraison'),
        ('maintenance', 'Maintenance'),
        ('inspection', 'Inspection'),
    ]

    vehicule = models.ForeignKey(
        Vehicle,
        on_delete=models.CASCADE,
        related_name='affectations',
        verbose_name='Véhicule'
    )
    conducteur = models.ForeignKey(
        Driver,
        on_delete=models.CASCADE,
        related_name='affectations',
        verbose_name='Conducteur'
    )
    date_debut = models.DateTimeField(verbose_name='Date de début')
    date_fin = models.DateTimeField(verbose_name='Date de fin')
    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOICES,
        default='planifiee',
        verbose_name='Statut'
    )
    type_mission = models.CharField(
        max_length=20,
        choices=TYPE_MISSION_CHOICES,
        default='livraison',
        verbose_name='Type de mission'
    )
    commentaire = models.TextField(blank=True, verbose_name='Commentaire')
    kilometrage_initial = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        default=0,
        verbose_name='Kilométrage initial'
    )
    kilometrage_final = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Kilométrage final'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Affectation'
        verbose_name_plural = 'Affectations'
        ordering = ['-date_debut']

    def __str__(self):
        return f"{self.vehicule} - {self.conducteur} ({self.date_debut.strftime('%d/%m/%Y')})"

    def clean(self):
        # Vérifier les chevauchements pour le véhicule
        vehicule_affectations = Affectation.objects.filter(
            vehicule=self.vehicule,
            date_debut__lt=self.date_fin,
            date_fin__gt=self.date_debut
        )
        if self.pk:  # Si c'est une mise à jour
            vehicule_affectations = vehicule_affectations.exclude(pk=self.pk)
        if vehicule_affectations.exists():
            raise ValidationError({
                'date_debut': 'Ce véhicule est déjà affecté pendant cette période'
            })

        # Vérifier les chevauchements pour le conducteur
        conducteur_affectations = Affectation.objects.filter(
            conducteur=self.conducteur,
            date_debut__lt=self.date_fin,
            date_fin__gt=self.date_debut
        )
        if self.pk:  # Si c'est une mise à jour
            conducteur_affectations = conducteur_affectations.exclude(pk=self.pk)
        if conducteur_affectations.exists():
            raise ValidationError({
                'date_debut': 'Ce conducteur est déjà affecté pendant cette période'
            })

    def save(self, *args, **kwargs):
        # Vérifier si l'affectation est terminée
        if self.statut == 'terminee' and not self.kilometrage_final:
            raise ValueError("Le kilométrage final est requis pour une affectation terminée")
        
        # Vérifier les dates
        if self.date_fin <= self.date_debut:
            raise ValueError("La date de fin doit être postérieure à la date de début")
        
        # Vérifier les kilométrages
        if self.kilometrage_final and self.kilometrage_final < self.kilometrage_initial:
            raise ValueError("Le kilométrage final ne peut pas être inférieur au kilométrage initial")
        
        # Vérifier les chevauchements
        self.clean()
        
        super().save(*args, **kwargs)

    @property
    def duree(self):
        """Calcule la durée de l'affectation en jours"""
        return (self.date_fin - self.date_debut).days

    @property
    def distance_parcourue(self):
        """Calcule la distance parcourue si l'affectation est terminée"""
        if self.kilometrage_final:
            return self.kilometrage_final - self.kilometrage_initial
        return None
