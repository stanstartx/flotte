from django.contrib.auth.models import User, Group
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .models import UserProfile, Driver
import logging

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    try:
        logger.info("[register_user] payload=%s", dict(request.data))
        username = (request.data.get('username') or '').strip()
        password = (request.data.get('password') or '').strip()
        email = (request.data.get('email') or '').strip()
        role = (request.data.get('role') or 'conducteur').strip()  # admin, gestionnaire, conducteur
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')

        if not (username or email) or not password:
            logger.warning("[register_user] missing fields username=%s email=%s password_provided=%s", bool(username), bool(email), bool(password))
            return Response({'error': "username (ou email) et password sont requis."}, status=400)

        # Si username est vide, tenter de l'inférer depuis l'email
        if not username and email:
            base_username = email.split('@')[0][:30] or 'user'
            candidate = base_username
            suffix = 1
            while User.objects.filter(username=candidate).exists():
                candidate = f"{base_username}{suffix}"
                suffix += 1
            username = candidate

        if User.objects.filter(username=username).exists():
            logger.warning("[register_user] username exists username=%s", username)
            return Response({'error': "Ce nom d'utilisateur existe déjà."}, status=400)

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
        )
        logger.info("[register_user] user created id=%s username=%s", user.id, user.username)

        if role in ['admin', 'gestionnaire', 'conducteur']:
            group, _ = Group.objects.get_or_create(name=role)
            user.groups.add(group)
            logger.info("[register_user] user added to group role=%s", role)

        # Profil est créé via signal; le récupérer pour renvoyer son id
        try:
            profile = UserProfile.objects.get(user=user)
        except UserProfile.DoesNotExist:
            profile = UserProfile.objects.create(user=user)
        logger.info("[register_user] profile ready id=%s", profile.id)

        return Response({
            'message': 'Utilisateur créé avec succès.',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            },
            'profile_id': profile.id,
        }, status=201)
    except Exception as e:
        logger.exception("[register_user] Unexpected error: %s", str(e))
        return Response({'error': f"Erreur interne: {str(e)}"}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_role(request):
    user = request.user
    roles = list(user.groups.values_list('name', flat=True))
    return Response({'username': user.username, 'roles': roles})

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    # Accept either username or email from the same field (mobile sends email in 'username')
    username_input = request.data.get('username') or request.data.get('email')
    password = request.data.get('password')

    # Try to authenticate directly with provided username
    user = authenticate(username=username_input, password=password)

    # If that fails, and the input looks like an email or username not found, try resolving by email
    if not user:
        try:
            # Normalize email case
            from django.contrib.auth.models import User as DjangoUser
            possible_user = DjangoUser.objects.filter(email__iexact=(username_input or '')).first()
            if possible_user:
                user = authenticate(username=possible_user.username, password=password)
        except Exception:
            user = None
    
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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    """Endpoint pour la déconnexion (invalidation du token)"""
    try:
        # Pour JWT, on peut ajouter le token à une blacklist si nécessaire
        # Pour l'instant, on retourne juste un succès
        return Response({'message': 'Déconnexion réussie'}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def verify_token(request):
    """Endpoint pour vérifier la validité du token"""
    user = request.user
    try:
        profile = UserProfile.objects.get(user=user)
        roles = list(user.groups.values_list('name', flat=True))
        driver_id = None
        if 'conducteur' in roles:
            try:
                driver = Driver.objects.get(user_profile=profile)
                driver_id = driver.id
            except Driver.DoesNotExist:
                driver_id = None
        
        return Response({
            'valid': True,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'roles': roles,
                'driver_id': driver_id,
                'profile': {
                    'telephone': profile.telephone,
                    'adresse': profile.adresse,
                    'role': profile.role,
                    'photo': profile.photo.url if profile.photo else None
                }
            }
        })
    except UserProfile.DoesNotExist:
        return Response({'error': 'Profil utilisateur non trouvé'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """Endpoint pour changer le mot de passe"""
    user = request.user
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    
    if not user.check_password(old_password):
        return Response({'error': 'Ancien mot de passe incorrect'}, status=status.HTTP_400_BAD_REQUEST)
    
    user.set_password(new_password)
    user.save()
    
    return Response({'message': 'Mot de passe modifié avec succès'}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password(request):
    """Endpoint pour la récupération de mot de passe"""
    email = request.data.get('email')
    
    try:
        user = User.objects.get(email=email)
        # Ici vous pouvez implémenter l'envoi d'email
        # Pour l'instant, on retourne juste un message
        return Response({'message': 'Si cet email existe, vous recevrez un lien de récupération'}, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        # Pour des raisons de sécurité, on ne révèle pas si l'email existe ou non
        return Response({'message': 'Si cet email existe, vous recevrez un lien de récupération'}, status=status.HTTP_200_OK)