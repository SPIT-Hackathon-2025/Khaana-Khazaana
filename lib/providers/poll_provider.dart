import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollProvider with ChangeNotifier {
  String? selectedOption;
  Map<String, dynamic> pollResults = {};

  void setPollData(Map<String, dynamic> results) {
    pollResults = results;
    notifyListeners();
  }

  Future<void> vote(String postId, String replyId, String option) async {
    String userId = 'FirebaseAuth.instance.currentUser!.uid';

    // Reference to Firestore document
    DocumentReference replyRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .doc(replyId);

    // Fetch current poll data
    DocumentSnapshot snapshot = await replyRef.get();
    if (!snapshot.exists) return;

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    Map<String, int> pollResults = Map<String, int>.from(data['pollResults'] ?? {});

    // If the user has already voted for a different option, remove that vote
    if (selectedOption != null && selectedOption != option) {
      pollResults[selectedOption!] = (pollResults[selectedOption!] ?? 1) - 1;
    }

    // Add a vote to the selected option
    pollResults[option] = (pollResults[option] ?? 0) + 1;

    // Update Firestore
    await replyRef.update({'pollResults': pollResults});

    // Update local state
    selectedOption = option;
    this.pollResults = pollResults;
    notifyListeners();
  }
}
