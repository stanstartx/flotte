from django.core.management.base import BaseCommand
from django.contrib.auth.models import User, Group
from django.contrib.auth.hashers import make_password

class Command(BaseCommand):
    help = 'Crée ou met à jour l\'utilisateur par défaut pour l\'application'

    def handle(self, *args, **kwargs):
        # Créer les groupes s'ils n'existent pas
        admin_group, _ = Group.objects.get_or_create(name='admin')
        gestionnaire_group, _ = Group.objects.get_or_create(name='gestionnaire')
        conducteur_group, _ = Group.objects.get_or_create(name='conducteur')

        # Créer ou mettre à jour l'utilisateur stan
        user, created = User.objects.get_or_create(
            username='stan',
            defaults={
                'password': make_password('CI0114279081'),
                'is_staff': True,
                'is_superuser': True
            }
        )

        if not created:
            # Mettre à jour le mot de passe si l'utilisateur existe déjà
            user.set_password('CI0114279081')
            user.is_staff = True
            user.is_superuser = True
            user.save()
            self.stdout.write(self.style.SUCCESS('Mot de passe de l\'utilisateur stan mis à jour'))
        else:
            self.stdout.write(self.style.SUCCESS('Utilisateur stan créé avec succès'))

        # S'assurer que l'utilisateur est dans le groupe admin
        if not user.groups.filter(name='admin').exists():
            user.groups.add(admin_group)
            self.stdout.write(self.style.SUCCESS('Utilisateur stan ajouté au groupe admin')) 