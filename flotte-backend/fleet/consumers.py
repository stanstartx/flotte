import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import VehiclePosition, Vehicle

class VehicleConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.vehicle_id = self.scope['url_route']['kwargs']['vehicle_id']
        self.room_group_name = f'vehicle_{self.vehicle_id}'

        # Rejoindre le groupe de la salle
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        # Quitter le groupe de la salle
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        data = json.loads(text_data)
        
        # Sauvegarder la position du véhicule
        await self.save_vehicle_position(data)

        # Envoyer la position à tous les clients connectés
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'vehicle_position',
                'position': data
            }
        )

    async def vehicle_position(self, event):
        # Envoyer la position au WebSocket
        await self.send(text_data=json.dumps(event['position']))

    @database_sync_to_async
    def save_vehicle_position(self, data):
        vehicle = Vehicle.objects.get(id=self.vehicle_id)
        VehiclePosition.objects.create(
            vehicle=vehicle,
            latitude=data['latitude'],
            longitude=data['longitude'],
            speed=data.get('speed'),
            heading=data.get('heading'),
            battery_level=data.get('battery_level'),
            is_online=True
        ) 