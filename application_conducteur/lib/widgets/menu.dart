import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Menu extends StatefulWidget {
  final Function(String route)? onItemSelected;

  const Menu({super.key, this.onItemSelected});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  String selectedRoute = '';
  bool isCollapsed = false;

  late final AnimationController _animationController;
  late final Animation<double> widthAnimation;

  final double maxWidth = 260;
  final double minWidth = 70;

  final Duration animationDuration = const Duration(milliseconds: 300);

  final List<_MenuItemData> menuItems = [
    _MenuItemData(Icons.dashboard_outlined, 'Tableau de bord', '/dashboard'),
    _MenuItemData(Icons.assignment_rounded, 'Mes missions', '/missions'),
    _MenuItemData(Icons.person_outline, 'Mes trajets', '/trajets'),
    _MenuItemData(Icons.report_problem_outlined, 'Mes incidents', '/incidents'),

    _MenuItemData(
      Icons.insert_drive_file_rounded,
      'Mes documents',
      '/documents',
    ),

    _MenuItemData(
      Icons.warning_amber_rounded,
      'Mes alertes',
      '/alertes',
      badgeCount: 3,
    ),
    _MenuItemData(
      Icons.bar_chart_outlined,
      'Mes statistiques',
      '/statistiques',
    ),

    _MenuItemData(Icons.timeline_rounded, 'Mon historique', '/historiques'),
    _MenuItemData(Icons.settings, 'Paramètres', '/parametres'),
  ];

  @override
  void initState() {
    super.initState();
    selectedRoute = '';
    _animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    widthAnimation = Tween<double>(
      begin: maxWidth,
      end: minWidth,
    ).animate(_animationController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context)?.settings.name ?? '';
      setState(() {
        selectedRoute = route;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleCollapse() {
    setState(() {
      isCollapsed = !isCollapsed;
      if (isCollapsed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigate(String route) {
    setState(() {
      selectedRoute = route;
    });
    widget.onItemSelected?.call(route);
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return isWideScreen
        ? AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: widthAnimation.value,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF64B5F6), // bleu clair subtil
                    Color(0xFF1E88E5), // bleu principal (connexion.dart)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildMenuList()),
                  _buildLogoutButton(),
                  const SizedBox(height: 12),
                  _buildCollapseToggle(),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        )
        : Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildMenuList(isDrawer: true)),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildAvatarSection() {
    return AnimatedSwitcher(
      duration: animationDuration,
      child:
          isCollapsed
              ? Padding(
                key: const ValueKey('collapsedAvatar'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: const Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              )
              : Column(
                key: const ValueKey('expandedAvatar'),
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conducteur',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMenuList({bool isDrawer = false}) {
    return ListView.builder(
      padding:
          isDrawer
              ? const EdgeInsets.only(top: 30)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = selectedRoute == item.route;

        return _MenuItemWidget(
          item: item,
          isSelected: isSelected,
          isCollapsed: isCollapsed,
          onTap: () {
            if (isDrawer) Navigator.of(context).pop();
            _navigate(item.route);
          },
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title:
          isCollapsed
              ? null
              : Text(
                'Se déconnecter',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 28,
      dense: true,
    );
  }

  Widget _buildCollapseToggle() {
    return InkWell(
      onTap: toggleCollapse,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        alignment: isCollapsed ? Alignment.center : Alignment.centerRight,
        child: Icon(
          isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}

class _MenuItemWidget extends StatefulWidget {
  final _MenuItemData item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _MenuItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (widget.isSelected) {
      backgroundColor = Colors.white.withOpacity(0.25);
      iconColor = Colors.white;
      textColor = Colors.white;
    } else if (isHovering) {
      backgroundColor = Colors.white.withOpacity(0.15);
      iconColor = Colors.white;
      textColor = Colors.white70;
    } else {
      backgroundColor = Colors.transparent;
      iconColor = Colors.white70;
      textColor = Colors.white70;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(widget.item.icon, color: iconColor, size: 26),
              if (widget.item.badgeCount != null && widget.item.badgeCount! > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.7),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.item.badgeCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title:
              widget.isCollapsed
                  ? null
                  : Text(
                    widget.item.title,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
          onTap: widget.onTap,
          horizontalTitleGap: 8,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minLeadingWidth: 28,
          dense: true,
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String route;
  final int? badgeCount;

  _MenuItemData(this.icon, this.title, this.route, {this.badgeCount});
}
