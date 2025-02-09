import 'package:flutter/material.dart';
import 'claimhistory.dart';
import 'foundhistory.dart';
import 'searchItem.dart'; // Assuming this file exists

class HomePage extends StatelessWidget {
  final List<Map<String, String>> lostItems = [
    {
      "image": "assets/images/phone.jpg",
      "title": "Claimed Item 1 ",
      "description": "Description of claimed item 1.",
      "latitude": "28.7041",
      "longitude": "77.1025",
      "status": "unresolved", // Example status
    },
    {
      "image": "assets/images/bag.jpg",
      "title": "Claimed Item 2",
      "description": "Description of claimed item 2.",
      "latitude": "28.7041",
      "longitude": "77.1025",
      "status": "unresolved", // Example status
    }
  ];

  final List<Map<String, String>> foundItems = [
    {
      "image": "assets/images/bag.jpg",
      "title": "Claimed Item 1",
      "description": "Description of claimed item 1.",
      "latitude": "28.7041",
      "longitude": "77.1025",
      "status": "unresolved", // Example status
    },
    {
      "image": "assets/images/phone.jpg",
      "title": "Claimed Item 2",
      "description": "Description of claimed item 2.",
      "latitude": "28.7041",
      "longitude": "77.1025",
      "status": "unresolved", // Example status
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make the background transparent
        appBar: AppBar(
          title: Text(
            'LOST AND FOUND',
            style: TextStyle(
                color: Color(0xff3BBD81), fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xffF1F7E8),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.home), text: "Home"),
              Tab(icon: Icon(Icons.search), text: "Search"),
              Tab(icon: Icon(Icons.account_balance_wallet_outlined),
                  text: "Claims"),
              Tab(icon: Icon(Icons.account_balance_wallet), text: "Found"),
              Tab(icon: Icon(Icons.person), text: "Profile"),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/back.jpg', // Replace with your image path
                fit: BoxFit.cover, // Adjusts the image to cover the screen
              ),
            ),

            // Main Content (TabBarView)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TabBarView(
                children: [
                  _buildHomePage(),
                  _buildSearchPage(),
                  _buildInsertPage(),
                  _buildInboxPage(),
                  //_buildProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Green Notification Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Have you lost or found an item?\nWhat should you do now?",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lost Items Section
          const Text("Your lost items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          SizedBox(
            height: 180, // Adjust the height of the sliding row
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lostItems.length,
              itemBuilder: (context, index) {
                var item = lostItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Container(
                    width: 300, // Set a specific width for the card
                    height: 180, // Set the height of the card
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Image and Title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.asset(
                                item['image']!,
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Title
                            Text(
                              item['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10), // Space between image and description
                        // Right Column: Description, Status, and Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description Text (wrapped on new lines)
                              Text(
                                item['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 10),
                              // Status Text
                              Text(
                                'Status: ${item['status']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item['status'] == 'unresolved' ? Colors.red : Colors.green,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Get Details Button with green background and elevation
                              ElevatedButton(
                                onPressed: () {
                                  // Handle the "Get Details" action here.
                                  print('Get details of ${item['title']}');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                ),
                                child: Text(
                                  'Get Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Found Items Section
          const Text("Your found items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 180, // Adjust the height of the sliding row
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lostItems.length,
              itemBuilder: (context, index) {
                var item = lostItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Container(
                    width: 300, // Set a specific width for the card
                    height: 180, // Set the height of the card
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Image and Title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.asset(
                                item['image']!,
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Title
                            Text(
                              item['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10), // Space between image and description
                        // Right Column: Description, Status, and Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description Text (wrapped on new lines)
                              Text(
                                item['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 10),
                              // Status Text
                              Text(
                                'Status: ${item['status']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item['status'] == 'unresolved' ? Colors.red : Colors.green,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Get Details Button with green background and elevation
                              ElevatedButton(
                                onPressed: () {
                                  // Handle the "Get Details" action here.
                                  print('Get details of ${item['title']}');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                ),
                                child: Text(
                                  'Get Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )

        ],
      ),
    );
  }

  Widget _buildSearchPage() {
    return LostAndFoundPage(); // Make sure to create a LostFoundPage widget
  }

  Widget _buildInsertPage() {
    return ClaimHistoryPage();
  }

  Widget _buildInboxPage() {
    return FoundHistoryPage();
  }

  // Widget _buildProfilePage() {
  //   return HomeScreen();
  // }

  Widget _buildItemCard(Map<String, String> item, {bool isFoundItem = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image at the top
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: item["image"] != null
                ? Image.asset(
              item["image"]!,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(color: Colors.grey, height: 100), // Default image if null
          ),

          // Scrollable Column with Padding for text and button
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title of the item
                  Text(
                    item["title"]!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Description of the item
                  Text(
                    item["description"]!,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location (latitude, longitude)
                  Text(
                    "📍 ${item["latitude"]}, ${item["longitude"]}",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
