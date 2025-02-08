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

// Custom map style: No buildings
const String _mapStyle = '''
[
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';



class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage();


  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final locationController = Location();
  LatLng? currentPosition;
  GoogleMapController? _mapController;
  String? selectedLocationName;
  String? selectedLocationImage;
  LatLng? selectedLocation;
  Map<PolylineId, Polyline> polylines = {};
  BitmapDescriptor? userAvatarIcon;
  CameraPosition _currentCameraPosition = _initialCameraPosition;
  Map<String, BitmapDescriptor> customMarkers = {};
  List<Map<String,dynamic>> locations=[];
  @override
  void initState() {
    super.initState();
    _loadCustomAvatar();
    fetchLocations();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initializeMap());
  }

  Future<void> initializeMap() async {
    await fetchLocationUpdates();
  }

  Future<void> _loadCustomAvatar() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(70, 70)),
      "assets/images/avt.png",
    );
    setState(() {
      userAvatarIcon = icon;
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
    var snapshot = await FirebaseFirestore.instance.collection('complaints').get(); // Fetch once
    print("Firestore data fetched");

    setState(() {
      locations = snapshot.docs.map((doc) {
        return {
          "name": doc['title'],
          "latLng": LatLng(doc['latitude'], doc['longitude']),
          "info": doc['category'],
          "image": doc['imageUrl'],
        };
      }).toList();
    });

    print("Locations: $locations");
    _generateCustomMarkers();
  }


  Future<void> _generateCustomMarkers() async {
    print("Calling fetchLocations...");

    print("Locations after fetch: ${locations.length}");

    if (locations.isEmpty) {
      print("Error: Locations still empty!");
      return;
    }

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

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    for (var location in locations) {
      if (customMarkers.containsKey(location['name'])) {
        markers.add(
          Marker(
            markerId: MarkerId(location['name']),
            position: location['latLng'],
            icon: customMarkers[location['name']]!,
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
