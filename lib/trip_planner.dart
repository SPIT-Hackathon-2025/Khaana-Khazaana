import 'package:flutter/material.dart';
import 'detailed_trip_page.dart';
import 'past_trips_page.dart';
import 'current_trip_page.dart';

class TripPlannerPage extends StatefulWidget {
  @override
  _TripPlannerPageState createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController daysController = TextEditingController(); // Input for number of days
  double budget = 500; // Default budget
  bool communityCollab = false;

  // Sample trips for list view remain unchanged.
  // Sample trips for list view remain unchanged.
  List<Map<String, dynamic>> trips = [
    {
      "title": "Exploring Bali",
      "image": "assets/images/bali.jpg",
      "price": "\$1200",
      "rating": 4.8,
      "duration": "7 Days",
      "location": "Bali, Indonesia",
      "description": "A week-long adventure in Bali, enjoying beaches, temples, and local food.",
    },
    {
      "title": "Paris Getaway",
      "image": "assets/images/paris.png",
      "price": "\$1500",
      "rating": 4.9,
      "duration": "5 Days",
      "location": "Paris, France",
      "description": "Explore Paris, visit the Eiffel Tower, Louvre, and experience French cuisine.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void generateAIPlan() {
    // Validate that all necessary fields are filled in.
    if (sourceController.text.isEmpty ||
        destinationController.text.isEmpty ||
        daysController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required to generate a trip plan.")),
      );
      return;
    }

    final Trip userTrip = Trip(
      source: sourceController.text,
      destination: destinationController.text,
      budget:"\$$budget",
      duration:"${daysController.text} Days",
      communityColab: communityCollab,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("AI is generating the best trip plan for you...")),
    );

    // Redirect to Detailed Plan Page with user input.
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TripPlanScreen(trip: userTrip)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      // **Custom AppBar with Curved Bottom**
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration:  BoxDecoration(
            color: Colors.green[300],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Trip Planner",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  // **Tab Bar for Navigation**
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(icon: Icon(Icons.home), text: "Explore"),
                      Tab(icon: Icon(Icons.history), text: "Past Trips"),
                      Tab(icon: Icon(Icons.flight_takeoff), text: "Current Trip"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          // **Home / Trip Planning Page**
          SingleChildScrollView(
            child: Column(
              children: [
                // **Trip Planning UI**
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // **Source & Destination Input**
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sourceController,
                              decoration: InputDecoration(
                                labelText: "Source",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: destinationController,
                              decoration: InputDecoration(
                                labelText: "Destination",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // **Days Input Field**
                      TextField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Number of Days",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // **Budget Slider**
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Budget:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("\$${budget.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        min: 100,
                        max: 5000,
                        divisions: 50,
                        value: budget,
                        onChanged: (val) {
                          setState(() {
                            budget = val;
                          });
                        },
                      ),
                      // **Community Collaboration Toggle**
                      SwitchListTile(
                        title: const Text("Community Collaboration", style: TextStyle(fontSize: 16)),
                        value: communityCollab,
                        onChanged: (val) {
                          setState(() {
                            communityCollab = val;
                          });
                        },
                      ),
                      // **Generate AI Plan Button**
                      ElevatedButton.icon(
                        onPressed: generateAIPlan,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Generate AI Plan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[300],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // **Trips List (Fixed Overflow)**
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    var trip = trips[index];
                    return GestureDetector(
                      onTap: () {

                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Image.asset(trip["image"], width: 120, height: 120, fit: BoxFit.cover),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trip["title"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(trip["location"], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(trip["price"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // **Past Trips Page**
          PastTripsPage(trip: {
            "title": "Exploring Bali",
            "image": "assets/images/bali.jpg",
            "price": "\$1200",
            "rating": 4.8,
            "duration": "7 Days",
            "location": "Bali, Indonesia",
            "description": "A week-long adventure in Bali, enjoying beaches, temples, and local food.",
          },),
          // **Current Trip Page**
          CurrentTripPage(trip: {
            "title": "Paris Getaway",
            "image": "assets/images/paris.png",
            "price": "\$1500",
            "rating": 4.9,
            "duration": "5 Days",
            "location": "Paris, France",
            "description": "Explore Paris, visit the Eiffel Tower, Louvre, and experience French cuisine.",
          },),
        ],
      ),
    );
  }
}
