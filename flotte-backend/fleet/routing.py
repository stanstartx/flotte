from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/vehicle/(?P<vehicle_id>\w+)/$', consumers.VehicleConsumer.as_asgi()),
] 