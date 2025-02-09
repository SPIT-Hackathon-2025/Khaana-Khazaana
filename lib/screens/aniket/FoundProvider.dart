import 'package:flutter/cupertino.dart';

class FoundProvider extends ChangeNotifier {
  List<Map<String, String>> _foundItems = [
    {
      "image": "assets/images/bag.jpg",
      "title": "Claimed Item 1",
      "description": "Description of claimed item 1.",
      "latitude": "28.7041",
      "longitude": "77.1025",
      "status": "unresolved", // Example status
    },
    {
      "image": "assets/images/phone.jpg",
      "title": "Claimed Item 2",
      "description": "Description of claimed item 2.",
      "latitude": "28.7041",
      "longitude": "77.1025",
      "status": "unresolved", // Example status
    },
  ];

  List<Map<String, String>> get foundItems => _foundItems;

  void markedAsClaimed(Map<String, String> item) {
    print("Adding new item...");
    debugPrint("Before: $_foundItems");

    _foundItems = [..._foundItems, item]; // Correct way to update state

    debugPrint("After: $_foundItems");
    notifyListeners();
  }

  void updateItemClaimed(Map<String, String> item) {
    int index = _foundItems.indexWhere((existingItem) => existingItem["title"] == item["title"]);

    if (index != -1) {
      _foundItems[index] = {
        ..._foundItems[index], // Copy existing item data
        "status": "claimed" // Add/Update status field
      };
      notifyListeners();
    }
  }
}
