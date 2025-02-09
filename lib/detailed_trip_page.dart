import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Define the Trip request model.
class Trip {
  final String source;
  final String destination;
  final String budget;
  final String duration;
  final bool communityColab;

  Trip({
    required this.source,
    required this.destination,
    required this.budget,
    required this.duration,
    required this.communityColab,
  });

  Map<String, dynamic> toJson() {
    return {
      "source": source,
      "destination": destination,
      "budget": budget,
      "duration": duration,
      "community_colab": communityColab,
    };
  }
}

// Model for the TripPlan response.
// (Assuming the JSON response structure is: { "trip_plan": { "trip_plan": { ... } } })
class TripPlan {
  final String title;
  final String summary;
  final String accommodation;
  final String transportation;
  final String estimatedCostsPerDay;
  final String localTips;
  final List<dynamic> dailyPlan;

  TripPlan({
    required this.title,
    required this.summary,
    required this.accommodation,
    required this.transportation,
    required this.estimatedCostsPerDay,
    required this.localTips,
    required this.dailyPlan,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    final inner = json["trip_plan"]["trip_plan"];
    return TripPlan(
      title: inner["title"],
      summary: inner["summary"],
      accommodation: inner["accommodation"],
      transportation: inner["transportation"],
      estimatedCostsPerDay: inner["estimated_costs_per_day"],
      localTips: inner["local_tips"],
      dailyPlan: inner["daily_plan"],
    );
  }
}

// Function to fetch the trip plan from the backend.
Future<TripPlan> fetchTripPlan(Trip trip) async {
  final url = Uri.parse("https://0a28-2409-40c0-105d-9906-152b-e4ea-fef5-ba5c.ngrok-free.app/generate_trip_plan");
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(trip.toJson()),
  );
  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    return TripPlan.fromJson(jsonResponse);
  } else {
    throw Exception("Failed to fetch trip plan");
  }
}

class TripPlanScreen extends StatefulWidget {
  final Trip trip;
  const TripPlanScreen({Key? key, required this.trip}) : super(key: key);

  @override
  _TripPlanScreenState createState() => _TripPlanScreenState();
}

class _TripPlanScreenState extends State<TripPlanScreen> {
  late Future<TripPlan> futureTripPlan;

  @override
  void initState() {
    super.initState();
    futureTripPlan = fetchTripPlan(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trip Planner"),
      ),
      body: FutureBuilder<TripPlan>(
        future: futureTripPlan,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final tripPlan = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Summary Section
                  Text(tripPlan.title, style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text(tripPlan.summary, style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 16),
                  // Accommodation Card
                  _buildCard("Accommodation", tripPlan.accommodation),
                  SizedBox(height: 16),
                  // Transportation Card
                  _buildCard("Transportation", tripPlan.transportation),
                  SizedBox(height: 16),
                  // Daily Plan Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Daily Plan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ...tripPlan.dailyPlan.map((day) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Day ${day["day"]}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ...List<Widget>.from((day["activities"] as List<dynamic>).map((activity) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Text("• $activity", style: TextStyle(fontSize: 16)),
                                    );
                                  })),
                                  SizedBox(height: 4),
                                  Text("Estimated Cost: ${day["estimated_cost"]}", style: TextStyle(fontStyle: FontStyle.italic)),
                                  SizedBox(height: 4),
                                  Text("Tips: ${day["local_tips"]}", style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Estimated Costs Card
                  _buildCard("Estimated Costs per Day", tripPlan.estimatedCostsPerDay),
                  SizedBox(height: 16),
                  // Local Tips Card
                  _buildCard("Local Tips", tripPlan.localTips),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Helper widget to build a styled card.
  Widget _buildCard(String title, String content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(content, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
