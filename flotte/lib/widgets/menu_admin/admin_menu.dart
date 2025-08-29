import 'package:flutter/material.dart';

class AdminMenu extends StatefulWidget {
  final Function(String route)? onItemSelected;

  const AdminMenu({super.key, this.onItemSelected});

  @override
  State<AdminMenu> createState() => _AdminMenuState();
}

class _AdminMenuState extends State<AdminMenu> {
  String selectedRoute = '/admin/dashboard';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Détecte la route actuelle pour garder le menu synchronisé
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null && routeName != selectedRoute) {
      setState(() {
        selectedRoute = routeName;
      });
    }
  }

  void _navigate(String route, bool isDrawer) {
    if (isDrawer) Navigator.of(context).pop(); // ferme le drawer mobile
    if (route != selectedRoute) {
      setState(() {
        selectedRoute = route;
      });
      widget.onItemSelected?.call(route);
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 600) {
      // Desktop: sidebar
      return buildMenuContent();
    }
    // Mobile: drawer
    return Drawer(
      child: buildMenuContent(isDrawer: true),
    );
  }

  Widget buildMenuContent({bool isDrawer = false}) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
        children: [
          GestureDetector(
            onTap: () => _navigate('/admin/dashboard', isDrawer),
            child: Column(
              children: [
                Container(
                  height: 100, // taille augmentée
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/logo/logo_groupe_laroche.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                // Si tu veux le texte sous le logo, décommente :
                // const Text('GROUPE\nLAROCHE', textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildMenuItem(
              Icons.dashboard, 'Tableau de bord', '/admin/dashboard', isDrawer),
          _buildMenuItem(
              Icons.directions_car, 'Véhicules', '/admin/vehicules', isDrawer),
          _buildMenuItem(
              Icons.people, 'Utilisateurs', '/admin/utilisateurs', isDrawer),
          _buildMenuItemWithBadge(Icons.warning_amber_rounded, 'Alertes',
              '/admin/alertes', isDrawer,
              badgeCount: 5),
          _buildMenuItem(Icons.flag, 'Missions', '/admin/missions', isDrawer),
          _buildMenuItem(
              Icons.description, 'Documents', '/admin/documents', isDrawer),
          const Divider(color: Colors.black26, height: 40, thickness: 1),
          _buildMenuItem(Icons.map, 'Trajets', '/admin/trajets', isDrawer),
          _buildMenuItem(
              Icons.bar_chart, 'Statistiques', '/admin/statistiques', isDrawer),
          _buildMenuItem(
              Icons.settings, 'Paramètres', '/admin/parametres', isDrawer),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String title, String route, bool isDrawer) {
    final isSelected = selectedRoute == route;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE5ECFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF002244) : Colors.grey[800],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF002244) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => _navigate(route, isDrawer),
        hoverColor: Colors.blue.withOpacity(0.1),
      ),
    );
  }

  Widget _buildMenuItemWithBadge(
      IconData icon, String title, String route, bool isDrawer,
      {int badgeCount = 0}) {
    return _buildMenuItemWithExtra(
      icon: icon,
      title: title,
      route: route,
      isDrawer: isDrawer,
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItemWithExtra({
    required IconData icon,
    required String title,
    required String route,
    required bool isDrawer,
    Widget? trailing,
  }) {
    final isSelected = selectedRoute == route;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE5ECFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF002244) : Colors.grey[800],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF002244) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => _navigate(route, isDrawer),
        hoverColor: Colors.blue.withOpacity(0.1),
      ),
    );
  }
}
