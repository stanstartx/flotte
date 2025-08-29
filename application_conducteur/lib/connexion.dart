import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'services/position_sender_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/location_service.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _handleLogin() async {
    print('LOG: _handleLogin appelé');
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      print('LOG: Tentative de connexion pour ${_emailController.text.trim()}');
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      Provider.of<PositionSenderService>(context, listen: false).start();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('LOG: Erreur lors de la connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double getResponsiveFontSize(double baseSize, double screenWidth) {
    if (screenWidth < 400) return baseSize * 0.85;
    if (screenWidth < 600) return baseSize * 0.95;
    if (screenWidth > 1000) return baseSize * 1.1;
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1000;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const greenColor = Color(0xFF2E7D32);

    double containerWidth =
        isMobile
            ? size.width * 0.95
            : isTablet
            ? 500
            : 600;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: isPortrait ? 24 : 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width),
            child: Container(
              width: containerWidth,
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow:
                    isDark
                        ? []
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Row(
                        mainAxisAlignment:
                            isMobile
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: isDark ? Colors.white : greenColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Connexion",
                            style: GoogleFonts.poppins(
                              fontSize: getResponsiveFontSize(20, size.width),
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Bienvenue 👋",
                        style: GoogleFonts.poppins(
                          fontSize: getResponsiveFontSize(26, size.width),
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Connectez-vous pour accéder à votre espace",
                        style: GoogleFonts.poppins(
                          fontSize: getResponsiveFontSize(14, size.width),
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: false,
                                onChanged: (_) {},
                                side: BorderSide(
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              Text(
                                "Se souvenir",
                                style: GoogleFonts.poppins(
                                  fontSize: getResponsiveFontSize(
                                    12,
                                    size.width,
                                  ),
                                  color:
                                      isDark
                                          ? Colors.grey[300]
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Mot de passe oublié ?",
                              style: GoogleFonts.poppins(
                                fontSize: getResponsiveFontSize(12, size.width),
                                color: greenColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Se connecter",
                                  style: GoogleFonts.poppins(
                                    fontSize: getResponsiveFontSize(16, size.width),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pas encore de compte ?",
                            style: GoogleFonts.poppins(
                              fontSize: getResponsiveFontSize(12, size.width),
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Créer un compte",
                              style: GoogleFonts.poppins(
                                fontSize: getResponsiveFontSize(12, size.width),
                                color: greenColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
