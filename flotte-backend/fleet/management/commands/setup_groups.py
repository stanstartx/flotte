from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group

class Command(BaseCommand):
    help = 'Crée les groupes par défaut pour l\'application'

    def handle(self, *args, **kwargs):
        groups = ['admin', 'gestionnaire', 'conducteur']
        for group_name in groups:
            group, created = Group.objects.get_or_create(name=group_name)
            if created:
                self.stdout.write(self.style.SUCCESS(f'Groupe "{group_name}" créé avec succès'))
            else:
                self.stdout.write(self.style.SUCCESS(f'Groupe "{group_name}" existe déjà')) 