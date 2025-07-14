import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'user_service.dart';

class MapService {
  static const String baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';
  static const String liveBusShiftEndpoint = '/api/Map/staff-view-live-bus-shift';

  // Get staff ID by email
  static Future<String?> getStaffIdByEmail(String email) async {
    try {
      final idUrl = Uri.parse('$baseUrl/api/Staff/get-id-by-email/$email');
      final idResponse = await http.get(idUrl);
      if (idResponse.statusCode == 200) {
        final idData = jsonDecode(idResponse.body);
        return idData['staffId']?.toString() ?? idData['StaffID']?.toString();
      }
      return null;
    } catch (e) {
      print('Error getting staff ID by email: $e');
      return null;
    }
  }

  // Get bus details by staff ID
  static Future<Map<String, String>?> getBusDetailsByStaffId(String staffId) async {
    try {
      final busUrl = Uri.parse('$baseUrl/api/Bus/by-staff/$staffId');
      print('DEBUG: Fetching bus details from: $busUrl');

      final busResponse = await http.get(busUrl);
      print('DEBUG: Bus details response status: ${busResponse.statusCode}');
      print('DEBUG: Bus details response body: ${busResponse.body}');

      if (busResponse.statusCode == 200) {
        final responseData = jsonDecode(busResponse.body);
        print('DEBUG: Parsed response data: $responseData');

        // Handle both array and single object responses
        List<dynamic> busList;
        if (responseData is List) {
          busList = responseData;
        } else {
          busList = [responseData];
        }

        print('DEBUG: Bus list length: ${busList.length}');

        if (busList.isNotEmpty) {
          // Use the first bus in the list
          final busData = busList[0];
          print('DEBUG: Using first bus data: $busData');

          // Filter only numberPlate and busRouteNumber
          String? numberPlate;
          String? busRouteNumber;

          // Handle different possible field names
          numberPlate = busData['numberPlate']?.toString() ??
              busData['NumberPlate']?.toString() ??
              busData['number_plate']?.toString();

          busRouteNumber = busData['busRouteNumber']?.toString() ??
              busData['BusRouteNumber']?.toString() ??
              busData['bus_route_number']?.toString();

          print('DEBUG: Extracted numberPlate: $numberPlate');
          print('DEBUG: Extracted busRouteNumber: $busRouteNumber');

          if (numberPlate != null && busRouteNumber != null) {
            return {
              'numberPlate': numberPlate,
              'busRouteNumber': busRouteNumber,
            };
          } else {
            print('DEBUG: Missing required bus details - numberPlate: $numberPlate, busRouteNumber: $busRouteNumber');
          }
        } else {
          print('DEBUG: No buses found in the response');
        }
      } else {
        print('DEBUG: Failed to get bus details - status: ${busResponse.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error getting bus details by staff ID: $e');
      return null;
    }
  }

  // Fetch live bus shift data for the logged-in staff member
  static Future<Map<String, dynamic>> getLiveBusShiftData() async {
    try {
      print('DEBUG: Starting getLiveBusShiftData - automatic mode');

      // Get staff email from UserService
      final email = await UserService.getStaffEmail();
      print('DEBUG: Retrieved staff email: $email');

      if (email == null || email.isEmpty || email == 'N/A') {
        throw Exception('Staff email not found. Please ensure you are logged in.');
      }

      // Get staff ID by email
      final staffId = await getStaffIdByEmail(email);
      print('DEBUG: Retrieved staff ID: $staffId');

      if (staffId == null || staffId.isEmpty) {
        throw Exception('Failed to get staff ID for email: $email');
      }

      // Get bus details by staff ID
      final busDetails = await getBusDetailsByStaffId(staffId);
      print('DEBUG: Retrieved bus details: $busDetails');

      if (busDetails == null) {
        throw Exception('No bus assigned to staff ID: $staffId');
      }

      final numberPlate = busDetails['numberPlate']!;
      final busRouteNumber = busDetails['busRouteNumber']!;

      print('DEBUG: Using bus details - Number Plate: $numberPlate, Route: $busRouteNumber');

      // Build the endpoint with the actual bus details
      final uri = Uri.parse(
        '$baseUrl$liveBusShiftEndpoint?busRoute=$busRouteNumber&bus=${Uri.encodeComponent(numberPlate)}',
      );

      print('DEBUG: Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! Map<String, dynamic>) {
          throw Exception('API did not return a valid map');
        }
        return decoded;
      } else {
        throw Exception('Failed to load live bus shift data: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Exception in getLiveBusShiftData: $e');
      throw Exception('Error fetching live bus shift data: $e');
    }
  }

  // Legacy method for backward compatibility (keeps the old signature)
  static Future<Map<String, dynamic>> getLiveBusShiftDataWithParams({
    String? busRoute,
    String? bus,
  }) async {
    try {
      // Use provided parameters or fall back to automatic detection
      String? finalBusRoute = busRoute;
      String? finalBus = bus;

      if (finalBusRoute == null || finalBus == null) {
        // Get staff email from UserService
        final email = await UserService.getStaffEmail();
        if (email == null || email.isEmpty || email == 'N/A') {
          throw Exception('Staff email not found. Please ensure you are logged in.');
        }

        // Get staff ID by email
        final staffId = await getStaffIdByEmail(email);
        if (staffId == null || staffId.isEmpty) {
          throw Exception('Failed to get staff ID for email: $email');
        }

        // Get bus details by staff ID
        final busDetails = await getBusDetailsByStaffId(staffId);
        if (busDetails == null) {
          throw Exception('No bus assigned to staff ID: $staffId');
        }

        finalBusRoute = busDetails['busRouteNumber'];
        finalBus = busDetails['numberPlate'];
      }

      final uri = Uri.parse(
        '$baseUrl$liveBusShiftEndpoint?busRoute=$finalBusRoute&bus=${Uri.encodeComponent(finalBus!)}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! Map<String, dynamic>) {
          throw Exception('API did not return a valid map');
        }
        return decoded;
      } else {
        throw Exception('Failed to load live bus shift data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching live bus shift data: $e');
    }
  }

  // Fetch GeoJSON data for bus stops
  static Future<Map<String, dynamic>> getBusStopsGeoJSON() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/busstop/geojson'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load bus stops data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bus stops data: $e');
    }
  }

  // Fetch GeoJSON data for bus routes
  static Future<Map<String, dynamic>> getBusRoutesGeoJSON() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/busroute/single/geojson'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load bus routes data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bus routes data: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchGeoJsonFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch GeoJSON from $url');
    }
  }
}

// Data models for map configuration
class MapConfiguration {
  final String googleMapsApiKey;
  final CameraPosition initialCameraPosition;
  final MapOptions mapOptions;
  final List<MapLayer> layers;

  MapConfiguration({
    required this.googleMapsApiKey,
    required this.initialCameraPosition,
    required this.mapOptions,
    required this.layers,
  });

  factory MapConfiguration.fromJson(Map<String, dynamic> json) {
    return MapConfiguration(
      googleMapsApiKey: json['googleMapsApiKey'] ?? '',
      initialCameraPosition: CameraPosition.fromJson(json['initialCameraPosition']),
      mapOptions: MapOptions.fromJson(json['mapOptions']),
      layers: (json['layers'] as List)
          .map((layer) => MapLayer.fromJson(layer))
          .toList(),
    );
  }
}

class CameraPosition {
  final double latitude;
  final double longitude;
  final double zoom;
  final double bearing;
  final double tilt;

  CameraPosition({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.bearing,
    required this.tilt,
  });

  factory CameraPosition.fromJson(Map<String, dynamic> json) {
    return CameraPosition(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      zoom: json['zoom']?.toDouble() ?? 12.0,
      bearing: json['bearing']?.toDouble() ?? 0.0,
      tilt: json['tilt']?.toDouble() ?? 0.0,
    );
  }
}

class MapOptions {
  final String mapType;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool myLocationButtonEnabled;
  final bool trafficEnabled;
  final bool indoorEnabled;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool zoomGesturesEnabled;
  final List<Map<String, dynamic>> styles;

  MapOptions({
    required this.mapType,
    required this.zoomControlsEnabled,
    required this.compassEnabled,
    required this.myLocationButtonEnabled,
    required this.trafficEnabled,
    required this.indoorEnabled,
    required this.rotateGesturesEnabled,
    required this.scrollGesturesEnabled,
    required this.tiltGesturesEnabled,
    required this.zoomGesturesEnabled,
    required this.styles,
  });

  factory MapOptions.fromJson(Map<String, dynamic> json) {
    return MapOptions(
      mapType: json['mapType'] ?? 'roadmap',
      zoomControlsEnabled: json['zoomControlsEnabled'] ?? true,
      compassEnabled: json['compassEnabled'] ?? true,
      myLocationButtonEnabled: json['myLocationButtonEnabled'] ?? true,
      trafficEnabled: json['trafficEnabled'] ?? true,
      indoorEnabled: json['indoorEnabled'] ?? false,
      rotateGesturesEnabled: json['rotateGesturesEnabled'] ?? true,
      scrollGesturesEnabled: json['scrollGesturesEnabled'] ?? true,
      tiltGesturesEnabled: json['tiltGesturesEnabled'] ?? true,
      zoomGesturesEnabled: json['zoomGesturesEnabled'] ?? true,
      styles: List<Map<String, dynamic>>.from(json['styles'] ?? []),
    );
  }
}

class MapLayer {
  final String id;
  final String type;
  final String? sourceUrl;
  final String? signalRHubUrl;
  final LayerRenderOptions renderOptions;

  MapLayer({
    required this.id,
    required this.type,
    this.sourceUrl,
    this.signalRHubUrl,
    required this.renderOptions,
  });

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    return MapLayer(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      sourceUrl: json['sourceUrl'],
      signalRHubUrl: json['signalRHubUrl'],
      renderOptions: LayerRenderOptions.fromJson(json['renderOptions'] ?? {}),
    );
  }
}

class LayerRenderOptions {
  final String? markerIconUrl;
  final bool? clusterMarkers;
  final String? strokeColor;
  final int? strokeWidth;
  final double? strokeOpacity;
  final bool? followRoads;
  final bool? animateMovement;

  LayerRenderOptions({
    this.markerIconUrl,
    this.clusterMarkers,
    this.strokeColor,
    this.strokeWidth,
    this.strokeOpacity,
    this.followRoads,
    this.animateMovement,
  });

  factory LayerRenderOptions.fromJson(Map<String, dynamic> json) {
    return LayerRenderOptions(
      markerIconUrl: json['markerIconUrl'],
      clusterMarkers: json['clusterMarkers'],
      strokeColor: json['strokeColor'],
      strokeWidth: json['strokeWidth'],
      strokeOpacity: json['strokeOpacity']?.toDouble(),
      followRoads: json['followRoads'],
      animateMovement: json['animateMovement'],
    );
  }
}