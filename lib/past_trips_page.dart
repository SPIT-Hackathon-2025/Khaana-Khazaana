import 'package:flutter/material.dart';

class   PastTripsPage
 extends StatelessWidget {
  final Map<String, dynamic> trip;
  const   PastTripsPage
({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trip["title"])),
      body: Column(
        children: [
          Image.asset(trip["image"], width: double.infinity, height: 250, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip["title"], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("📍 ${trip["location"]}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(trip["description"], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Text("💰 ${trip["price"]}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
