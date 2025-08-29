from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group, User
from django.contrib.auth.hashers import make_password
from fleet.models import UserProfile

class Command(BaseCommand):
    help = 'Initialise les groupes et les utilisateurs de test'

    def handle(self, *args, **kwargs):
        # Création des groupes
        admin_group, _ = Group.objects.get_or_create(name='admin')
        gestionnaire_group, _ = Group.objects.get_or_create(name='gestionnaire')
        conducteur_group, _ = Group.objects.get_or_create(name='conducteur')

        # Création des utilisateurs de test
        users_data = [
            {
                'username': 'admin',
                'password': 'admin123',
                'email': 'admin@example.com',
                'first_name': 'Admin',
                'last_name': 'User',
                'group': admin_group,
                'role': 'admin'
            },
            {
                'username': 'gestionnaire',
                'password': 'gest123',
                'email': 'gestionnaire@example.com',
                'first_name': 'Gestionnaire',
                'last_name': 'User',
                'group': gestionnaire_group,
                'role': 'gestionnaire'
            },
            {
                'username': 'conducteur',
                'password': 'cond123',
                'email': 'conducteur@example.com',
                'first_name': 'Conducteur',
                'last_name': 'User',
                'group': conducteur_group,
                'role': 'conducteur'
            }
        ]

        for user_data in users_data:
            user, created = User.objects.get_or_create(
                username=user_data['username'],
                defaults={
                    'email': user_data['email'],
                    'first_name': user_data['first_name'],
                    'last_name': user_data['last_name'],
                    'password': make_password(user_data['password'])
                }
            )
            
            if created:
                user.groups.add(user_data['group'])
                # Créer le profil utilisateur
                UserProfile.objects.create(
                    user=user,
                    role=user_data['role']
                )
                self.stdout.write(
                    self.style.SUCCESS(f'Utilisateur {user_data["username"]} créé avec succès')
                )
            else:
                # Mettre à jour l'utilisateur existant
                user.email = user_data['email']
                user.first_name = user_data['first_name']
                user.last_name = user_data['last_name']
                user.set_password(user_data['password'])
                user.save()
                
                # Mettre à jour les groupes
                user.groups.clear()
                user.groups.add(user_data['group'])
                
                # Mettre à jour le profil
                profile, _ = UserProfile.objects.get_or_create(user=user, defaults={'role': user_data['role']})
                profile.role = user_data['role']
                profile.save()
                
                self.stdout.write(
                    self.style.SUCCESS(f'Utilisateur {user_data["username"]} mis à jour avec succès')
                ) 