import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pokemon_go/constants.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ClaimProvider.dart';
import 'claim.dart';

class ClaimHistoryPage extends StatefulWidget {


  ClaimHistoryPage();
  @override
  _ClaimHistoryPageState createState() => _ClaimHistoryPageState();

}

class _ClaimHistoryPageState extends State<ClaimHistoryPage> {

  // Function to mark an item as claimed (resolved)


  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> claims =Provider.of<ClaimProvider>(context).claims;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        itemCount: claims.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xffE8F5E9), // Light green background color that complements the theme
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Image.asset(claims[index]["image"]!, width: 50, height: 50),
              title: Text(claims[index]["title"]!),
              subtitle: Text(claims[index]["description"]!),
              trailing: Text(claims[index]["status"]!),
              onTap: () {
                if (claims[index]["status"] == "unresolved") {
                  // Navigate to claim verification chat if unresolved
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClaimVerificationChatPage(
                        item: claims[index],
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      )
      ,
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the claim page and pass the callback to update the history
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClaimPage(
                item: claims[0], // Pass the first claim item for now

              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}


class ClaimVerificationChatPage extends StatefulWidget {
  final Map<String, String> item;

  ClaimVerificationChatPage({required this.item});

  @override
  _ClaimVerificationChatPageState createState() => _ClaimVerificationChatPageState();
}

class _ClaimVerificationChatPageState extends State<ClaimVerificationChatPage> {
  List<Map<String, String>> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchVerificationQuestions();
  }

  Future<void> fetchVerificationQuestions() async {

    final response = await http.post(
      Uri.parse("$url/generate_questions"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(widget.item),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        messages.add({"sender": "Admin", "text": "Please answer these verification questions:"});
        for (String question in data["questions"]) {
          messages.add({"sender": "Admin", "text": question});
        }
      });
    } else {
      setState(() {
        messages.add({"sender": "Admin", "text": "Failed to load verification questions."});
      });
    }
  }

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      setState(() {
        messages.add({"sender": "You", "text": messageController.text});
      });
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Chat'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(widget.item["image"]!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),

            // Item Title and Description
            Text(widget.item["title"]!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.item["description"]!, style: const TextStyle(fontSize: 16, color: Colors.grey)),

            const SizedBox(height: 16),

            // Chat Area for Verification
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return ListTile(
                    title: Text(
                      "${message["sender"]}: ${message["text"]}",
                      style: TextStyle(
                        fontWeight: message["sender"] == "Admin" ? FontWeight.bold : FontWeight.normal,
                        color: message["sender"] == "Admin" ? Colors.red : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Field
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type your response...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.green),
                    onPressed: sendMessage,
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
