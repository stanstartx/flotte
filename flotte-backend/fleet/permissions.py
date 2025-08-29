
from rest_framework.permissions import BasePermission

class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.groups.filter(name='admin').exists()

class IsGestionnaire(BasePermission):
    def has_permission(self, request, view):
        return request.user.groups.filter(name='gestionnaire').exists()

class IsConducteur(BasePermission):
    def has_permission(self, request, view):
        return request.user.groups.filter(name='conducteur').exists()

