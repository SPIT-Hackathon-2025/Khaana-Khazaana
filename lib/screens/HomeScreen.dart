import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pokemon_go/screens/MapScreen.dart';

import '../main.dart';
import 'aniket/lostandfound.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // List of screens (stubs for Trip, Complaints, Lost/Found, Profile)
  final List<Widget> _screens = [
    TripPage(),
    ComplaintsScreen(),
    LostFoundScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // Scaffold background is green
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Lost/Found',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}



class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String verifiedName = "";
  int credits = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  // Fetch user profile data from Firestore using the current user's UID.
  Future<void> fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          verifiedName = data['verifiedName'] ?? "No Name";
          credits = data['credits'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          verifiedName = "User not found";
          credits = 0;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        verifiedName = "Not logged in";
        credits = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // Green scaffold background
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              SizedBox(height: 20),
              // Verified name
              Text(
                verifiedName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // Credits display
              Text(
                "Credits: $credits",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 30),
              // Card with additional profile details
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.email, color: Colors.green),
                        title: Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          FirebaseAuth.instance.currentUser?.email ?? "No Email",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.verified_user, color: Colors.green),
                        title: Text("Verified Name", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          verifiedName,
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.credit_card, color: Colors.green),
                        title: Text("Credits", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "$credits",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Logout button
              ElevatedButton(
                onPressed: () {
                  // Add your logout functionality here
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.green, backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Log Out",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
