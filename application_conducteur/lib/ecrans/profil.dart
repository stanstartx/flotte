import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool isMobile = false;

  final Color greenPrimary = const Color(0xFF2F855A);
  final Color greenLight = const Color(0xFF81E6D9);
  final Color greyLight = const Color(0xFFEDF2F7);
  final Color textPrimary = const Color(0xFF1A202C);

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes; // Pour le web
  String? _photoUrl;

  // Variables pour les vraies données du conducteur
  String _nom = '';
  String _email = '';
  String _telephone = '';
  String _adresse = '';
  String _role = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final backendUrl = prefs.getString('backend_url') ?? 'http://localhost:8000';
      if (token == null) throw Exception('Utilisateur non authentifié');
      final url = Uri.parse('$backendUrl/api/userprofiles/my_profile/');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nom = (data['user']?['first_name'] ?? '') + ' ' + (data['user']?['last_name'] ?? '');
          _email = data['user']?['email'] ?? '';
          _telephone = data['telephone'] ?? '';
          _adresse = data['adresse'] ?? '';
          _role = data['role'] ?? '';
          _photoUrl = data['photo'] ?? _photoUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  double scaled(double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    // base width = 720, clamp entre 0.7 et 1 pour garder lisibilité
    double scaleFactor = (screenWidth / 720).clamp(0.7, 1.0);
    return size * scaleFactor;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _pickedImageBytes = bytes;
        });
      } else {
        setState(() {
          _pickedImage = picked;
          _pickedImageBytes = null;
        });
      }
    }
  }

  Future<void> _savePhoto() async {
    if (_pickedImage == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final driverId = prefs.getInt('driver_id');
    if (token == null || driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non authentifié.')),
      );
      return;
    }
    final backendUrl = prefs.getString('backend_url') ?? 'http://localhost:8000';
    final url = Uri.parse('$backendUrl/api/userprofiles/$driverId/upload_photo/');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token';

    try {
      if (kIsWeb && _pickedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          _pickedImageBytes!,
          filename: _pickedImage!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('photo', _pickedImage!.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la préparation du fichier : $e')),
      );
      return;
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        setState(() {
          _photoUrl = data['photo'] ?? _photoUrl;
          _pickedImage = null;
          _pickedImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo enregistrée avec succès.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'upload (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  ImageProvider getProfileImageProvider() {
    if (_pickedImage != null) {
      if (kIsWeb && _pickedImageBytes != null) {
        return MemoryImage(_pickedImageBytes!);
      } else if (!kIsWeb) {
        return FileImage(File(_pickedImage!.path));
      }
    }
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      if (_photoUrl!.startsWith('http')) {
        return NetworkImage(_photoUrl!);
      } else if (!kIsWeb) {
        return FileImage(File(_photoUrl!));
      } else {
        // Sur le web, on ne peut pas charger un fichier local, donc AssetImage par défaut
        return const AssetImage('assets/images/im1.png');
      }
    }
    return const AssetImage('assets/images/im1.png');
  }

  @override
  Widget build(BuildContext context) {
    isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF2F855A).withOpacity(0.13),
                iconTheme: IconThemeData(color: textPrimary),
                title: Text(
                  'Profil',
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: scaled(20),
                  ),
                ),
              )
              : null,
      drawer: isMobile ? const Menu() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: scaled(40),
                vertical: scaled(48),
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 720),
                  padding: EdgeInsets.symmetric(
                    vertical: scaled(48),
                    horizontal: scaled(36),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(scaled(32)),
                    border: Border.all(color: greyLight, width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2F855A),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar modifiable
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: scaled(60),
                            backgroundImage: getProfileImageProvider(),
                            backgroundColor: Colors.grey[200],
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 3,
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: greenPrimary, size: scaled(28)),
                                tooltip: 'Changer la photo',
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: scaled(30)),
                      Text(
                        _nom.isNotEmpty ? _nom : 'Nom inconnu',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: scaled(32),
                          color: textPrimary,
                          letterSpacing: 1.4,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: scaled(6)),
                      Text(
                        _role.isNotEmpty ? _role[0].toUpperCase() + _role.substring(1) : '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: scaled(16),
                          color: greenPrimary,
                          letterSpacing: 2.5,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: scaled(50)),
                      _InfoRowMinimal(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _email,
                        iconColor: greenPrimary,
                        labelColor: Colors.grey.shade600,
                        valueColor: textPrimary,
                        iconSize: scaled(28),
                        labelFontSize: scaled(13),
                        valueFontSize: scaled(18),
                      ),
                      SizedBox(height: scaled(26)),
                      _InfoRowMinimal(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: _telephone,
                        iconColor: greenPrimary,
                        labelColor: Colors.grey.shade600,
                        valueColor: textPrimary,
                        iconSize: scaled(28),
                        labelFontSize: scaled(13),
                        valueFontSize: scaled(18),
                      ),
                      SizedBox(height: scaled(26)),
                      _InfoRowMinimal(
                        icon: Icons.home_outlined,
                        label: 'Adresse',
                        value: _adresse,
                        iconColor: greenPrimary,
                        labelColor: Colors.grey.shade600,
                        valueColor: textPrimary,
                        iconSize: scaled(28),
                        labelFontSize: scaled(13),
                        valueFontSize: scaled(18),
                      ),
                      SizedBox(height: scaled(64)),
                      // Responsive buttons : colonne sur mobile, ligne sinon
                      isMobile
                          ? Column(
                            children: [
                              _FlatPremiumButton(
                                label: 'Modifier Profil',
                                icon: Icons.edit_outlined,
                                onPressed: _showModifierProfilDialog,
                                bgColor: Colors.transparent,
                                textColor: greenPrimary,
                                borderColor: greenPrimary,
                                hoverBgColor: greenLight.withOpacity(0.3),
                                paddingH: scaled(28),
                                paddingV: scaled(16),
                                fontSize: scaled(16),
                                iconSize: scaled(20),
                              ),
                              SizedBox(height: scaled(16)),
                              _FlatPremiumButton(
                                label: 'Changer mot de passe',
                                icon: Icons.lock_outline,
                                onPressed: _showChangerMotDePasseDialog,
                                bgColor: greenPrimary,
                                textColor: Colors.white,
                                borderColor: Colors.transparent,
                                hoverBgColor: greenPrimary.withOpacity(0.85),
                                paddingH: scaled(28),
                                paddingV: scaled(16),
                                fontSize: scaled(16),
                                iconSize: scaled(20),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FlatPremiumButton(
                                label: 'Modifier Profil',
                                icon: Icons.edit_outlined,
                                onPressed: _showModifierProfilDialog,
                                bgColor: Colors.transparent,
                                textColor: greenPrimary,
                                borderColor: greenPrimary,
                                hoverBgColor: greenLight.withOpacity(0.3),
                                paddingH: scaled(28),
                                paddingV: scaled(16),
                                fontSize: scaled(16),
                                iconSize: scaled(20),
                              ),
                              SizedBox(width: scaled(30)),
                              _FlatPremiumButton(
                                label: 'Changer mot de passe',
                                icon: Icons.lock_outline,
                                onPressed: _showChangerMotDePasseDialog,
                                bgColor: greenPrimary,
                                textColor: Colors.white,
                                borderColor: Colors.transparent,
                                hoverBgColor: greenPrimary.withOpacity(0.85),
                                paddingH: scaled(28),
                                paddingV: scaled(16),
                                fontSize: scaled(16),
                                iconSize: scaled(20),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModifierProfilDialog() {
    final _formKey = GlobalKey<FormState>();
    String nom = _nom;
    String email = _email;
    String tel = _telephone;
    String adresse = _adresse;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaled(24)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(scaled(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: 500,
                  padding: EdgeInsets.all(scaled(24)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, const Color(0xFFF6FFFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: greenPrimary,
                                size: scaled(26),
                              ),
                              SizedBox(width: scaled(10)),
                              Text(
                                'Modifier le Profil',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: scaled(20),
                                  color: greenPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: scaled(24)),
                          _champPremium(
                            'Nom complet',
                            nom,
                            (v) => nom = v ?? '',
                          ),
                          _champPremium(
                            'Adresse email',
                            email,
                            (v) => email = v ?? '',
                          ),
                          _champPremium('Téléphone', tel, (v) => tel = v ?? ''),
                          _champPremium(
                            'Adresse',
                            adresse,
                            (v) => adresse = v ?? '',
                          ),
                          SizedBox(height: scaled(24)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              SizedBox(width: scaled(10)),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save_alt_outlined),
                                label: const Text('Enregistrer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenPrimary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scaled(22),
                                    vertical: scaled(14),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      scaled(12),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profil mis à jour'),
                                      ),
                                    );
                                  }
                                },
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

  void _showChangerMotDePasseDialog() {
    final _formKey = GlobalKey<FormState>();
    String nouveau = '', confirmation = '';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaled(24)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(scaled(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: 500,
                  padding: EdgeInsets.all(scaled(24)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, const Color(0xFFF6FFFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: greenPrimary,
                              size: scaled(26),
                            ),
                            SizedBox(width: scaled(10)),
                            Text(
                              'Changer le mot de passe',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: scaled(20),
                                color: greenPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: scaled(24)),
                        _champPremium(
                          'Nouveau mot de passe',
                          '',
                          (v) => nouveau = v ?? '',
                          obscure: true,
                        ),
                        _champPremium(
                          'Confirmer le mot de passe',
                          '',
                          (v) => confirmation = v ?? '',
                          obscure: true,
                        ),
                        SizedBox(height: scaled(24)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            SizedBox(width: scaled(10)),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.lock_open_outlined),
                              label: const Text('Valider'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenPrimary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: scaled(22),
                                  vertical: scaled(14),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    scaled(12),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  if (nouveau != confirmation) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Les mots de passe ne correspondent pas',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (nouveau.length < 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Le mot de passe doit contenir au moins 6 caractères'),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  // Appel API changement mot de passe
                                  try {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('token');
                                    final backendUrl = prefs.getString('backend_url') ?? 'http://localhost:8000';
                                    final url = Uri.parse('$backendUrl/api/userprofiles/change_password/');
                                    final response = await http.post(
                                      url,
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({'new_password': nouveau}),
                                    );
                                    if (response.statusCode == 200) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Mot de passe modifié avec succès'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      final data = jsonDecode(response.body);
                                      final msg = data['error'] ?? 'Erreur lors du changement de mot de passe';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(msg),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur réseau : $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
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
    );
  }

  Widget _champPremium(
    String label,
    String initial,
    FormFieldSetter<String?> onSaved, {
    bool obscure = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scaled(16)),
      child: TextFormField(
        initialValue: initial.isNotEmpty ? initial : null,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: scaled(14)),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(scaled(14)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(scaled(14)),
            borderSide: BorderSide(color: greenPrimary, width: 1.4),
          ),
        ),
        onSaved: onSaved,
        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
      ),
    );
  }
}

class _InfoRowMinimal extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;

  final double iconSize;
  final double labelFontSize;
  final double valueFontSize;

  const _InfoRowMinimal({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.labelColor,
    required this.valueColor,
    this.iconSize = 28,
    this.labelFontSize = 13,
    this.valueFontSize = 18,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        SizedBox(width: iconSize * 0.7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: labelFontSize,
                color: labelColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: labelFontSize * 0.3),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: valueFontSize,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlatPremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final Color hoverBgColor;

  final double paddingH;
  final double paddingV;
  final double fontSize;
  final double iconSize;

  const _FlatPremiumButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.hoverBgColor,
    this.paddingH = 28,
    this.paddingV = 16,
    this.fontSize = 16,
    this.iconSize = 20,
    Key? key,
  }) : super(key: key);

  @override
  State<_FlatPremiumButton> createState() => _FlatPremiumButtonState();
}

class _FlatPremiumButtonState extends State<_FlatPremiumButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    final bg = isHover ? widget.hoverBgColor : widget.bgColor;
    final border = isHover ? widget.textColor : widget.borderColor;

    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.8),
        ),
        child: TextButton.icon(
          onPressed: widget.onPressed,
          icon: Icon(
            widget.icon,
            color: widget.textColor,
            size: widget.iconSize,
          ),
          label: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: widget.fontSize,
              color: widget.textColor,
              letterSpacing: 1.2,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: widget.paddingH,
              vertical: widget.paddingV,
            ),
            minimumSize: const Size(160, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
