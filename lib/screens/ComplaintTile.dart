import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../constants.dart';
import '../main.dart';
import 'DiscussionScreen.dart';

class ComplaintsFeedScreen extends StatefulWidget {
  @override
  _ComplaintsFeedScreenState createState() => _ComplaintsFeedScreenState();
}

class _ComplaintsFeedScreenState extends State<ComplaintsFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentLoc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    Position position = await determinePosition();
    setState(() {
      _currentLoc = position;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Latest Complaints',
          style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          indicatorColor: Colors.green[900],
          controller: _tabController,
          labelColor: Colors.green[900],
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Local'),
            Tab(text: 'Global'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/back.jpg',
              fit: BoxFit.cover,
            ),
          ),
          (_isLoading)
              ? Center(child: CircularProgressIndicator(color: Colors.green[900]))
              : TabBarView(
            controller: _tabController,
            children: [
              ComplaintsList(type: 'local', currentLocation: _currentLoc),
              ComplaintsList(type: 'global', currentLocation: _currentLoc),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[900],
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddComplaintScreen()),
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ComplaintsList extends StatelessWidget {
  final String type;
  final Position? currentLocation;

  ComplaintsList({required this.type, required this.currentLocation});

  double getRadius() {
    return type == "local" ? 50.0 : 100.0; // Local has a smaller range
  }

  bool isWithinRadius(double latitude, double longitude, Position currentLocation, double radius) {
    double distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      latitude,
      longitude,
    );
    return distance <= radius;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("An Error Occurred!"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          double latitude = doc['latitude'];
          double longitude = doc['longitude'];
          return isWithinRadius(latitude, longitude, currentLocation!, getRadius());
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("No complaints found!"));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredDocs[index];

            // 🔹 **First complaint is shown as a large tile**
            if (index == 0) {
              return LargeComplaintTile(doc: doc);
            }

            // 🔹 **Rest are smaller tiles**
            return SmallComplaintTile(doc: doc);
          },
        );
      },
    );
  }
}

class LargeComplaintTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  LargeComplaintTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return DiscussionScreen(postId: doc.id);
        }));
      },
      child: Card(
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                doc['imageUrl'],
                fit: BoxFit.cover,
                height: 220,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc['title'],
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 18),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          doc['latitude'].toString(),
                          style: TextStyle(color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallComplaintTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  SmallComplaintTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return DiscussionScreen(postId: doc.id);
        }));
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              doc['imageUrl'],
              fit: BoxFit.cover,
              width: 80,
              height: 80,
            ),
          ),
          title: Text(doc['title'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  doc['latitude'].toString(),
                  style: TextStyle(color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
