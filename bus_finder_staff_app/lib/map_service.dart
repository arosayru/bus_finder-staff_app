import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class MapService {
  static const String baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';
  static const String liveBusShiftEndpoint = '/api/Map/staff-view-live-bus-shift';

  // Fetch live bus shift data for a specific bus and route (hardcoded for testing)
  static Future<Map<String, dynamic>> getLiveBusShiftData({
    String? busRoute,
    String? bus,
  }) async {
    try {
      // Hardcoded endpoint for testing
      final uri = Uri.parse(
        '$baseUrl$liveBusShiftEndpoint?busRoute=174&bus=BN%20-%201315',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status:  [${response.statusCode}');
      print('Response body:  [${response.body}');

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
