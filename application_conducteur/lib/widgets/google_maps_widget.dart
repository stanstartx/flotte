import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:application_conducteur/services/google_maps_service.dart';

class GoogleMapsWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final List<LatLng>? routePoints;
  final String? routePolyline;
  final bool showCurrentLocation;
  final bool showRoute;
  final Function(LatLng)? onLocationSelected;
  final double height;

  const GoogleMapsWidget({
    super.key,
    this.initialPosition,
    this.routePoints,
    this.routePolyline,
    this.showCurrentLocation = true,
    this.showRoute = false,
    this.onLocationSelected,
    this.height = 300,
  });

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _error;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      if (widget.showCurrentLocation) {
        _currentPosition = await GoogleMapsService.getCurrentLocation();
        _addCurrentLocationMarker();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de localisation: $e';
        _isLoading = false;
      });
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(
            title: 'Votre position',
            snippet: 'Position actuelle',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  void _addRouteMarkers() {
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      // Marqueur de départ
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: widget.routePoints!.first,
          infoWindow: const InfoWindow(
            title: 'Départ',
            snippet: 'Point de départ',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Marqueur d'arrivée
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: widget.routePoints!.last,
          infoWindow: const InfoWindow(
            title: 'Arrivée',
            snippet: 'Point d\'arrivée',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de la carte...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur de carte',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeMap,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Carte de secours si Google Maps ne fonctionne pas
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[100]!,
                    Colors.blue[200]!,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carte Google Maps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Position actuelle',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton de localisation
            if (widget.showCurrentLocation)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    try {
                      final position = await GoogleMapsService.getCurrentLocation();
                      setState(() {
                        _currentPosition = position;
                        _markers.clear();
                        _addCurrentLocationMarker();
                      });
                      if (widget.onLocationSelected != null) {
                        widget.onLocationSelected!(position);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur de localisation: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher une carte avec itinéraire
class RouteMapWidget extends StatefulWidget {
  final String origin;
  final String destination;
  final double height;

  const RouteMapWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.height = 400,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _routeData;
  bool _isLoading = true;
  String? _error;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final routeData = await GoogleMapsService.calculateMissionRoute(
        origin: widget.origin,
        destination: widget.destination,
      );

      setState(() {
        _routeData = routeData;
        _isLoading = false;
      });

      // Ajouter les marqueurs et polylines
      _addRouteMarkers();
      _addRoutePolyline();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du calcul de l\'itinéraire: $e';
        _isLoading = false;
      });
    }
  }

  void _addRouteMarkers() {
    if (_routeData != null) {
      final originLocation = _routeData!['origin_location'];
      final destLocation = _routeData!['destination_location'];

      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: originLocation,
          infoWindow: InfoWindow(
            title: 'Départ',
            snippet: widget.origin,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: destLocation,
          infoWindow: InfoWindow(
            title: 'Arrivée',
            snippet: widget.destination,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _addRoutePolyline() {
    if (_routeData != null && _routeData!['directions']['routes'] != null) {
      final routes = _routeData!['directions']['routes'];
      if (routes.isNotEmpty) {
        final route = routes[0];
        final points = <LatLng>[];
        
        // Extraire les points de la polyline
        if (route['overview_polyline'] != null) {
          final polylinePoints = route['overview_polyline']['points'];
          // Note: Pour une vraie implémentation, vous devriez décoder la polyline
          // Pour l'instant, on utilise les points de départ et d'arrivée
          points.add(_routeData!['origin_location']);
          points.add(_routeData!['destination_location']);
        }

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calcul de l\'itinéraire...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur d\'itinéraire',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculateRoute,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_routeData == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Aucun itinéraire disponible'),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Carte
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _routeData!['origin_location'],
                  zoom: 12.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            
            // Informations de route
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: _buildRouteInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    final directions = _routeData!['directions'];
    final distanceMatrix = _routeData!['distance_matrix'];
    
    String duration = 'N/A';
    String distance = 'N/A';
    
    if (directions['routes'] != null && directions['routes'].isNotEmpty) {
      final route = directions['routes'][0];
      final legs = route['legs'];
      if (legs != null && legs.isNotEmpty) {
        final leg = legs[0];
        duration = GoogleMapsService.formatDuration(leg['duration']['text']);
        distance = GoogleMapsService.formatDistance(leg['distance']['text']);
      }
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distance',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                distance,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Durée',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                duration,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Départ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                widget.origin,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 