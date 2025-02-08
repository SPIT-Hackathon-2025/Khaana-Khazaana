import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/poll_provider.dart';

class DiscussionScreen extends StatefulWidget {
  final String postId;
  DiscussionScreen({required this.postId});

  @override
  _DiscussionScreenState createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController replyController = TextEditingController();
  final TextEditingController pollQuestionController = TextEditingController();
  final TextEditingController pollOptionController = TextEditingController();
  List<String> pollOptions = [];
  //String userId = FirebaseAuth.instance.currentUser!.uid;
  String userId = 'FirebaseAuth.instance.currentUser!.uid';

  Future<void> addReply({String? pollQuestion, List<String>? options}) async {
    Map<String, dynamic> replyData = {
      'userId': userId,
      'reply': replyController.text.isNotEmpty ? replyController.text : null,
      'createdAt': Timestamp.now(),
      'isPoll': pollQuestion != null,
      'pollQuestion': pollQuestion,
      'pollOptions': options ?? [],
      'pollResults': options != null ? {for (var option in options) option: 0} : null,
    };

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('replies')
        .add(replyData);

    replyController.clear();
    pollOptions.clear();
    pollQuestionController.clear();
    pollOptionController.clear();
  }

  void showCreatePollDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create a Poll"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: pollQuestionController, decoration: InputDecoration(labelText: "Poll Question")),
              SizedBox(height: 10),
              TextField(
                controller: pollOptionController,
                decoration: InputDecoration(labelText: "Add Option"),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      pollOptions.add(value);
                      pollOptionController.clear();
                    });
                  }
                },
              ),
              SizedBox(height: 10),
              Wrap(
                children: pollOptions.map((option) {
                  return Chip(
                    label: Text(option),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => pollOptions.remove(option));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (pollOptions.length >= 2) {
                  addReply(pollQuestion: pollQuestionController.text, options: pollOptions);
                  Navigator.pop(context);
                }
              },
              child: Text("Create Poll"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PollProvider(),
      child: Scaffold(
        appBar: AppBar(title: Text("Discussion Thread")),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('replies')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: snapshot.data!.docs.map((doc) {
                        bool isMe = doc['userId'] == userId;
                        bool isPoll = doc['isPoll'] ?? false;
                        List<String> pollOptions = List<String>.from(doc['pollOptions'] ?? []);
                        Map<String, dynamic> pollResults = Map<String, dynamic>.from(doc['pollResults'] ?? {});

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (doc['reply'] != null)
                                  Text(doc['reply'], style: TextStyle(fontSize: 16)),

                                if (isPoll)
                                  Consumer<PollProvider>(
                                    builder: (context, pollProvider, child) {
                                      pollProvider.setPollData(pollResults);
                                      return Column(
                                        children: [
                                          Text(doc['pollQuestion'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          ...pollOptions.map((option) {
                                            return Card(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              child: RadioListTile<String>(
                                                title: Text("$option (${pollResults[option] ?? 0} votes)"),
                                                value: option,
                                                groupValue: pollProvider.selectedOption,
                                                onChanged: (String? value) {
                                                  pollProvider.vote(widget.postId, doc.id, value!);
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      );
                                    },
                                  ),

                                SizedBox(height: 4),
                                Text("By: ${doc['userId']}", style: TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(controller: replyController, decoration: InputDecoration(labelText: "Reply...")),
                      ),
                      IconButton(icon: Icon(Icons.send), onPressed: () => addReply()),
                      IconButton(icon: Icon(Icons.poll), onPressed: showCreatePollDialog),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
