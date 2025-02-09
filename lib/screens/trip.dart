import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:pokemon_go/providers/ComplaintsProvider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

import 'package:provider/provider.dart';

const googleMapsApiKey = "AIzaSyDdRJkfyUxkJ-R2Ar3af254AmHX0iD9Cy4";

// New initial camera position
final CameraPosition _initialCameraPosition = CameraPosition(
  target: LatLng(19.1231776, 72.8335405), // New location
  zoom: 18,
  tilt: 67.5,
  bearing: 314,
);
/// *List of icon markers*
List<Map<String, dynamic>> iconMarkers = [
  {
    "iconPath": "assets/images/icon1.png",
    "latLng": const LatLng(19.123500, 72.832900),
  },
  {
    "iconPath": "assets/images/icon2.png",
    "latLng": const LatLng(19.124000, 72.833200),
  },
];

/// *Function to Build Only Icon Markers*
Future<Set<Marker>> _buildIconMarkers() async {
  Set<Marker> markers = {};

  for (var iconMarker in iconMarkers) {
    final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(80, 80)),
      iconMarker["iconPath"],
    );

    markers.add(
      Marker(
        markerId: MarkerId(iconMarker["iconPath"]),
        position: iconMarker["latLng"],
        icon: customIcon,
      ),
    );
  }

  return markers;
}

// Custom map style: No buildings
const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.medical",
    "elementType": "labels",
    "stylers": [
      { "visibility": "on" }
    ]
  },
  {
    "featureType": "poi.medical",
    "elementType": "geometry",
    "stylers": [
      { "visibility": "on" },
      { "color": "#ff0000" }
    ]
  },
  {
"featureType": "landscape.man_made",
"elementType": "geometry",
"stylers": [
{ "visibility": "off" }
]
},
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';



class TripPage extends StatefulWidget {
  const TripPage();


  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  final locationController = Location();
  LatLng? currentPosition;
  GoogleMapController? _mapController;
  String? selectedLocationName;
  String? selectedLocationImage;
  LatLng? selectedLocation;
  Map<PolylineId, Polyline> polylines = {};
  BitmapDescriptor? userAvatarIcon;
  BitmapDescriptor? userSpecialIcon;
  CameraPosition _currentCameraPosition = _initialCameraPosition;
  Map<String, BitmapDescriptor> customMarkers = {};
  List<Map<String,dynamic>> locations=[];
  Map<String, BitmapDescriptor> iconMap = {};
  @override
  void initState() {
    super.initState();
    _loadCustomAvatar();
    _loadSpecialAvatar();
    fetchLocations();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initializeMap());
  }

  Future<void> initializeMap() async {
    await fetchLocationUpdates();
  }

  Future<void> _loadCustomAvatar() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(50, 50)),
      "assets/images/avt.png",
    );

    setState(() {
      userAvatarIcon = icon;
    });

    var snapshot = await FirebaseFirestore.instance.collection('complaints').get();

    List<Map<String, dynamic>> fetchedLocations = snapshot.docs.map((doc) {
      return {
        "name": doc['title'],
        "latLng": LatLng(doc['latitude'], doc['longitude']),
        "info": doc['category'],
        "image": doc['imageUrl'],
      };
    }).toList();

    // *Ensure locations are not empty before processing*
    if (fetchedLocations.isEmpty) {
      debugPrint("No locations available to assign icons.");
      return;
    }
    // *Load icon once, not inside loop*
    final customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(80, 80)),
      "assets/images/avt.png",
    );

    // *Assign the same icon to all locations*
    for (var location in fetchedLocations) {
      iconMap[location['name']] = customIcon;
    }

    setState(() {}); // Ensure UI updates after loading icons
  }


  Future<void> _loadSpecialAvatar() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(70, 70)),
      "assets/images/back.jpg",
    );
    setState(() {
      userSpecialIcon = icon;
    });
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });

        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(currentPosition!));
        }
      }
    });
  }

  Future<void> fetchLocations() async {
    var snapshot = await FirebaseFirestore.instance.collection('complaints').get();

    List<Map<String, dynamic>> fetchedLocations = snapshot.docs.map((doc) {
      return {
        "name": doc['title'],
        "latLng": LatLng(doc['latitude'], doc['longitude']),
        "info": doc['category'],
        "image": doc['imageUrl'],
      };
    }).toList();

    // *Add a Static Location Manually*
    // fetchedLocations.add({
    //   "name": "Static Location",
    //   "latLng": const LatLng(19.1230738, 72.8290329), // Set your custom coordinates
    //   "info": "This is a manually added location.",
    //   "image": "https://example.com/static_location_image.jpg", // Optional image
    // });

    setState(() {
      locations = fetchedLocations;
    });

    _generateCustomMarkers(); // Generate markers after updating locations
  }



  Future<void> _generateCustomMarkers() async {
    print("Calling fetchLocations...");

    print("Locations after fetch: ${locations.toString()}");

    if (locations.isEmpty) {
      print("Error: Locations still empty!");
      return;
    }
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(60, 60)),
      "assets/images/avt.png",
    );

    for (var location in locations) {
      final markerIcon = await _createCustomMarker(location['name']);
      customMarkers[location['name']] = markerIcon;
    }

    setState(() {});
  }



  Future<BitmapDescriptor> _createCustomMarker(String title) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const Size size = Size(180, 60);

    final Paint paint = Paint()..color = Colors.white;
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, paint);

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, const Offset(10, 15));

    final img = await pictureRecorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }
  LatLng SpecialavatarPosition = const LatLng(19.123208, 72.8328109);
  Set<Marker> _buildSpecialMarkers() {
    Set<Marker> markers = {};

    // Add other dynamic markers from Firestore
    for (var location in locations) {
      if (customMarkers.containsKey(location['name'])) {
        markers.add(
          Marker(
            markerId: MarkerId(location['name']),
            position: SpecialavatarPosition,
            icon: customMarkers[location['name']]!,
            onTap: () {
              _showLocationInfo(location['name'], location['latLng'], location['image']);
            },
          ),
        );
      }
    }

    // *Add User Avatar at Required Coordinates*
    if (userAvatarIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user_avatar"),
          position: SpecialavatarPosition,  // Set required coordinates
          icon: userAvatarIcon!,
          anchor: const Offset(0.5, 0.5),  // Center the icon properly
          infoWindow: const InfoWindow(title: "User Avatar"),
        ),
      );
    }

    return markers;
  }
  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    for (var location in locations) {
      if (customMarkers.containsKey(location['name'])) {
        markers.add(
          Marker(
            markerId: MarkerId(location['name']),
            position: location['latLng'],
            // icon: customMarkers[location['name']]!,
            icon:iconMap[location['name']]!,
            infoWindow: InfoWindow(title:location['name']),
            onTap: () {
              _showLocationInfo(location['name'], location['latLng'], location['image']);
            },
          ),
        );
      }
    }

    if (currentPosition != null && userAvatarIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user_avatar"),
          position: currentPosition!,
          icon: userAvatarIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return markers;
  }

  void _showLocationInfo(String name, LatLng position, String? imageUrl) {
    setState(() {
      selectedLocationName = name;
      selectedLocation = position;
      selectedLocationImage = imageUrl;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  Future<void> _goToMyLocation() async {
    if (currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(currentPosition!));
    }
  }

  Widget _buildFloatingInfoWindow() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedLocationImage != null)
              CachedNetworkImage(imageUrl: selectedLocationImage!, width: 180, height: 120, fit: BoxFit.cover),
            Text(selectedLocationName!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sky image with fade effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 170,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.0),
                  ],
                  stops: [0.8, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                "assets/images/sky.png",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Map with padding to avoid overlapping sky
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 150),child:GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController!.setMapStyle(_mapStyle);
              },
              initialCameraPosition: _initialCameraPosition,
              markers: _buildMarkers(),
            ),
            ),),
          if (selectedLocationName != null) Positioned(bottom: 20, left: 20, right: 20, child: _buildFloatingInfoWindow()
          )
        ],
      ),

    );
  }
}