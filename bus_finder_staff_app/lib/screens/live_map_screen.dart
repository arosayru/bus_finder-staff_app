import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import '../user_service.dart';
import '/map_service.dart';
import '/service/gps_service.dart'; // Import the global GPS service
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

class LiveMapScreen extends StatefulWidget {
  final dynamic busRoute;
  final dynamic bus;

  const LiveMapScreen({
    super.key,
    this.busRoute,
    this.bus,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final int currentIndex = 1;
  late GpsService _gpsService;

  gmaps.GoogleMapController? _mapController;
  MapConfiguration? _mapConfig;
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Polyline> _polylines = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Default camera position (Colombo, Sri Lanka)
  gmaps.CameraPosition _initialCameraPosition = const gmaps.CameraPosition(
    target: gmaps.LatLng(6.9271, 79.8612),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _gpsService = GpsService();
    print('[DEBUG] LiveMapScreen initState called');
    print('BusRoute: ${widget.busRoute}');
    print('Bus: ${widget.bus}');
    _loadMapData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateBusMarker(String busId, double latitude, double longitude) {
    print('[Map] Placing/updating bus marker: id=$busId, lat=$latitude, lng=$longitude');
    final latLng = gmaps.LatLng(latitude, longitude);
    final markerId = gmaps.MarkerId('bus_$busId');
    final marker = gmaps.Marker(
      markerId: markerId,
      position: latLng,
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
      infoWindow: gmaps.InfoWindow(
        title: 'Bus $busId',
        snippet: 'Live location',
      ),
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(marker);
    });
  }

  Future<void> _loadMapData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _markers.clear();
        _polylines.clear();
      });

      // Fetch the main config (automatically gets bus details for logged-in staff)
      final mapDataRaw = await MapService.getLiveBusShiftData();

      // If the response is a list, use the first element
      final mapData = (mapDataRaw is List && mapDataRaw.isNotEmpty)
          ? mapDataRaw[0]
          : mapDataRaw;

      print('[DEBUG] mapData: $mapData');

      _mapConfig = MapConfiguration.fromJson(mapData);

      // Set initial camera position
      _initialCameraPosition = gmaps.CameraPosition(
        target: gmaps.LatLng(
          _mapConfig!.initialCameraPosition.latitude,
          _mapConfig!.initialCameraPosition.longitude,
        ),
        zoom: _mapConfig!.initialCameraPosition.zoom,
        bearing: _mapConfig!.initialCameraPosition.bearing,
        tilt: _mapConfig!.initialCameraPosition.tilt,
      );

      // For each geojson layer, fetch and process its features
      for (final layer in _mapConfig!.layers) {
        if (layer.type == 'geojson' && layer.sourceUrl != null) {
          // Replace localhost with production base URL if present
          String sourceUrl = layer.sourceUrl!;
          if (sourceUrl.contains('localhost')) {
            sourceUrl = sourceUrl.replaceFirst('localhost:5176', 'bus-finder-sl-a7c6a549fbb1.herokuapp.com');
            sourceUrl = sourceUrl.replaceFirst('localhost', 'bus-finder-sl-a7c6a549fbb1.herokuapp.com');
            if (!sourceUrl.startsWith('http')) {
              sourceUrl = 'https://' + sourceUrl;
            }
          }
          // Also, if the url starts with http://, change to https://
          if (sourceUrl.startsWith('http://')) {
            sourceUrl = sourceUrl.replaceFirst('http://', 'https://');
          }
          final geoJson = await MapService.fetchGeoJsonFromUrl(sourceUrl);
          if (geoJson.containsKey('features')) {
            _processGeoJSONData(geoJson['features'], layer);
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load map data: $e';
      });
      print('Error loading map data: $e');
    }
  }

  void _processGeoJSONData(List features, MapLayer? layer) {
    for (final feature in features) {
      if (feature['geometry'] == null) continue;

      final geometry = feature['geometry'];
      final geometryType = geometry['type'];
      final coordinates = geometry['coordinates'];

      if (geometryType == 'Point') {
        _addMarker(coordinates, layer);
      } else if (geometryType == 'LineString') {
        // Use road-following polyline for the main route layer
        if (layer != null && layer.id == 'singleBusRouteLayer') {
          _addRoadFollowingPolyline(coordinates, layer);
        } else {
          _addPolyline(coordinates, layer);
        }
      } else if (geometryType == 'MultiLineString') {
        for (final lineCoords in coordinates) {
          if (layer != null && layer.id == 'singleBusRouteLayer') {
            _addRoadFollowingPolyline(lineCoords, layer);
          } else {
            _addPolyline(lineCoords, layer);
          }
        }
      }
    }
  }

  void _addMarker(List coordinates, MapLayer? layer) {
    if (coordinates.length < 2) return;

    final latLng = gmaps.LatLng(
      coordinates[1].toDouble(),
      coordinates[0].toDouble(),
    );

    final marker = gmaps.Marker(
      markerId: gmaps.MarkerId('${layer?.id ?? 'unknown'}_${_markers.length}'),
      position: latLng,
      icon: layer?.renderOptions.markerIconUrl != null
          ? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed)
          : gmaps.BitmapDescriptor.defaultMarker,
      infoWindow: gmaps.InfoWindow(
        title: 'Bus Stop',
        snippet: 'Tap for more info',
      ),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _addPolyline(List coordinates, MapLayer? layer) {
    if (coordinates.length < 2) return;

    final points = coordinates.map((coord) {
      return gmaps.LatLng(
        coord[1].toDouble(),
        coord[0].toDouble(),
      );
    }).toList();

    final polyline = gmaps.Polyline(
      polylineId: gmaps.PolylineId('${layer?.id ?? 'unknown'}_${_polylines.length}'),
      points: points,
      color: _parseColor(layer?.renderOptions.strokeColor ?? '#FF0000'),
      width: layer?.renderOptions.strokeWidth ?? 3,
      geodesic: true,
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = gmaps.LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(latLng, 15.0),
      );
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<List<gmaps.LatLng>> getRoadFollowingRoute({
    required gmaps.LatLng origin,
    required gmaps.LatLng destination,
    required List<gmaps.LatLng> waypoints,
    required String apiKey,
  }) async {
    String waypointsString = waypoints
        .map((w) => '${w.latitude},${w.longitude}')
        .join('|');

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    if (waypoints.isNotEmpty) {
      url += '&waypoints=$waypointsString';
    }

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final points = PolylinePoints().decodePolyline(
        data['routes'][0]['overview_polyline']['points'],
      );
      return points
          .map((p) => gmaps.LatLng(p.latitude, p.longitude))
          .toList();
    } else {
      throw Exception('Directions API error: ${data['status']}');
    }
  }

  Future<void> _addRoadFollowingPolyline(List coordinates, MapLayer? layer) async {
    if (coordinates.length < 2) return;

    final apiKey = _mapConfig?.googleMapsApiKey ?? 'YOUR_API_KEY';
    final origin = gmaps.LatLng(coordinates[0][1], coordinates[0][0]);
    final destination = gmaps.LatLng(coordinates.last[1], coordinates.last[0]);
    final waypoints = coordinates
        .sublist(1, coordinates.length - 1)
        .map<gmaps.LatLng>((c) => gmaps.LatLng(c[1], c[0]))
        .toList();

    try {
      final routePoints = await getRoadFollowingRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        apiKey: apiKey,
      );

      final polyline = gmaps.Polyline(
        polylineId: gmaps.PolylineId('road_route_${_polylines.length}'),
        points: routePoints,
        color: _parseColor(layer?.renderOptions.strokeColor ?? '#FF0000'),
        width: layer?.renderOptions.strokeWidth ?? 3,
        geodesic: false,
      );

      setState(() {
        _polylines.add(polyline);
      });
    } catch (e) {
      print('Directions API error: $e');
      // Fallback: draw straight line
      _addPolyline(coordinates, layer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 🔸 Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            width: double.infinity,
            color: const Color(0xFFFB9933),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Live Map",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Show GPS status and bus number plate
                AnimatedBuilder(
                  animation: _gpsService,
                  builder: (context, child) {
                    return Row(
                      children: [
                        if (_gpsService.targetBusNumberPlate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _gpsService.targetBusNumberPlate!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          _gpsService.isGpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                          color: _gpsService.isGpsEnabled ? Colors.green : Colors.red,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  IconButton(
                    onPressed: _loadMapData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh Map',
                  ),
              ],
            ),
          ),

          // 🔸 GPS Status Banner
          AnimatedBuilder(
            animation: _gpsService,
            builder: (context, child) {
              if (!_gpsService.isGpsEnabled) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red,
                  child: const Text(
                    'GPS is disabled. Location sharing is off.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.green,
                  child: const Text(
                    'GPS enabled. Sharing live location.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              }
            },
          ),

          // 🔸 Map Container
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB9933)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading live map data...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFFB9933),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMapData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB9933),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : gmaps.GoogleMap(
              onMapCreated: (gmaps.GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: _mapConfig?.mapOptions.zoomControlsEnabled ?? true,
              compassEnabled: _mapConfig?.mapOptions.compassEnabled ?? true,
              mapType: _getMapType(_mapConfig?.mapOptions.mapType ?? 'roadmap'),
              onTap: (gmaps.LatLng latLng) {
                // Handle map tap
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _errorMessage == null
          ? FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: const Color(0xFFFB9933),
        child: const Icon(Icons.my_location, color: Colors.white),
      )
          : null,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  gmaps.MapType _getMapType(String mapType) {
    switch (mapType.toLowerCase()) {
      case 'satellite':
        return gmaps.MapType.satellite;
      case 'hybrid':
        return gmaps.MapType.hybrid;
      case 'terrain':
        return gmaps.MapType.terrain;
      default:
        return gmaps.MapType.normal;
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(0, -5), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          IconData icon;
          switch (index) {
            case 0:
              icon = Icons.home;
              break;
            case 1:
              icon = Icons.location_on_outlined;
              break;
            case 2:
              icon = Icons.notifications_none;
              break;
            case 3:
              icon = Icons.grid_view;
              break;
            default:
              icon = Icons.help_outline;
          }

          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () {
              if (index == 1) {
                // Already on Live Map
              } else if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              } else if (index == 2) {
                Navigator.pushNamedAndRemoveUntil(context, 'notification', (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, 'more', (route) => false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomLeft,
                  stops: [0.0, 0.1, 0.5, 0.9, 1.0],
                  colors: [
                    Color(0xFFBD2D01),
                    Color(0xFFCF4602),
                    Color(0xFFF67F00),
                    Color(0xFFCF4602),
                    Color(0xFFBD2D01),
                  ],
                )
                    : null,
                color: isSelected ? null : Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFCF4602),
              ),
            ),
          );
        }),
      ),
    );
  }
}