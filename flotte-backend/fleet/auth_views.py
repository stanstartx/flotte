from django.contrib.auth.models import User, Group
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .models import UserProfile, Driver

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    username = request.data.get('username')
    password = request.data.get('password')
    email = request.data.get('email')
    role = request.data.get('role')  # admin, gestionnaire, conducteur

    if User.objects.filter(username=username).exists():
        return Response({'error': "Ce nom d'utilisateur existe déjà."}, status=400)

    user = User.objects.create_user(username=username, email=email, password=password)

    if role in ['admin', 'gestionnaire', 'conducteur']:
        group = Group.objects.get(name=role)
        user.groups.add(group)

    return Response({'message': 'Utilisateur créé avec succès.'}, status=201)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_role(request):
    user = request.user
    roles = list(user.groups.values_list('name', flat=True))
    return Response({'username': user.username, 'roles': roles})

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    username = request.data.get('username')
    password = request.data.get('password')

    user = authenticate(username=username, password=password)
    
    if user:
        refresh = RefreshToken.for_user(user)
        roles = list(user.groups.values_list('name', flat=True))
        driver_id = None
        if 'conducteur' in roles:
            try:
                profile = UserProfile.objects.get(user=user)
                driver = Driver.objects.get(user_profile=profile)
                driver_id = driver.id
            except (UserProfile.DoesNotExist, Driver.DoesNotExist):
                driver_id = None
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'roles': roles,
                'driver_id': driver_id
            }
        })
    else:
        return Response(
            {'error': 'Identifiants invalides'},
            status=status.HTTP_401_UNAUTHORIZED
        )