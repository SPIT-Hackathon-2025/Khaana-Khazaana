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
  zoom: 16,
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
      const ImageConfiguration(size: Size(70, 70)),
      "assets/images/ash.png",
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
    fetchedLocations.add({
      "name": "Found samsung s23",
      "latLng": const LatLng(19.1230738, 72.8290329), // Set your custom coordinates
      "info": "This is a manually added location.",
      "image": "https://m.media-amazon.com/images/I/61isPIHrHgL.SX679.jpg", // Optional image
    });
    fetchedLocations.add({
      "name": "JOHTO GYM",
      "latLng": const LatLng(19.1274009,72.8299478), // Set your custom coordinates
      "info": "JOHTO GYM",
      "image": "https://vignette.wikia.nocookie.net/pokemon/images/2/29/Gym_Leader_file.png/revision/latest?cb=20180602212712", // Optional image
    });

    // *Load icon once, not inside loop*
    final customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(80, 80)),
      "assets/images/avt.png",
    );
    final customIco = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(80, 80)),
      "assets/images/gym.jpg",
    );
    final customIcoi = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(80, 80)),
      "assets/images/char.png",
    );

    // *Assign the same icon to all locations*
    int i=0;
    for (var location in fetchedLocations) {
      if(i%2==0){
        iconMap[location['name']] = customIcon;
      }else{
        iconMap[location['name']] = customIco;
      }
      i++;
    }
    iconMap['Found samsung s23'] = customIcoi;
    iconMap['JOHTO GYM'] = customIco;
    locations=fetchedLocations;
    setState(() {

    }); // Ensure UI updates after loading icons
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
    fetchedLocations.add({
      "name": "JOHTO GYM",
      "latLng": const LatLng(19.1274009,72.8299478), // Set your custom coordinates
      "info": "JOHTO GYM",
      "image": "https://m.media-amazon.com/images/I/61isPIHrHgL.SX679.jpg", // Optional image
    });
    fetchedLocations.add({
      "name": "Found samsung s23",
      "latLng": const LatLng(19.1230738, 72.8290329), // Set your custom coordinates
      "info": "This is a manually added location.",
      "image": "https://m.media-amazon.com/images/I/61isPIHrHgL.SX679.jpg", // Optional image
    });

    setState(() {
      locations = fetchedLocations;
    });

    _generateCustomMarkers(); // Generate markers after updating locations
  }

  Future<void> _getDirections() async {
    if (currentPosition == null || selectedLocation == null) return;
    debugPrint('hi');
    debugPrint(currentPosition.toString());
    debugPrint(selectedLocation.toString());
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleMapsApiKey,
      request: PolylineRequest(
        origin: PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
        destination: PointLatLng(selectedLocation!.latitude, selectedLocation!.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      _generatePolyline(polylineCoordinates);
    } else {
      debugPrint("Failed to fetch route: ${result.errorMessage}");
    }
  }

  void _generatePolyline(List<LatLng> polylineCoordinates) {
    const polylineId = PolylineId('route');
    final polyline = Polyline(
      polylineId: polylineId,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() {
      polylines[polylineId] = polyline;
    });
  }

  Widget _buildFloatingInfoWindow() {
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedLocationImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: selectedLocationImage!,
                  width: 120,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              selectedLocationName!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Lat: ${selectedLocation!.latitude}, Lng: ${selectedLocation!.longitude}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedLocationName = null;
                      selectedLocation = null;
                      selectedLocationImage = null;
                      polylines.clear();
                    });
                  },
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  onPressed: _getDirections,
                  child: const Text("Get Directions"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCustomMarkers() async {
    print("Calling fetchLocations...");

    print("Locations after fetch: ${locations.toString()}");

    if (locations.isEmpty) {
      print("Error: Locations still empty!");
      return;
    }
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(70, 70)),
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
      debugPrint(location['latLng'].toString()+iconMap.toString());
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

  // Widget _buildFloatingInfoWindow() {
  //   return Card(
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(10),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           if (selectedLocationImage != null)
  //             CachedNetworkImage(imageUrl: selectedLocationImage!, width: 180, height: 120, fit: BoxFit.cover),
  //           Text(selectedLocationName!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
              polylines: Set<Polyline>.of(polylines.values),
            ),
            ),),
          if (selectedLocationName != null) Positioned(bottom: 20, left: 20, right: 20, child: _buildFloatingInfoWindow()
          )
        ],
      ),

    );
  }
}