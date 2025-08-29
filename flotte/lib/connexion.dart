import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        } else {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double largeur =
              constraints.maxWidth < 600 ? constraints.maxWidth * 0.9 : 400;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Column(
                    children: [
                      Image.asset(
                        'assets/logo/logo_groupe_laroche.png',
                        height: 90,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

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
                      onSubmitted: (_) => _handleLogin()),
                  const SizedBox(height: 16),
                  _ChampTexte(
                    label: "Mot de passe",
                    isPassword: true,
                    controller: _passwordController,
                    onSubmitted: (_) => _handleLogin(),
                  ),

                  const SizedBox(height: 12),

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
          );
        },
      ),
    );
  }
}

// Widget réutilisable pour les champs texte
class _ChampTexte extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _ChampTexte({
    required this.label,
    this.isPassword = false,
    required this.controller,
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
    return TextField(
      controller: widget.controller,
      obscureText: !_passwordVisible,
      onSubmitted: widget.onSubmitted,
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
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
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
