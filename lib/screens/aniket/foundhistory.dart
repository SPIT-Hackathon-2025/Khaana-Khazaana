import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import 'FoundProvider.dart';


class FoundHistoryPage extends StatefulWidget {
  FoundHistoryPage();

  @override
  _FoundHistoryPageState createState() => _FoundHistoryPageState();
}

class _FoundHistoryPageState extends State<FoundHistoryPage> {
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> foundItems = Provider.of<FoundProvider>(context).foundItems;
    return Scaffold(
      backgroundColor: Colors.transparent,
        body: ListView.builder(
          itemCount: foundItems.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xffE8F5E9), // Light green background that complements a light green theme
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Image.asset(
                  foundItems[index]["image"]!,
                  width: 50,
                  height: 50,
                ),
                title: Text(foundItems[index]["title"]!),
                subtitle: Text(foundItems[index]["description"]!),
                trailing: Text(foundItems[index]["status"]!),
                onTap: () {
                  if (foundItems[index]["status"] == "unresolved") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClaimantListPage(item: foundItems[index]),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.lightGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitLostItemPage(), // Pass the first claim item for now
            ),
          );
        },
        child: Icon(Icons.add,color: Colors.white,),
      ),
    );
  }
}

// New class to display list of claimants for a found item
class ClaimantListPage extends StatefulWidget {
  final Map<String, String> item;

  ClaimantListPage({required this.item});

  @override
  _ClaimantListPageState createState() => _ClaimantListPageState();
}

class _ClaimantListPageState extends State<ClaimantListPage> {
  List<Map<String, dynamic>> claimants = [
    {
      "name": "John Doe",
      "status": "Pending",
      "answers": [
        {"question": "What color is the item?", "answer": "Blue"},
        {"question": "Where did you lose it?", "answer": "At the park"},
      ]
    },
    {
      "name": "Jane Smith",
      "status": "Pending",
      "answers": [
        {"question": "What color is the item?", "answer": "Red"},
        {"question": "Where did you lose it?", "answer": "At the mall"},
      ]
    },
    {
      "name": "Alex Johnson",
      "status": "Pending",
      "answers": [
        {"question": "What color is the item?", "answer": "Green"},
        {"question": "Where did you lose it?", "answer": "On the bus"},
      ]
    },
  ];

  void approveClaimant(int index) {
    setState(() {
      claimants[index]["status"] = "Approved";
    });
  }

  void rejectClaimant(int index) {
    setState(() {
      claimants[index]["status"] = "Rejected";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claimants List'),
        backgroundColor: Colors.green,
      ),
      body: claimants.isEmpty
          ? Center(child: Text("No claimants found."))
          : ListView.builder(
        itemCount: claimants.length,
        itemBuilder: (context, index) {
          final claimant = claimants[index];

          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(claimant["name"]),
              subtitle: Text("Verification Status: ${claimant["status"]}"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClaimantDetailsPage(claimant: claimant),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => approveClaimant(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => rejectClaimant(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// New class to display claimant's verification answers
class ClaimantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> claimant;

  ClaimantDetailsPage({required this.claimant});

  @override
  _ClaimantDetailsPageState createState() => _ClaimantDetailsPageState();
}

class _ClaimantDetailsPageState extends State<ClaimantDetailsPage> {
  List<dynamic> answers = [];

  @override
  void initState() {
    super.initState();
    answers = widget.claimant["answers"] ?? [];
  }

  void approveClaimant() {
    setState(() {
      widget.claimant["status"] = "Approved";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${widget.claimant["name"]} has been approved!"), backgroundColor: Colors.green),
    );

    Navigator.pop(context);
  }

  void rejectClaimant() {
    setState(() {
      widget.claimant["status"] = "Rejected";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${widget.claimant["name"]} has been rejected!"), backgroundColor: Colors.red),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.claimant["name"]}\'s Answers'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Verification Answers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Q: ${answers[index]["question"]}"),
                    subtitle: Text("A: ${answers[index]["answer"]}"),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: approveClaimant,
                  icon: Icon(Icons.check, color: Colors.white),
                  label: Text("Accept"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: rejectClaimant,
                  icon: Icon(Icons.close, color: Colors.white),
                  label: Text("Reject"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class SubmitLostItemPage extends StatefulWidget {
  @override
  _SubmitLostItemPageState createState() => _SubmitLostItemPageState();
}

class _SubmitLostItemPageState extends State<SubmitLostItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _customQuestionController = TextEditingController();

  String? _selectedImage;
  final List<String> availableImages = [
    "assets/images/wallet.jpg",
    "assets/images/phone.jpg",
    "assets/images/bag.jpg",
  ];

  List<String> questions = []; // List to store generated & custom questions
  bool _isLoadingQuestions = false; // Loading state for API call

  // Function to fetch questions from API
  Future<void> _generateQuestionnaire() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter item title and description first")),
      );
      return;
    }

    setState(() {
      _isLoadingQuestions = true;
    });

    //final url = Uri.parse("https://f181-2409-40c0-103d-8150-b0e8-2c11-689e-55fa.ngrok-free.app/generate_questions");
    final requestBody = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "image": _selectedImage ?? "No image selected",
      "latitude": _latitudeController.text,
      "longitude": _longitudeController.text,
    };

    try {
      final response = await http.post(
        Uri.parse("$url/generate_questions"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = List<String>.from(data["questions"]);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate questions")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  // Function to add a custom question
  void _addCustomQuestion() {
    if (_customQuestionController.text.isNotEmpty) {
      setState(() {
        questions.add(_customQuestionController.text);
      });
      _customQuestionController.clear();
    }
  }

  void _submitItem() {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedImage == null ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty ||
        questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and generate questions")),
      );
      return;
    }

    // Join the questions list into a single string
    String questionsString = questions.join(", ");

    final newItem = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "image": _selectedImage!,
      "latitude": _latitudeController.text,
      "longitude": _longitudeController.text,
      "questions": questionsString,  // Now a String instead of List<String>
      "status": "unresolved"
    };

    // Add to FoundProvider
    Provider.of<FoundProvider>(context, listen: false).markedAsClaimed(newItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Item added successfully!")),
    );

    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Lost Item")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Item Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 10),

              // Image Selection
              const Text("Select Image:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableImages.map((imagePath) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = imagePath;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: _selectedImage == imagePath ? Border.all(color: Colors.blue, width: 3) : null,
                        ),
                        child: Image.asset(
                          imagePath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _latitudeController,
                decoration: const InputDecoration(labelText: "Latitude"),
              ),
              TextField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: "Longitude"),
              ),
              const SizedBox(height: 20),

              // Generate Questions Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoadingQuestions ? null : _generateQuestionnaire,
                  child: _isLoadingQuestions
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text("Generate Questionnaire"),
                ),
              ),
              const SizedBox(height: 20),

              // Display Questions
              if (questions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Verification Questions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...questions.map((question) => Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        title: Text(question),
                      ),
                    )),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customQuestionController,
                      decoration: InputDecoration(
                        labelText: "Add Custom Question",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _addCustomQuestion,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Add Item Button
              Center(
                child: ElevatedButton(
                  onPressed: _submitItem,
                  child: const Text("Add Item"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
