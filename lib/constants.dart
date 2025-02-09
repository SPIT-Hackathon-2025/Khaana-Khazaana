import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const url =
    "https://0a28-2409-40c0-105d-9906-152b-e4ea-fef5-ba5c.ngrok-free.app";
Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

List<Map<String, dynamic>> locations = [
  {
    "name": "R City",
    "latLng": LatLng(19.0945902, 72.9421997),
    "info": "Famous landmark",
    'image':
        'https://media.geeksforgeeks.org/wp-content/uploads/20191016135223/What-is-Algorithm_.jpg'
  },
  {
    "name": "Taj Trees",
    "latLng": LatLng(19.0946016, 72.9422359),
    "info": "Iconic tower",
    'image':
        'https://media.geeksforgeeks.org/wp-content/uploads/20191016135223/What-is-Algorithm_.jpg',
  },
  {
    "name": "Powai Lake",
    "latLng": LatLng(19.1103994, 72.9237242),
    "info": "Beautiful lake",
    'image':
        'https://media.geeksforgeeks.org/wp-content/uploads/20191016135223/What-is-Algorithm_.jpg',
  },
];
