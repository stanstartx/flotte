from django.db import models
from fleet.models import Mission

# Create your models here.

class PointGPS(models.Model):
    mission = models.ForeignKey(Mission, on_delete=models.CASCADE, related_name='points_gps')
    latitude = models.FloatField()
    longitude = models.FloatField()
    timestamp = models.DateTimeField()

    def __str__(self):
        return f"Point {self.latitude}, {self.longitude} ({self.timestamp})"
