import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class MapService {
  static const String baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';
  static const String liveBusShiftEndpoint = '/api/Map/staff-view-live-bus-shift';
  static const String futureBusShiftEndpoint = '/api/BusShift/by-route';

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

  // Helper method to extract bus number plate from shift data
  static String? _extractBusNumberPlate(Map<String, dynamic> shiftMap) {
    // Primary field name options for bus number plate
    List<String> primaryFields = [
      'numberPlate',      // This matches your JSON structure
      'NumberPlate',
      'busNumberPlate',
      'BusNumberPlate',
      'busPlate',
      'BusPlate',
      'bus',
      'Bus',
      'busNumber',
      'BusNumber',
      'vehicleNumber',
      'VehicleNumber',
      'plateNumber',
      'PlateNumber',
    ];

    // Check primary level fields first
    for (String field in primaryFields) {
      if (shiftMap.containsKey(field) && shiftMap[field] != null) {
        final value = shiftMap[field].toString().trim();
        if (value.isNotEmpty && value != 'null') {
          print('DEBUG: Found bus plate in field "$field": "$value"');
          return value;
        }
      }
    }

    // Check nested bus object
    final nestedBusFields = ['bus', 'Bus', 'busDetails', 'BusDetails'];
    for (String busField in nestedBusFields) {
      if (shiftMap[busField] is Map<String, dynamic>) {
        final busObj = shiftMap[busField] as Map<String, dynamic>;
        print('DEBUG: Checking nested bus object in "$busField": ${busObj.keys.toList()}');

        for (String field in primaryFields) {
          if (busObj.containsKey(field) && busObj[field] != null) {
            final value = busObj[field].toString().trim();
            if (value.isNotEmpty && value != 'null') {
              print('DEBUG: Found bus plate in nested field "$busField.$field": "$value"');
              return value;
            }
          }
        }
      }
    }

    print('DEBUG: No bus number plate found in shift data. Available fields: ${shiftMap.keys.toList()}');
    return null;
  }

  // Add this method to handle the specific JSON structure you showed
  static List<Map<String, dynamic>> transformShiftResponse(List<dynamic> rawShifts) {
    return rawShifts.map<Map<String, dynamic>>((shift) {
      final shiftMap = shift as Map<String, dynamic>;

      // Transform the nested structure to a flatter structure for easier access
      final transformedShift = <String, dynamic>{
        // Copy all original fields
        ...shiftMap,

        // Add flattened normal direction fields
        if (shiftMap['normal'] != null && shiftMap['normal'] is Map<String, dynamic>) ...{
          'normalStartTime': shiftMap['normal']['startTime'],
          'normalEndTime': shiftMap['normal']['endTime'],
          'normalDate': shiftMap['normal']['date'],
        },

        // Add flattened reverse direction fields
        if (shiftMap['reverse'] != null && shiftMap['reverse'] is Map<String, dynamic>) ...{
          'reverseStartTime': shiftMap['reverse']['startTime'],
          'reverseEndTime': shiftMap['reverse']['endTime'],
          'reverseDate': shiftMap['reverse']['date'],
        },

        // Add route number for consistency
        'routeNumber': shiftMap['routeNo'] ?? shiftMap['RouteNo'] ?? 'N/A',
      };

      return transformedShift;
    }).toList();
  }
// Helper method to format date to YYYY-MM-DD
  static String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

// Helper method to format time to HH:MM:SS
  static String _formatTimeForAPI(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  // Get future bus shifts for the logged-in staff member's assigned bus ONLY (with client-side filtering)
  static Future<List<Map<String, dynamic>>> getFutureBusShifts({
    String? date,
    String? time,
  }) async {
    try {
      print('DEBUG: Starting getFutureBusShifts with client-side filtering');


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

      final busRouteNumber = busDetails['busRouteNumber']!;
      final userBusNumberPlate = busDetails['numberPlate']!;
      print('DEBUG: Using bus route number: $busRouteNumber');
      print('DEBUG: Filtering for user\'s bus number plate: $userBusNumberPlate');


      // Build the endpoint URL
      final baseEndpoint = '$baseUrl$futureBusShiftEndpoint/$busRouteNumber/future';

      // Build query parameters
      Map<String, String> queryParams = {};

      if (date != null && date.isNotEmpty) {
        // If date is already in correct format, use as is, otherwise format it
        if (date.contains('-') && date.length == 10) {
          queryParams['date'] = date;
        } else {
          // Handle conversion from other formats if needed
          try {
            // Try parsing DD/MM/YYYY format
            final parts = date.split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              final parsedDate = DateTime(year, month, day);
              queryParams['date'] = _formatDateForAPI(parsedDate);
            } else {
              queryParams['date'] = date; // Use as is if can't parse
            }
          } catch (e) {
            print('DEBUG: Could not parse date format, using as is: $date');
            queryParams['date'] = date;
          }
        }
        print('DEBUG: Adding date parameter: ${queryParams['date']}');
      }if (time != null && time.isNotEmpty) {
        // If time is already in correct format, use as is, otherwise format it
        if (time.contains(':')) {
          // Already in HH:MM or HH:MM:SS format
          if (time.split(':').length == 2) {
            queryParams['time'] = '$time:00'; // Add seconds if missing
          } else {
            queryParams['time'] = time;
          }
        } else if (time.contains('.')) {
          // Convert HH.MM to HH:MM:SS
          final parts = time.split('.');
          if (parts.length == 2) {
            queryParams['time'] = '${parts[0]}:${parts[1]}:00';
          } else {
            queryParams['time'] = time;
          }
        } else {
          queryParams['time'] = time; // Use as is
        }
        print('DEBUG: Adding time parameter: ${queryParams['time']}');
      }

      // Create URI with query parameters
      final uri = Uri.parse(baseEndpoint).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      print('DEBUG: Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Future bus shifts response status: ${response.statusCode}');
      print('DEBUG: Future bus shifts response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        print('DEBUG: Decoded response type: ${decoded.runtimeType}');

        // Handle both array and single object responses
        List<dynamic> shiftsList;
        if (decoded is List) {
          shiftsList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // If it's a single object, wrap it in a list
          shiftsList = [decoded];
        } else {
          throw Exception('API returned unexpected data format');
        }

        print('DEBUG: Found ${shiftsList.length} total shifts for route $busRouteNumber');

        // Transform the response to handle your JSON structure
        List<Map<String, dynamic>> transformedShifts = transformShiftResponse(shiftsList);

        // CLIENT-SIDE FILTERING BY USER'S SPECIFIC BUS NUMBER PLATE
        List<Map<String, dynamic>> filteredShifts = [];

        for (int index = 0; index < transformedShifts.length; index++) {
          final shift = transformedShifts[index];

          print('DEBUG: Processing shift ${index + 1}: ${shift.keys.toList()}');

          // Check various possible field names for bus identification
          String? shiftBusPlate = _extractBusNumberPlate(shift);

          print('DEBUG: Shift ${index + 1} bus plate: "$shiftBusPlate", User bus plate: "$userBusNumberPlate"');

          // Filter by user's bus number plate (case-insensitive comparison)
          if (shiftBusPlate != null &&
              shiftBusPlate.toLowerCase().trim() == userBusNumberPlate.toLowerCase().trim()) {
            filteredShifts.add(shift);
            print('DEBUG: ✅ Shift ${index + 1} matched user\'s bus - INCLUDED');
          } else {
            print('DEBUG: ❌ Shift ${index + 1} does not match user\'s bus - EXCLUDED');
          }
        }

        print('DEBUG: FILTERING COMPLETE - Found ${filteredShifts.length} shifts for user\'s bus out of ${transformedShifts.length} total shifts');

        // Log each filtered shift for debugging
        for (int i = 0; i < filteredShifts.length; i++) {
          print('DEBUG: User\'s Shift ${i + 1} details: ${filteredShifts[i]}');
        }

        return filteredShifts;
      } else {
        print('DEBUG: Failed to load future bus shifts - status: ${response.statusCode}');
        throw Exception('Failed to load future bus shifts: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Exception in getFutureBusShifts: $e');
      throw Exception('Error fetching future bus shifts: $e');
    }
  }


  // Alternative method that accepts custom route number (for flexibility) - also with filtering
  static Future<List<Map<String, dynamic>>> getFutureBusShiftsByRoute(
      String routeNumber, {
        String? date,
        String? time,
        bool filterByUserBus = false,
      }) async {
    try {
      print('DEBUG: Starting getFutureBusShiftsByRoute with route: $routeNumber, filterByUserBus: $filterByUserBus');

      String? userBusNumberPlate;

      // If filtering is enabled, get user's bus details
      if (filterByUserBus) {
        final email = await UserService.getStaffEmail();
        if (email == null || email.isEmpty || email == 'N/A') {
          throw Exception('Staff email not found for filtering. Please ensure you are logged in.');
        }

        final staffId = await getStaffIdByEmail(email);
        if (staffId == null || staffId.isEmpty) {
          throw Exception('Failed to get staff ID for filtering.');
        }

        final busDetails = await getBusDetailsByStaffId(staffId);
        if (busDetails == null) {
          throw Exception('No bus assigned to staff for filtering.');
        }

        userBusNumberPlate = busDetails['numberPlate']!;
        print('DEBUG: Will filter by user\'s bus: $userBusNumberPlate');
      }

      // Build the endpoint URL
      final baseEndpoint = '$baseUrl$futureBusShiftEndpoint/$routeNumber/future';

      // Build query parameters with correct formatting
      Map<String, String> queryParams = {};

      if (date != null && date.isNotEmpty) {
        // If date is already in correct format, use as is, otherwise format it
        if (date.contains('-') && date.length == 10) {
          queryParams['date'] = date;
        } else {
          // Handle conversion from other formats if needed
          try {
            // Try parsing DD/MM/YYYY format
            final parts = date.split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              final parsedDate = DateTime(year, month, day);
              queryParams['date'] = _formatDateForAPI(parsedDate);
            } else {
              queryParams['date'] = date; // Use as is if can't parse
            }
          } catch (e) {
            print('DEBUG: Could not parse date format, using as is: $date');
            queryParams['date'] = date;
          }
        }
        print('DEBUG: Adding date parameter: ${queryParams['date']}');
      }

      if (time != null && time.isNotEmpty) {
        // If time is already in correct format, use as is, otherwise format it
        if (time.contains(':')) {
          // Already in HH:MM or HH:MM:SS format
          if (time.split(':').length == 2) {
            queryParams['time'] = '$time:00'; // Add seconds if missing
          } else {
            queryParams['time'] = time;
          }
        } else if (time.contains('.')) {
          // Convert HH.MM to HH:MM:SS
          final parts = time.split('.');
          if (parts.length == 2) {
            queryParams['time'] = '${parts[0]}:${parts[1]}:00';
          } else {
            queryParams['time'] = time;
          }
        } else {
          queryParams['time'] = time; // Use as is
        }
        print('DEBUG: Adding time parameter: ${queryParams['time']}');
      }

      // Create URI with query parameters
      final uri = Uri.parse(baseEndpoint).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      print('DEBUG: Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Future bus shifts response status: ${response.statusCode}');
      print('DEBUG: Future bus shifts response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        print('DEBUG: Decoded response type: ${decoded.runtimeType}');

        // Handle both array and single object responses
        List<dynamic> shiftsList;
        if (decoded is List) {
          shiftsList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // If it's a single object, wrap it in a list
          shiftsList = [decoded];
        } else {
          throw Exception('API returned unexpected data format');
        }

        print('DEBUG: Found ${shiftsList.length} future shifts for route $routeNumber');

        // Transform the response to handle your JSON structure
        List<Map<String, dynamic>> transformedShifts = transformShiftResponse(shiftsList);

        // Apply filtering if enabled
        if (filterByUserBus && userBusNumberPlate != null) {
          List<Map<String, dynamic>> filteredResult = [];

          for (int index = 0; index < transformedShifts.length; index++) {
            final shiftMap = transformedShifts[index];
            String? shiftBusPlate = _extractBusNumberPlate(shiftMap);

            if (shiftBusPlate != null &&
                shiftBusPlate.toLowerCase().trim() == userBusNumberPlate.toLowerCase().trim()) {
              filteredResult.add(shiftMap);
            }
          }

          print('DEBUG: Filtered ${transformedShifts.length} shifts down to ${filteredResult.length} for user\'s bus');
          transformedShifts = filteredResult;
        }

        // Log each shift for debugging
        for (int i = 0; i < transformedShifts.length; i++) {
          print('DEBUG: Final Shift ${i + 1}: ${transformedShifts[i]}');
        }

        return transformedShifts;
      } else {
        print('DEBUG: Failed to load future bus shifts - status: ${response.statusCode}');
        throw Exception('Failed to load future bus shifts: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Exception in getFutureBusShiftsByRoute: $e');
      throw Exception('Error fetching future bus shifts: $e');
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