from django.contrib import admin
from .models import PointGPS  # 👈 le vrai nom de ton modèle

admin.site.register(PointGPS)  # 👈 enregistre-le pour l’admin
