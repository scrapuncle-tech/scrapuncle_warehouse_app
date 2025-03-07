import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart';

class DatabaseMethods {
  Future addSupervisorDetail(
      Map<String, dynamic> supervisorInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("supervisors") // Changed collection name
        .doc(id)
        .set(supervisorInfoMap);
  }

  Future<void> addItem(
      Map<String, dynamic> itemInfo, String phoneNumber, String userId) async {
    // Ensure the phone number is valid
    if (phoneNumber == null || phoneNumber.isEmpty) {
      print("Error: Phone number is null or empty.");
      return;
    }

    // Add a unique item ID to the item info
    String itemId = randomAlphaNumeric(10);
    itemInfo['itemId'] = itemId;

    // Construct the document path using the user's ID and phone number and Item ID
    try {
      await FirebaseFirestore.instance
          .collection("users") // Top-level collection for all users
          .doc(userId) // Document ID is the user's ID
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
      return const Stream<
          QuerySnapshot>.empty(); // Return an empty stream on error
    }
  }

  // New method to fetch items based on agent's phone number
  Future<List<Map<String, dynamic>>> getItemsByPhoneNumber(
      String phoneNumber) async {
    List<Map<String, dynamic>> items = [];

    //**IMPORTANT:** This assumes your data is structured as users/(userId)/PhoneNumber = phoneNumber
    //  This is different from the original app and CRUCIAL to get right.

    QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('PhoneNumber',
            isEqualTo:
                phoneNumber) //find the document where PhoneNumber field is equal to the phone number
        .get();

    if (userQuery.docs.isNotEmpty) {
      //User found with that phone number
      String userId = userQuery.docs.first.id; //get the ID of the user

      //Get the items associated with that particular phone number
      DocumentSnapshot phoneNumberSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection("phoneNumbers")
          .doc(phoneNumber)
          .get();

      if (phoneNumberSnapshot.exists) {
        //Retrieve items if there is
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
