import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VehiculesPage extends StatefulWidget {
  const VehiculesPage({super.key});

  @override
  State<VehiculesPage> createState() => _VehiculesPageState();
}

class _VehiculesPageState extends State<VehiculesPage> {
  List<Map<String, dynamic>> vehicules = [];
  String selectedStatut = 'Tous';
  String selectedMarque = 'Toutes';
  final List<String> statuts = [
    'Tous',
    'Disponible',
    'En mission',
    'En entretien',
  ];
  List<String> marques = ['Toutes'];
  bool _isLoading = true;
  String? _error;

  Color getStatusColor(String statut) {
    switch (statut) {
      case 'Disponible':
        return const Color(0xFF22C55E); // Vert vif
      case 'En mission':
        return const Color(0xFF2563EB); // Bleu vif
      case 'En entretien':
        return const Color(0xFFEF4444); // Rouge vif
      case 'Indisponible':
        return Colors.red.shade700;
      default:
        return const Color(0xFF2F855A);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchVehiculesAffectes();
  }

  Future<void> _fetchVehiculesAffectes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      // Remplace par l'URL de ton backend si besoin
      const backendUrl = 'http://localhost:8000/api/conducteur/vehicules/';
      if (token == null) throw Exception('Token non trouvé');
      final response = await http.get(
        Uri.parse(backendUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          vehicules = List<Map<String, dynamic>>.from(data);
          marques = [
            'Toutes',
            ...{for (var v in vehicules) v['marque'] as String},
          ];
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

  List<Map<String, dynamic>> get filteredVehicules {
    return vehicules.where((v) {
      final statutMatch =
          selectedStatut == 'Tous' || v['statut'] == selectedStatut;
      final marqueMatch =
          selectedMarque == 'Toutes' || v['marque'] == selectedMarque;
      return statutMatch && marqueMatch;
    }).toList();
  }

  void showVehiculeDetailsModal(
    BuildContext context,
    Map<String, dynamic> vehicule,
  ) {
    int currentPhotoIndex = 0;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre + badge "Nouveau"
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${vehicule['marque']} ${vehicule['modele']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF14532D),
                                ),
                              ),
                            ),
                            if (vehicule['nouveau'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "Nouveau",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Badge statut
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              vehicule['statut']!,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vehicule['statut'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: getStatusColor(vehicule['statut']!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Carousel photos avec indicateurs
                        SizedBox(
                          height: 220,
                          child: Stack(
                            children: [
                              PageView.builder(
                                itemCount: (vehicule['photos'] as List).length,
                                onPageChanged: (index) {
                                  setModalState(() {
                                    currentPhotoIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final photoUrl = vehicule['photos'][index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        progress,
                                      ) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                progress.expectedTotalBytes !=
                                                        null
                                                    ? progress
                                                            .cumulativeBytesLoaded /
                                                        progress
                                                            .expectedTotalBytes!
                                                    : null,
                                            color: const Color(0xFF14532D),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[200],
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 80,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    (vehicule['photos'] as List).length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: currentPhotoIndex == i ? 16 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            currentPhotoIndex == i
                                                ? const Color(0xFF14532D)
                                                : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Immatriculation
                        Row(
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Immatriculation : ${vehicule['immatriculation']}",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Historique entretien
                        Text(
                          "Historique d'entretien",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if ((vehicule['entretien'] as List).isEmpty)
                          Text(
                            "Aucun entretien enregistré.",
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          )
                        else
                          ...((vehicule['entretien'] as List).map((entretien) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Color(0xFF14532D),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      "${entretien['date']} — ${entretien['description']}",
                                      style: GoogleFonts.poppins(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })),

                        const SizedBox(height: 32),

                        // Bouton fermer
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF14532D),
                              textStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Fermer"),
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

  Widget vehiculeCard(Map<String, dynamic> vehicule) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F855A).withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marque + modèle + badge "Nouveau"
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${vehicule['marque']} ${vehicule['modele']}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14532D),
                    ),
                  ),
                ),
                if (vehicule['nouveau'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      "Nouveau",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Statut badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: getStatusColor(vehicule['statut']!).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                vehicule['statut'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: getStatusColor(vehicule['statut']!),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Immatriculation
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  vehicule['immatriculation'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Boutons action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => showVehiculeDetailsModal(context, vehicule),
                  icon: const Icon(Icons.info_outline),
                  label: const Text("Voir fiche"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14532D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    elevation: 6,
                    shadowColor: Colors.black45,
                  ),
                ),
                const SizedBox(width: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Ajouter fonctionnalité modifier véhicule
                  },
                  icon: const Icon(Icons.edit, color: Color(0xFF14532D)),
                  label: Text(
                    "Modifier",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF14532D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF14532D)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget vehiculeCardMobile(Map<String, dynamic> vehicule) {
    // Version allégée / adaptée mobile de la carte
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        title: Text(
          '${vehicule['marque']} ${vehicule['modele']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF14532D),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(vehicule['statut']!).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                vehicule['statut'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: getStatusColor(vehicule['statut']!),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vehicule['immatriculation'],
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline, color: Color(0xFF14532D)),
          onPressed: () => showVehiculeDetailsModal(context, vehicule),
        ),
      ),
    );
  }

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredBySearch =
        vehicules.where((vehicule) {
          return vehicule['marque']!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              vehicule['modele']!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              vehicule['immatriculation']!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();

    final filteredList =
        filteredBySearch.where((v) {
          final statutMatch =
              selectedStatut == 'Tous' || v['statut'] == selectedStatut;
          final marqueMatch =
              selectedMarque == 'Toutes' || v['marque'] == selectedMarque;
          return statutMatch && marqueMatch;
        }).toList();

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      drawer: isMobile ? const Drawer(child: Menu()) : null,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: const Color(0xFF14532D),
                title: Text(
                  "Mes véhicules",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              )
              : null,
      body:
          isMobile
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtres verticalisés
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        shadowColor: Colors.black.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade100, width: 1),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedStatut,
                                          isExpanded: true,
                                          borderRadius: BorderRadius.circular(16),
                                          onChanged: (val) => setState(() => selectedStatut = val!),
                                          items: statuts
                                              .map((e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text(e, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade100, width: 1),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedMarque,
                                          isExpanded: true,
                                          borderRadius: BorderRadius.circular(16),
                                          onChanged: (val) => setState(() => selectedMarque = val!),
                                          items: marques
                                              .map((e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text(e, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Barre recherche
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Rechercher un véhicule...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF14532D),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF14532D),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF14532D),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF14532D),
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: const Color(0xFF14532D),
                      ),

                      const SizedBox(height: 20),

                      // Liste véhicules
                      Expanded(
                        child:
                            filteredList.isEmpty
                                ? Center(
                                  child: Text(
                                    "Aucun véhicule trouvé.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    return vehiculeCardMobile(
                                      filteredList[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              )
              : Row(
                children: [
                  const Menu(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header top
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14532D),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.directions_car_filled_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "Mes véhicules",
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF14532D),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Filtres dans card élégante
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            shadowColor: Colors.black.withOpacity(0.08),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedStatut,
                                      decoration: InputDecoration(
                                        labelText: "Filtrer par statut",
                                        labelStyle: GoogleFonts.poppins(
                                          color: const Color(0xFF14532D),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade100,
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade100,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF22C55E),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      iconEnabledColor: const Color(0xFF14532D),
                                      items: statuts
                                          .map(
                                            (statut) => DropdownMenuItem(
                                              value: statut,
                                              child: Text(
                                                statut,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            selectedStatut = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedMarque,
                                      decoration: InputDecoration(
                                        labelText: "Filtrer par marque",
                                        labelStyle: GoogleFonts.poppins(
                                          color: const Color(0xFF14532D),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade100,
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade100,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF22C55E),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      iconEnabledColor: const Color(0xFF14532D),
                                      items: marques
                                          .map(
                                            (marque) => DropdownMenuItem(
                                              value: marque,
                                              child: Text(
                                                marque,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            selectedMarque = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Barre recherche premium
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Rechercher un véhicule...",
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF14532D),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: Color(0xFF14532D),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF14532D),
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: const Color(0xFF14532D),
                          ),

                          const SizedBox(height: 30),

                          // Liste véhicules
                          Expanded(
                            child:
                                filteredList.isEmpty
                                    ? Center(
                                      child: Text(
                                        "Aucun véhicule trouvé.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: filteredList.length,
                                      itemBuilder: (context, index) {
                                        return vehiculeCard(
                                          filteredList[index],
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
