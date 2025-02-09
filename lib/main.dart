import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pokemon_go/screens/DiscussionScreen.dart';
import 'package:pokemon_go/screens/MapScreen.dart';
import 'package:pokemon_go/screens/ProfileInfoScreen.dart';
import 'package:pokemon_go/screens/aniket/lostandfound.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import 'package:workmanager/workmanager.dart';

import 'constants.dart';
import 'providers/ComplaintsProvider.dart';
import 'screens/HomeScreen.dart';
import 'screens/SignupScreen.dart';
import 'screens/aniket/ClaimProvider.dart';
import 'screens/aniket/FoundProvider.dart';
import 'screens/trip.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  AwesomeNotifications().initialize(
    null, // Use the default icon
    [
      NotificationChannel(
        channelKey: 'traffic_alerts',
        channelName: 'Traffic Alerts',
        channelDescription: 'Notification channel for traffic updates',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
      )
    ],
  );
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  FirebaseApp app = await Firebase.initializeApp();
  print('Initialized default app $app');

  runApp(MyApp());
}

class Complaint {
  String title;
  String imageUrl;
  double latitude;
  double longitude;
  String type;
  String category;
  int upvotes;
  int downvotes;
  String status;
  DateTime createdAt;
  String user_id;

  Complaint({
    required this.title,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.category,
    this.upvotes = 0,
    this.downvotes = 0,
    this.status = '0',
    required this.createdAt,
    required this.user_id,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'longitude': longitude,
      'latitude': latitude,
      'type': type,
      'category': category,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'status': status,
      'user_id': user_id,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComplaintsProvider()),
        ChangeNotifierProvider(create: (_) => ClaimProvider()),
        ChangeNotifierProvider(create: (_) => FoundProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Community Complaints',
        theme: ThemeData(
          fontFamily: 'Poppins',
          primarySwatch: Colors.deepPurple,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        home: HomeScreen(),
      ),
    );
  }
}

void showTrafficNotification() {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1,
      channelKey: 'traffic_alerts',
      title: '🚦 Heavy Traffic Ahead!',
      body: 'You are near a high-traffic area. Consider taking an alternate route.',
      notificationLayout: NotificationLayout.Default,
    ),
  );
}



class ComplaintsScreen extends StatefulWidget {
  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentLoc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    showTrafficNotification();
    _tabController = TabController(length: 2, vsync: this);
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
    });
    Position position = await determinePosition();
    setState(() {
      _currentLoc = position;
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchLocations() async {
    setState(() {
      _isLoading = true;
    });
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('complaints').get();

    return snapshot.docs.map((doc) {
      return {
        "name": doc['title'], // Map title to name
        "latLng": LatLng(doc['latitude'], doc['longitude']), // Map coordinates
        "info": doc['category'], // Map category to info
        "image": doc['imageUrl'], // Map image URL
      };
    }).toList();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffF1F7E8),
        title: Text(
          'Community Complaints',
          style:
              TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          indicatorColor: Color(0xff3BBD81),
          controller: _tabController,
          tabs: [
            Tab(
                child: Text(
              'Emergency',
              style: TextStyle(
                  color: Colors.green[900], fontWeight: FontWeight.bold),
            )),
            Tab(
              child: Text('Regular',
                  style: TextStyle(
                      color: Colors.green[900], fontWeight: FontWeight.bold)),
            ),
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

          // Main Content (Loading or TabBarView)
          (_isLoading)
              ? Center(
                  child: CircularProgressIndicator(color: Colors.green[900]),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    ComplaintsList(
                        type: 'emergency', currentLocation: _currentLoc),
                    ComplaintsList(
                        type: 'regular', currentLocation: _currentLoc),
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
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ComplaintsList extends StatefulWidget {
  final String type;
  final Position? currentLocation;

  ComplaintsList({required this.type, required this.currentLocation});

  @override
  _ComplaintsListState createState() => _ComplaintsListState();
}

class _ComplaintsListState extends State<ComplaintsList>
    with SingleTickerProviderStateMixin<ComplaintsList> {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });
  }

  double getRadius() {
    return widget.type == "emergency" ? 100.0 : 30.0;
  }

  bool isWithinRadius(double latitude, double longitude,
      Position currentLocation, double radius) {
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
          .where('type', isEqualTo: widget.type)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("An Error Occurred!"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var allDocs = snapshot.data!.docs;
        if (allDocs.isEmpty) {
          return const Center(child: Text("Nothing to show!"));
        }

        var localComplaints = allDocs.where((doc) {
          double latitude = doc['latitude'];
          double longitude = doc['longitude'];
          return isWithinRadius(
              latitude, longitude, widget.currentLocation!, getRadius());
        }).toList();

        var globalComplaints = allDocs
            .where(
                (doc) => !localComplaints.contains(doc) && doc['status'] != "0")
            .toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              // **Scrollable Large Complaint Tile**
              Container(
                child: LargeComplaintTile(doc: localComplaints.first),
              ),

              SizedBox(height: 10),

              // **TabBar with Oval Border**
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.white,
                  indicatorColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? Colors.green[50]
                              : Colors.transparent,
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Local",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? Colors.green[50]
                              : Colors.transparent,
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Global",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // **TabBarView for Switching Between Local & Global**
              SizedBox(height: 10),
              Container(
                height: 500, // Adjust height as needed
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // **Local Complaints Section**
                    localComplaints.isNotEmpty
                        ? ListView.builder(
                            physics: BouncingScrollPhysics(),
                            // Prevent inner scrolling issues
                            padding: EdgeInsets.all(8),
                            itemCount: localComplaints.length,
                            itemBuilder: (context, index) =>
                                ComplaintCard(doc: localComplaints[index]),
                          )
                        : Center(child: Text("No Local Complaints")),

                    // **Global Complaints Section**
                    globalComplaints.isNotEmpty
                        ? ListView.builder(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.all(8),
                            itemCount: globalComplaints.length,
                            itemBuilder: (context, index) =>
                                ComplaintCard(doc: globalComplaints[index]),
                          )
                        : Center(child: Text("No Global Complaints")),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LargeComplaintTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  LargeComplaintTile({required this.doc});
  late int upvotes;
  late int downvotes;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintsProvider>(context);
    final upvotes = provider.upvotes[doc.id] ?? doc['upvotes'];
    final downvotes = provider.downvotes[doc.id] ?? doc['downvotes'];
    String status = provider.statuses[doc.id] ?? doc['status'];
    String userId=doc['user_id'];
    return Card(
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint Title
            Text(
              doc['title'],
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900]),
            ),
            SizedBox(height: 8),

            // Location Row
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[800], size: 18),
                SizedBox(width: 6),
                Expanded(
                    child: Text(doc['latitude'].toString(),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 10),

            // **GestureDetector only on Image**
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => DiscussionScreen(postId: doc.id)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  doc['imageUrl'],
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null
                          ? child
                          : Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Voting and Report Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Upvote Button
                GestureDetector(
                  onTap: () => provider.updateVotes(
                      doc.id, true, upvotes > 20 ? "1" : "0"),
                  child: Row(
                    children: [
                      Icon(Icons.thumb_up, color: Colors.green[900], size: 22),
                      SizedBox(width: 4),
                      Text("$upvotes",
                          style: TextStyle(
                              color: Colors.green[900],
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Downvote Button
                GestureDetector(
                  onTap: () => provider.updateVotes(
                      doc.id, false, upvotes > 20 ? "1" : "0"),
                  child: Row(
                    children: [
                      Icon(Icons.thumb_down, color: Colors.red, size: 22),
                      SizedBox(width: 4),
                      Text("$downvotes",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Report Button
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.redAccent, size: 22),
                      SizedBox(width: 4),
                      Text(
                          (status != "0")
                              ? "Verified"
                              : upvotes > 20
                                  ? "Verified"
                                  : "Report",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintCard extends StatelessWidget {
  late int upvotes;
  late int downvotes;
  final QueryDocumentSnapshot doc;
  ComplaintCard({required this.doc});

  static IconData exclamationmark = IconData(0xf655);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintsProvider>(context);
    final upvotes = provider.upvotes[doc.id] ?? doc['upvotes'];
    final downvotes = provider.downvotes[doc.id] ?? doc['downvotes'];

    String status = provider.statuses[doc.id] ?? doc['status'];
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) {
          return DiscussionScreen(postId: doc.id);
        }));
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xffF1F7E8),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Section: Complaint Details (Expands to available space)
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Complaint Title
                      Text(
                        doc['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A9F7A),
                        ),
                      ),
                      SizedBox(height: 6),

                      // Location & Category
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.green[900], size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doc['latitude'].toString(),
                              style: TextStyle(
                                  color: Color(0xFF3A9F7A), fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),

                      // Category Label
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doc['category'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900]),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Voting Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Upvote Button
                          GestureDetector(
                            onTap: () => provider.updateVotes(
                                doc.id, true, upvotes > 20 ? "1" : "0"),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_up,
                                      color: Colors.green[900], size: 22),
                                  SizedBox(width: 6),
                                  Text(
                                    '$upvotes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // Downvote Button
                          GestureDetector(
                            onTap: () => provider.updateVotes(
                                doc.id, false, upvotes > 20 ? "1" : "0"),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_down,
                                      color: Colors.redAccent, size: 22),
                                  SizedBox(width: 6),
                                  Text(
                                    '$downvotes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right Section: Image + Report Button
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      doc['imageUrl'],
                      fit: BoxFit.cover,
                      height: 100,
                      width: 100, // Reduced width to avoid overflow
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 100,
                          width: 100,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: Colors.green,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: 100,
                          alignment: Alignment.center,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),

                  // Report Button
                  GestureDetector(
                    onTap: () =>
                        print('Report tapped'), // Replace with actual function
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 6),
                          Text(
                            (status != "0")
                                ? "Verified"
                                : upvotes > 20
                                    ? "Verified"
                                    : "Report",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//
// // **Smaller Tile for Other Complaints**
// class SmallComplaintTile extends StatelessWidget {
//   final QueryDocumentSnapshot doc;
//   SmallComplaintTile({required this.doc});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DiscussionScreen(postId: doc.id))),
//       child: Card(
//         margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         elevation: 2,
//         child: ListTile(
//           contentPadding: EdgeInsets.all(10),
//           leading: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.network(
//               doc['imageUrl'],
//               fit: BoxFit.cover,
//               width: 60,
//               height: 60,
//               loadingBuilder: (context, child, loadingProgress) =>
//               loadingProgress == null ? child : CircularProgressIndicator(),
//             ),
//           ),
//           title: Text(doc['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           subtitle: Row(
//             children: [
//               Icon(Icons.location_on, color: Colors.red, size: 16),
//               SizedBox(width: 4),
//               Expanded(child: Text(doc['latitude'].toString(), overflow: TextOverflow.ellipsis)),
//             ],
//           ),
//           trailing: Column(
//             children: [
//               Icon(Icons.thumb_up, color: Colors.green[900], size: 20),
//               Text("${doc['upvotes']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class AddComplaintScreen extends StatefulWidget {
  @override
  _AddComplaintScreenState createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _titleController = TextEditingController();
  String? _selectedType;
  String? _selectedCategory;
  File? _image;
  double _latitude = 0;
  double _longitude = 0;

  final _formKey = GlobalKey<FormState>();

  Future<void> _getLocation() async {
    Position position = await _determinePosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<Position> _determinePosition() async {
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate() &&
        _image != null &&
        _selectedType != null &&
        _selectedCategory != null) {
      String imageUrl = await _uploadImage();
      Complaint complaint = Complaint(
          title: _titleController.text,
          imageUrl: imageUrl,
          type: _selectedType!,
          category: _selectedCategory!,
          createdAt: DateTime.now(),
          latitude: _latitude!,
          longitude: _longitude!,
          user_id: FirebaseAuth.instance.currentUser!.uid);

      // Add complaint to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('complaints')
          .add(complaint.toMap());
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc("FirebaseAuth.instance.currentUser!.uid");

      // Send title to API
      // Replace with your API URL
      try {
        var response = await http.post(
          Uri.parse("$url/get-verification"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"title": _titleController.text}),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = jsonDecode(response.body);
          String newStatus = responseData["status"]; // Extract status
          print("Status is" + newStatus);
          if (newStatus == "1") {
            updateUserCredits(10,responseData["user_id"]);
          }
          // Update Firestore with the received status
          await docRef.update({"status": newStatus});
        } else {
          print("API Error: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("Failed to send API request: $e");
      }

      Navigator.pop(context);
    }
  }

  Future<String> _uploadImage() async {
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('complaints/${DateTime.now().toIso8601String()}');
    UploadTask uploadTask = storageRef.putFile(_image!);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent[100],
      appBar: AppBar(
        title: Text(
          'Add Complaint',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal[300],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/back_1.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'New Complaint',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.title, color: Colors.black),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a title'
                              : null,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Select Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ['emergency', 'regular']
                              .map((type) => DropdownMenuItem(
                                  value: type, child: Text(type.toUpperCase())))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedType = value),
                          validator: (value) =>
                              value == null ? 'Please select a type' : null,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Select Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            'Disaster',
                            'Accident',
                            'Health Emergency',
                            'Crime'
                          ]
                              .map((cat) => DropdownMenuItem(
                                  value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCategory = value),
                          validator: (value) =>
                              value == null ? 'Please select a category' : null,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(
                                  Icons.image,
                                  color: Colors.black,
                                ),
                                label: Text(
                                  'Pick Image',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _image!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        Icon(Icons.image, color: Colors.grey),
                                  ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _getLocation,
                                icon: Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                ),
                                label: Text(
                                  'Get Location',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _latitude != 0
                                    ? '$_latitude, $_longitude'
                                    : 'No location',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitComplaint,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'Submit Complaint',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> updateUserCredits(int amount,String userId) async {
  // String uid = FirebaseAuth.instance.currentUser!.uid;

  DocumentReference userDocRef =
      FirebaseFirestore.instance.collection('users').doc(userId);

  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDocRef);

      if (!snapshot.exists) {
        throw Exception("User document does not exist!");
      }

      int currentCredits = snapshot["credits"] ?? 0;
      print(currentCredits);
      int newCredits = (currentCredits + 10);

      transaction.update(userDocRef, {"credits": newCredits});
    });

    print("Credits increased by 10 successfully!");
  } catch (e) {
    print("Error increasing credits: $e");
  }
}
