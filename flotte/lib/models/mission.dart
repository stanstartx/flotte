class Mission {
  final String id;
  final String codeMission;
  final String intitule;
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? statut;
  final String? commentaire;
  final String vehicleId;
  final String driverId;
  final Map<String, dynamic>? driverDetails;
  final Map<String, dynamic>? vehicleDetails;
  final String? reponseConducteur;

  Mission({
    required this.id,
    required this.codeMission,
    required this.intitule,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.dateDebut,
    required this.dateFin,
    this.statut,
    this.commentaire,
    required this.vehicleId,
    required this.driverId,
    this.driverDetails,
    this.vehicleDetails,
    this.reponseConducteur,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? safeMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      return null;
    }
    DateTime parseDate(String? value) {
      if (value == null || value.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return Mission(
      id: json['id'].toString(),
      codeMission: json['code'] ?? json['codeMission'] ?? json['code_mission'] ?? '',
      intitule: json['raison'] ?? json['intitule'] ?? json['titre'] ?? '',
      lieuDepart: json['lieu_depart'] ?? json['lieuDepart'] ?? '',
      lieuArrivee: json['lieu_arrivee'] ?? json['lieuArrivee'] ?? '',
      dateDebut: parseDate(json['date_depart']?.toString()),
      dateFin: parseDate(json['date_arrivee']?.toString()),
      statut: json['statut'],
      commentaire: json['commentaire'],
      vehicleId: json['vehicle']?.toString() ?? '',
      driverId: json['driver']?.toString() ?? '',
      driverDetails: safeMap(json['driver_details']),
      vehicleDetails: safeMap(json['vehicle_details']),
      reponseConducteur: json['reponse_conducteur'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': codeMission,
      'vehicle': vehicleId,
      'driver': driverId,
      'date_depart': dateDebut.toIso8601String(),
      'date_arrivee': dateFin.toIso8601String(),
      'lieu_depart': lieuDepart,
      'lieu_arrivee': lieuArrivee,
      'raison': intitule,
      'commentaire': commentaire,
    };
  }
}
