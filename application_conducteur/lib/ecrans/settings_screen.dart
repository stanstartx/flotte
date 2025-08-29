import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:application_conducteur/services/notification_service.dart';
import 'package:application_conducteur/services/cache_service.dart';
import 'package:application_conducteur/services/error_handler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool> notificationSettings = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final settings = await NotificationService.getNotificationSettings();
      setState(() {
        notificationSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des paramètres: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      setState(() {
        notificationSettings[key] = value;
      });
      await NotificationService.updateNotificationSettings(notificationSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paramètre mis à jour'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          'Erreur lors de la mise à jour: $e',
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      await CacheService.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache vidé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          'Erreur lors du vidage du cache: $e',
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandlerService.showErrorSnackBar(
            context,
            'Erreur lors de la déconnexion: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF14532D),
              elevation: 0,
              title: const Text(
                'Paramètres',
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildSettingsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.poppins(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSettings,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 32),
          
          // Section Notifications
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              _buildSwitchTile(
                title: 'Nouvelles missions',
                subtitle: 'Recevoir des notifications pour les nouvelles missions',
                value: notificationSettings['missions'] ?? true,
                onChanged: (value) => _updateNotificationSetting('missions', value),
              ),
              _buildSwitchTile(
                title: 'Alertes',
                subtitle: 'Recevoir des notifications d\'alerte',
                value: notificationSettings['alerts'] ?? true,
                onChanged: (value) => _updateNotificationSetting('alerts', value),
              ),
              _buildSwitchTile(
                title: 'Entretien',
                subtitle: 'Recevoir des notifications d\'entretien',
                value: notificationSettings['maintenance'] ?? true,
                onChanged: (value) => _updateNotificationSetting('maintenance', value),
              ),
              _buildSwitchTile(
                title: 'Système',
                subtitle: 'Recevoir des notifications système',
                value: notificationSettings['system'] ?? true,
                onChanged: (value) => _updateNotificationSetting('system', value),
              ),
              _buildSwitchTile(
                title: 'Son',
                subtitle: 'Activer les sons de notification',
                value: notificationSettings['sound'] ?? true,
                onChanged: (value) => _updateNotificationSetting('sound', value),
              ),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: 'Activer les vibrations',
                value: notificationSettings['vibration'] ?? true,
                onChanged: (value) => _updateNotificationSetting('vibration', value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section Application
          _buildSection(
            title: 'Application',
            icon: Icons.settings,
            children: [
              _buildListTile(
                title: 'Vider le cache',
                subtitle: 'Libérer de l\'espace de stockage',
                icon: Icons.cleaning_services,
                onTap: _clearCache,
              ),
              _buildListTile(
                title: 'À propos',
                subtitle: 'Informations sur l\'application',
                icon: Icons.info,
                onTap: () {
                  // TODO: Implémenter l'écran À propos
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section Compte
          _buildSection(
            title: 'Compte',
            icon: Icons.person,
            children: [
              _buildListTile(
                title: 'Déconnexion',
                subtitle: 'Se déconnecter de l\'application',
                icon: Icons.logout,
                onTap: _logout,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6A4EC2)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF6A4EC2),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF6A4EC2),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 