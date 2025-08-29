# Register your models here.
from django.contrib import admin
from .models import Vehicle, Driver, Assignment, Maintenance, FuelLog, Alert, Mission, UserProfile
from django.utils.html import format_html

class DriverAdmin(admin.ModelAdmin):
    list_display = ('get_username', 'get_nom', 'get_prenom', 'numero_permis', 'statut', 'get_photo')
    search_fields = ('user_profile__user__username', 'numero_permis')
    readonly_fields = ('get_photo',)

    def get_username(self, obj):
        return obj.user_profile.user.username
    get_username.short_description = 'Nom d\'utilisateur'

    def get_nom(self, obj):
        return obj.user_profile.user.last_name
    get_nom.short_description = 'Nom'

    def get_prenom(self, obj):
        return obj.user_profile.user.first_name
    get_prenom.short_description = 'Prénom'

    def get_photo(self, obj):
        if obj.user_profile.photo:
            return format_html('<img src="{}" width="50" height="50" style="object-fit:cover;border-radius:50%;" />', obj.user_profile.photo.url)
        return ""
    get_photo.short_description = 'Photo'

#admin.site.register(Vehicle, VehicleAdmin)

admin.site.register(UserProfile)
admin.site.register(Vehicle)
admin.site.register(Driver, DriverAdmin)
admin.site.register(Assignment)
admin.site.register(Maintenance)
admin.site.register(FuelLog)
admin.site.register(Alert)
admin.site.register(Mission)
