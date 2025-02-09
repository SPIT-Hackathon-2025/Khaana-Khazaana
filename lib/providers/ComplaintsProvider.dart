import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokemon_go/main.dart';
class ComplaintsProvider with ChangeNotifier {
  Map<String, int> upvotes = {};
  Map<String, int> downvotes = {};
  Map<String, String> statuses = {}; // Store complaint status

  void initializeComplaint(String complaintId, int upvote, int downvote, String status) {
    upvotes[complaintId] = upvote;
    downvotes[complaintId] = downvote;
    statuses[complaintId] = status;
  }

  Future<void> updateVotes(String complaintId, bool isUpvote,String newStatus) async {
    DocumentReference complaintRef = FirebaseFirestore.instance.collection('complaints').doc(complaintId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(complaintRef);
      int newUpvotes = (freshSnap['upvotes'] ?? 0) + (isUpvote ? 1 : 0);
      int newDownvotes = (freshSnap['downvotes'] ?? 0) + (!isUpvote ? 1 : 0);

      transaction.update(complaintRef, {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
        'status':newStatus
      });
      if(newUpvotes>20){
        updateUserCredits(1);
      }
      upvotes[complaintId] = newUpvotes;
      downvotes[complaintId] = newDownvotes;
    });

    notifyListeners();
  }

  Future<void> updateStatus(String complaintId, String newStatus) async {
    DocumentReference complaintRef = FirebaseFirestore.instance.collection('complaints').doc(complaintId);

    await complaintRef.update({'status': newStatus});

    statuses[complaintId] = newStatus;
    notifyListeners();
  }
}
