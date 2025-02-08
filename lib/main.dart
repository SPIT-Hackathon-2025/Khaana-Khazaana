import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pokemon_go/providers/poll_provider.dart';
import 'package:pokemon_go/screens/ProfileInfoScreen.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:workmanager/workmanager.dart';

import 'screens/DiscussionScreen.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  //Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  AwesomeNotifications().initialize(
    null, // Use the default icon
    [NotificationChannel(
      channelKey: 'reminder_channel',
      channelName: 'SOS Reminders',
      channelDescription: 'Notifications with custom sounds',
      playSound: true,
      // Custom sound will be defined per notification
      importance: NotificationImportance.High,
    ),
      NotificationChannel(
        channelKey: 'custom_sound_channel',
        channelName: 'Custom Sound Notifications',
        channelDescription: 'Notifications with custom sounds',
        playSound: true,
        // Custom sound will be defined per notification
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Doctor Visit Notif',
        channelDescription: 'Notifications with custom sounds',
        playSound: true,
        // Custom sound will be defined per notification
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'high_frequency',
        channelName: 'high_frequency',
        channelDescription: 'Notifications with custom sounds',
        playSound: true,
        // Custom sound will be defined per notification
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'low_frequency',
        channelName: 'Doctor Visit Notif',
        channelDescription: 'Notifications with custom sounds',
        playSound: true,
        // Custom sound will be defined per notification
        importance: NotificationImportance.High,
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

  runApp(MyApp() );
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

  Complaint({
    required this.title,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.category,
    this.upvotes = 0,
    this.downvotes = 0,
    this.status = 'Pending',
    required this.createdAt,
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PollProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Community Complaints',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        home: ProfileUploadPage(),
      ),
    );
  }
}

class ComplaintsScreen extends StatefulWidget {
  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentLoc;
  bool _isLoading=false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getLocation();

  }
  Future<void> _getLocation() async {
    setState(() {
      _isLoading=true;
    });
    Position position = await _determinePosition();
    setState(() {
      _currentLoc=position;
      _isLoading=false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Complaints'),
        bottom: TabBar(
          controller: _tabController,

          tabs: [
            Tab(text: 'Emergency'),
            Tab(text: 'Regular'),
          ],
        ),
      ),
      body: (_isLoading)?
          Center(child: CircularProgressIndicator(color: Colors.deepPurple,),):TabBarView(
        controller: _tabController,
        children: [
          ComplaintsList(type: 'emergency',currentLocation: _currentLoc,),
          ComplaintsList(type: 'regular',currentLocation: _currentLoc),
        ],
      ),
      floatingActionButton: FloatingActionButton(

        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddComplaintScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}


class ComplaintsList extends StatelessWidget {
  final String type;
  final Position? currentLocation;

  ComplaintsList({required this.type, required this.currentLocation});

  double getRadius() {
    return type == "emergency" ? 100.0 : 30.0;
  }

  bool isWithinRadius(double latitude,double longitude, Position currentLocation, double radius) {
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
          double latitude=doc['latitude'];
          double longitude=doc['longitude'];
          return isWithinRadius(latitude,longitude, currentLocation!, getRadius());
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("Nothing to show!"));
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: filteredDocs.map((doc) => ComplaintCard(doc: doc)).toList(),
        );
      },
    );
  }
}


class ComplaintCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  ComplaintCard({required this.doc});

  void updateVotes(bool isUpvote) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(doc.reference);
      int newUpvotes = freshSnap['upvotes'] + (isUpvote ? 1 : 0);
      int newDownvotes = freshSnap['downvotes'] + (!isUpvote ? 1 : 0);
      transaction.update(doc.reference,
          {'upvotes': newUpvotes, 'downvotes': newDownvotes});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context){
          return DiscussionScreen(postId: doc.id);
        }));
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.deepPurple.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  doc['imageUrl'],
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                child: Text(
                  doc['title'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,

                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Colors.redAccent, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doc['latitude'].toString(),
                        style: TextStyle(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc['category'],
                        style: TextStyle(

                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_up, color: Colors.green),
                        onPressed: () => updateVotes(true),
                      ),
                      Text('${doc['upvotes']}'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_down, color: Colors.red),
                        onPressed: () => updateVotes(false),
                      ),
                      Text('${doc['downvotes']}'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class AddComplaintScreen extends StatefulWidget {
  @override
  _AddComplaintScreenState createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _titleController = TextEditingController();
  String? _selectedType;
  String? _selectedCategory;
  File? _image;
  double _latitude=0;
  double _longitude=0;
  final _formKey = GlobalKey<FormState>();

  Future<void> _getLocation() async {
    Position position = await _determinePosition();
    setState(() {

      _latitude =position.latitude;
      _longitude=position.longitude;
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
        createdAt: DateTime.now(), latitude: _latitude!,
        longitude: _longitude!
      );
      FirebaseFirestore.instance
          .collection('complaints')
          .add(complaint.toMap());
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
      appBar: AppBar(title: Text('Add Complaint')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        prefixIcon:
                        Icon(Icons.title, color: Colors.deepPurple),
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
                        'Fire',
                        'Power Cut',
                        'Flooding',
                        'Pothole',
                        'Road Damage',
                        'Water Issues'
                      ]
                          .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
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
                            icon: Icon(Icons.image),
                            label: Text('Pick Image'),
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
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _getLocation,
                            icon: Icon(Icons.location_on),
                            label: Text('Get Location'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _latitude!=0 ? '$_latitude, $_longitude' : 'No location',
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
                          style: TextStyle(fontSize: 18),
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
    );
  }
}