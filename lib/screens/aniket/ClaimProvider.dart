import 'package:flutter/cupertino.dart';

class ClaimProvider extends ChangeNotifier{


  List<Map<String, String>> _claims = [
    {
      "image": "assets/images/wallet.jpg",
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
  List<Map<String, String>> get claims =>_claims;

  void markedAsClaimed(Map<String, String> item){
    print("lol");
    debugPrint(_claims.toString());
    _claims.add(item);
    debugPrint(_claims.toString());
    notifyListeners();
  }
  void updateItemClaimed(Map<String, String> item) {

      int index =_claims.indexWhere((existingItem) => existingItem["title"] == item["title"]);
      if (index != -1) {
        _claims[index]["status"] = "claimed";
      }
    notifyListeners();
  }
}