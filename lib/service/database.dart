import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart';

class DatabaseMethods {
  Future addSupervisorDetail(
      Map<String, dynamic> supervisorInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("supervisors")
        .doc(id)
        .set(supervisorInfoMap);
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

  Stream<QuerySnapshot> getUploadedItems(String userId) {
    if (userId == null || userId.isEmpty) {
      print("Warning: User ID is null or empty. Returning empty stream.");
      return const Stream<QuerySnapshot>.empty();
    }
    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection("phoneNumbers")
          .snapshots();
    } catch (e) {
      print("Error getting uploaded items stream: $e");
      return const Stream<QuerySnapshot>.empty();
    }
  }

  Future<List<Map<String, dynamic>>> getItemsByPhoneNumber(
      String phoneNumber) async {
    List<Map<String, dynamic>> items = [];

    //IMPORTANT: This assumes your data is structured as users/(userId)/PhoneNumber = phoneNumber

    QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .get();

    if (userQuery.docs.isNotEmpty) {
      String userId = userQuery.docs.first.id;

      DocumentSnapshot phoneNumberSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection("phoneNumbers")
          .doc(phoneNumber)
          .get();

      if (phoneNumberSnapshot.exists) {
        QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection("phoneNumbers")
            .doc(phoneNumber)
            .collection("items")
            .get();

        for (var doc in itemsSnapshot.docs) {
          items.add(doc.data() as Map<String, dynamic>);
        }
      } else {
        print(
            "No phone number document exist for user with ID: $userId and phone number: $phoneNumber");
      }
    } else {
      print("No user found with phone number: $phoneNumber");
    }

    return items;
  }
}
