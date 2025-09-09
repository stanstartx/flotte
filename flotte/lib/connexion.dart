import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flotte/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier la connectivité réseau
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = 'Aucune connexion réseau. Vérifiez votre connexion.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString('role');

        if (role == 'gestionnaire') {
          Navigator.pushReplacementNamed(context, '/gestionnaire_dashboard');
        } else if (role == 'admin' || role == 'administrateur') {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else {
          setState(() {
            _errorMessage = 'Aucun rôle attribué. Contactez l\'administrateur.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }
      }
    } catch (e) {
      String error = e.toString().replaceFirst('Exception: ', '');

      // Harmonisation avec Dio 5 (plus de "DioError")
      if (e.toString().contains('DioException')) {
        if (e.toString().contains('404')) {
          error = 'Serveur introuvable. Vérifiez l\'URL du backend.';
        } else if (e.toString().contains('401')) {
          error = 'Email ou mot de passe incorrect.';
        } else if (e.toString().contains('connectionTimeout')) {
          error = 'Délai de connexion dépassé. Vérifiez si le serveur est en cours.';
        } else if (e.toString().contains('connectionError')) {
          error = 'Impossible de se connecter au serveur. Vérifiez qu\'il est démarré sur http://192.168.11.243:8000.';
        } else {
          error = 'Erreur réseau : impossible de se connecter au serveur.';
        }
      }

      if (mounted) {
        setState(() => _errorMessage = error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double largeur = constraints.maxWidth < 600
              ? constraints.maxWidth * 0.9
              : 400;

          return Center(
            child: Container(
              width: largeur,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo/logo_groupe_laroche.png',
                      height: 90,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "CONNEXION",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4D91),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ChampTexte(
                      label: "Email",
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Entrez un email valide';
                        }
                        return null;
                      },
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 16),
                    _ChampTexte(
                      label: "Mot de passe",
                      isPassword: true,
                      controller: _passwordController,
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Veuillez entrer un mot de passe'
                              : null,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 12),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, '/recuperation-mot-de-passe');
                        },
                        child: const Text(
                          "Mot de passe oublié ?",
                          style: TextStyle(
                            color: Color(0xFF1D4D91),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4D91),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "SE CONNECTER",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChampTexte extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const _ChampTexte({
    required this.label,
    this.isPassword = false,
    required this.controller,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_ChampTexte> createState() => _ChampTexteState();
}

class _ChampTexteState extends State<_ChampTexte> {
  late bool _passwordVisible;

  @override
  void initState() {
    super.initState();
    _passwordVisible = !widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_passwordVisible,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(fontFamily: 'Poppins'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Theme.of(context).primaryColorDark,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }
}
