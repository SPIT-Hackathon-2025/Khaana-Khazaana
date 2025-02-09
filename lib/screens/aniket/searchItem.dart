import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ClaimProvider.dart';
import 'claim.dart';

class LostAndFoundPage extends StatefulWidget {

  LostAndFoundPage();
  @override
  _LostAndFoundPageState createState() => _LostAndFoundPageState();
}

class _LostAndFoundPageState extends State<LostAndFoundPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredItems = [];

  final List<Map<String, String>> lostItems = [
    {
      "title": "Lost Wallet",
      "description": "Brown leather wallet with ID and cards.",
      "image": "assets/images/wallet.jpg",
      "latitude": "18.5204",
      "longitude": "73.8567",
      "status": "unresolved",
    },
    {
      "title": "Missing Phone",
      "description": "Black iPhone 13 Pro, last seen in the library.",
      "image": "assets/images/phone.jpg",
      "latitude": "40.7128",
      "longitude": "-74.0060",
      "status": "unresolved",
    },
    {
      "title": "Laptop Bag",
      "description": "Grey backpack with Dell laptop inside.",
      "image": "assets/images/bag.jpg",
      "latitude": "34.0522",
      "longitude": "-118.2437",
      "status": "unresolved",
    },
  ];
  // Sample list of claims with unresolved status


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    filteredItems = lostItems;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = lostItems
          .where((item) => item["title"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addNewItem(Map<String, String> newItem) {
    setState(() {
      lostItems.add(newItem);
      filteredItems = List.from(lostItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String,String>> claims = Provider.of<ClaimProvider>(context).claims;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search lost items...",
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
              onChanged: _filterItems,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: filteredItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final item = lostItems[index];
                  return _buildLostItemCard(item, index,context);
                },
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.deepPurpleAccent,
      //   child: const Icon(Icons.add, size: 30),
      //   onPressed: () async {
      //     final newItem = await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => AddLostItemPage()),
      //     );
      //
      //     if (newItem != null) {
      //       _addNewItem(newItem);
      //     }
      //   },
      // ),
    );
  }

  Widget _buildLostItemCard(Map<String, String> item, int index, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image at the top
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              item["image"]!,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Scrollable Column with Padding for text and button
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title of the item
                    Text(
                      item["title"]!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Description of the item
                    Text(
                      item["description"]!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location (latitude, longitude)
                    Text(
                      "📍 ${item["latitude"]}, ${item["longitude"]}",
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 12),

                    // Claim button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the ClaimPage when the Claim button is pressed
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  ClaimPage(
                                item: item,
                              ),
                            ),
                          );
                        },
                        child: const Text('Claim Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          textStyle: const TextStyle(fontSize: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class AddLostItemPage extends StatefulWidget {
  @override
  _AddLostItemPageState createState() => _AddLostItemPageState();
}

class _AddLostItemPageState extends State<AddLostItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  String? _selectedImage;

  final List<String> availableImages = [
    "assets/images/wallet.jpg",
    "assets/images/phone.jpg",
    "assets/images/bag.jpg",
  ];

  void _submitItem() {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedImage == null ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final newItem = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "image": _selectedImage!,
      "latitude": _latitudeController.text,
      "longitude": _longitudeController.text,
    };

    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Lost Item")),
      body: Padding(
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
            const Text("Select Image:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: availableImages.map((imagePath) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = imagePath;
                    });
                  },
                  child: Container(
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
            Center(
              child: ElevatedButton(
                onPressed: _submitItem,
                child: const Text("Add Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
