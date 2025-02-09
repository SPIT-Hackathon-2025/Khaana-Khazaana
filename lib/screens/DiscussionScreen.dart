import 'package:flutter/material.dart';
import 'package:pokemon_go/main.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_to/swipe_to.dart';

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
  // String userId = 'FirebaseAuth.instance.currentUser!.uid';
  DocumentSnapshot<Map<String, dynamic>>? complaint;
  String? quotedMessage; // Holds the message being replied to
  String? quotedMessageId; // Holds the ID of the original message

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }
  void getData()async{
  var data=await FirebaseFirestore.instance.collection('complaints').doc(widget.postId).get();
  setState(() {
    complaint=data;
  });
  }

  Future<void> addReply({String? pollQuestion, List<String>? options}) async {
    Map<String, dynamic> replyData = {
      'userId': "current",
      'reply': replyController.text.isNotEmpty ? replyController.text : null,
      'quotedMessage': quotedMessage, // Store quoted message
      'quotedMessageId': quotedMessageId,
      'createdAt': Timestamp.now(),
      'isPoll': pollQuestion != null,
      'pollQuestion': pollQuestion,
      'pollOptions': options ?? [],
      'pollResults': options != null ? {for (var option in options) option: 0} : null,
    };

    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(widget.postId)
        .collection('replies')
        .add(replyData);

    // Clear input fields after sending
    replyController.clear();
    pollOptions.clear();
    pollQuestionController.clear();
    pollOptionController.clear();
    setState(() {
      quotedMessage = null; // Reset quoted message after sending reply
      quotedMessageId = null;
    });
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
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/back_1.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .doc(widget.postId)
                .collection('replies')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              return Column(
                children: [
                  if(complaint!=null)
                    ImageCard(doc: complaint!,),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: snapshot.data!.docs.map((doc) {
                          bool isMe = (doc.data() as Map<String, dynamic>).containsKey('user_id') && doc['user_id'] == "current";
                          final data = doc.data() as Map<String, dynamic>?;
                          bool isPoll = doc['isPoll'] ?? false;
                          List<String> pollOptions = List<String>.from(doc['pollOptions'] ?? []);
                          Map<String, dynamic> pollResults = Map<String, dynamic>.from(doc['pollResults'] ?? {});
                          //String? quotedMessage = doc.data()!.containsKey('quotedMessage') ? doc['quotedMessage'] : null;
                          return SwipeTo(
                            onRightSwipe: (_) {
                              setState(() {
                                quotedMessage = doc['reply'];
                                quotedMessageId = doc.id;
                              });
                            },
                            child: Align(
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
                                    if (doc['quotedMessage'] != null)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 5),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "Replying to: ${doc['quotedMessage']}",
                                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.black54),
                                        ),
                                      ),

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

                                    Text("By: ${data != null && data.containsKey('user_id') ? data['user_id'] : 'Unknown User'}")
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  if (quotedMessage != null)
                    Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(child: Text("Replying to: $quotedMessage", style: TextStyle(fontStyle: FontStyle.italic))),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                quotedMessage = null;
                                quotedMessageId = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyController,
                            decoration: InputDecoration(
                              labelText: "Reply...",
                              labelStyle: TextStyle(color: Colors.white),  // Label text color
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),  // Bottom border color
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),  // Focused border color
                              ),
                            ),
                            style: TextStyle(color: Colors.white),  // Text input color
                            cursorColor: Colors.white,  // Cursor color
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.white),  // Send button icon color
                          onPressed: () => addReply(),
                        ),
                        IconButton(
                          icon: Icon(Icons.poll, color: Colors.white),  // Poll button icon color
                          onPressed: showCreatePollDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ImageCard extends StatefulWidget {
  final DocumentSnapshot doc;
  const ImageCard({super.key, required this.doc});

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  late String status; // Store status state

  @override
  void initState() {
    super.initState();
    status = widget.doc['status'].toString() == "1" ? "Verified" : "Processing";
  }

  void updateStatus(String newStatus) {
    setState(() {
      status = newStatus == "1" ? "Verified" : "Processing";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                widget.doc['imageUrl'],
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
              child: Text(
                widget.doc['title'],
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
                  Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.doc['latitude'].toString(),
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(status == "Verified" ? Icons.check : Icons.warning, color: Colors.redAccent, size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      status, // Use the state variable
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
                      widget.doc['category'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  SizedBox(width: 5),
                  Icon(Icons.person, color: Colors.redAccent, size: 16),
                  SizedBox(width: 5),
                  Text(
                    widget.doc['user_id'].toString(),
                    style: TextStyle(color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

