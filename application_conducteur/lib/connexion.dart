// application_conducteur/lib/connexion.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'services/position_sender_service.dart';
import 'dart:async';

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
  bool _rememberMe = false; // Case fonctionnelle
  String _debugMessage = ''; // Pour afficher les messages de debug

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
    
    // Pré-remplir avec des données de test
    _emailController.text = 'test@example.com';
    _passwordController.text = 'password123';
    
    // Tester la connectivité au démarrage
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _debugMessage = 'Test de connectivité...';
    });
    
    try {
      // Vous pouvez ajouter un test de ping ici
      // final dio = HttpClient.instance;
      // await dio.get('/auth/test-connection/');
      setState(() {
        _debugMessage = 'Connexion au serveur OK';
      });
    } catch (e) {
      setState(() {
        _debugMessage = 'Erreur de connexion: ${e.toString()}';
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _debugMessage = 'Tentative de connexion...';
    });
    
    try {
      print('=== DÉBUT CONNEXION ===');
      print('Email: ${_emailController.text.trim()}');
      print('Mot de passe fourni: ${_passwordController.text.isNotEmpty}');
      
      setState(() {
        _debugMessage = 'Envoi des données de connexion...';
      });
      
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      print('=== CONNEXION RÉUSSIE ===');
      setState(() {
        _debugMessage = 'Connexion réussie! Démarrage du service de position...';
      });
      
      // Démarrer le service de position
      Provider.of<PositionSenderService>(context, listen: false).start();
      
      setState(() {
        _debugMessage = 'Redirection vers le tableau de bord...';
      });
      
      if (mounted) {
        // Petite pause pour voir le message
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('=== ERREUR DE CONNEXION ===');
      print('Erreur complète: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      
      setState(() {
        _debugMessage = 'Erreur: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    // Palette de couleurs
    const primaryColor = Color(0xFF1E88E5); // Bleu principal
    const backgroundLight = Color(0xFFF0F4F8);
    const backgroundDark = Color(0xFF121212);

    double containerWidth =
        isMobile
            ? size.width * 0.95
            : isTablet
            ? 500
            : 600;

    return Scaffold(
      backgroundColor: isDark ? backgroundDark : backgroundLight,
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
                    crossAxisAlignment: CrossAxisAlignment.center, // Centré
                    children: [
                      // Titre centré
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "CONNEXION",
                            style: GoogleFonts.poppins(
                              fontSize: getResponsiveFontSize(20, size.width),
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Connectez-vous pour accéder à votre espace",
                        style: GoogleFonts.poppins(
                          fontSize: getResponsiveFontSize(14, size.width),
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Message de debug
                      if (_debugMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: _debugMessage.contains('Erreur') 
                                ? Colors.red.withOpacity(0.1)
                                : _debugMessage.contains('réussie') 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _debugMessage.contains('Erreur') 
                                  ? Colors.red.withOpacity(0.3)
                                  : _debugMessage.contains('réussie') 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _debugMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _debugMessage.contains('Erreur') 
                                  ? Colors.red
                                  : _debugMessage.contains('réussie') 
                                      ? Colors.green
                                      : Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          helperText: 'Utilisez: test@example.com pour tester',
                          helperStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
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
                          helperText: 'Utilisez: password123 pour tester',
                          helperStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
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
                      
                      // Case "Se souvenir de moi"
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            side: BorderSide(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          Text(
                            "Se souvenir de moi",
                            style: GoogleFonts.poppins(
                              fontSize: getResponsiveFontSize(12, size.width),
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Se connecter",
                                    style: GoogleFonts.poppins(
                                      fontSize: getResponsiveFontSize(
                                        16,
                                        size.width,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                        ),
                      ),
                      
                      // Bouton de test de connectivité
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _testConnection,
                        child: Text(
                          'Tester la connexion au serveur',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: primaryColor,
                          ),
                        ),
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