import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ClaimProvider.dart';

class ClaimPage extends StatefulWidget {
  final Map<String, String> item;


  ClaimPage({required this.item});

  @override
  _ClaimPageState createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Item'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Location Information (Latitude and Longitude)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Location: ${widget.item["latitude"]}, ${widget.item["longitude"]}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Claim Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Action when claim button is pressed
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Item Claimed'),
                        content: const Text('You have successfully claimed this item.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              debugPrint(widget.item.toString());
                              Provider.of<ClaimProvider>(context,listen: false).markedAsClaimed(widget.item);
                              Navigator.pop(context); // Close the claim page
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Claim Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
