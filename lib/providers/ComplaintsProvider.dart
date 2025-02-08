import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ComplaintsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _locations = [];

  List<Map<String, dynamic>> get locations => _locations;

  ComplaintsProvider() {
    _fetchLocations();
  }

  void _fetchLocations() {
    FirebaseFirestore.instance.collection('complaints').snapshots().listen((snapshot) {
      _locations = snapshot.docs.map((doc) {
        return {
          "name": doc['title'], // Map title to name
          "latLng": LatLng(doc['latitude'], doc['longitude']), // Map coordinates
          "info": doc['category'], // Map category to info
          "image": doc['imageUrl'], // Map image URL
        };
      }).toList();
      print("lol");
      print(locations);
      notifyListeners(); // Notify UI to update
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> upvotes = {};
  Map<String, int> downvotes = {};

  void initializeVotes(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      upvotes[doc.id] = doc['upvotes'];
      downvotes[doc.id] = doc['downvotes'];
    }
    notifyListeners();
  }

  Future<void> updateVotes(String docId, bool isUpvote) async {
    final docRef = _firestore.collection('complaints').doc(docId);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(docRef);
      int newUpvotes = freshSnap['upvotes'] + (isUpvote ? 1 : 0);
      int newDownvotes = freshSnap['downvotes'] + (!isUpvote ? 1 : 0);
      transaction.update(docRef, {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
      });
      upvotes[docId] = newUpvotes;
      downvotes[docId] = newDownvotes;
    });
    notifyListeners();
  }
}
