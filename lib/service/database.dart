import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart';

class DatabaseMethods {
  Future addUserDetail(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("supervisors") // Changed to "supervisors"
        .doc(id)
        .set(userInfoMap);
  }

  Future<void> addItem(
      Map<String, dynamic> itemInfo, String phoneNumber, String userId) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      print("Error: Phone number is null or empty.");
      return;
    }

    String itemId = randomAlphaNumeric(10);
    itemInfo['itemId'] = itemId;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("phoneNumbers")
          .doc(phoneNumber)
          .collection("items")
          .doc(itemId)
          .set(itemInfo);
      print(
          "Item data added successfully to Firestore (User: $userId, Phone Number: $phoneNumber)");
    } catch (e) {
      print("Error adding item data to Firestore: $e");
    }
  }
}
