import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({Key? key}) : super(key: key);

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  TextEditingController phoneController = TextEditingController();
  List<Map<String, dynamic>> items = [];
  List<bool> itemVerificationStatus = [];
  String? userId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchItems() async {
    String phoneNumber = phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number.")),
      );
      return;
    }

    List<Map<String, dynamic>> fetchedItems =
        await DatabaseMethods().getItemsByPhoneNumber(phoneNumber);

    setState(() {
      items = fetchedItems;
      itemVerificationStatus = List.filled(items.length, false);
    });
  }

  void toggleItemVerification(int index) {
    setState(() {
      itemVerificationStatus[index] = !itemVerificationStatus[index];
    });
  }

  Future<void> completePickup() async {
    String phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number.")),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No items to complete.")),
      );
      return;
    }

    QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .get();

    if (userQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found with this phone number")),
      );
      return;
    }

    String userId = userQuery.docs.first.id;

    try {
      for (int i = 0; i < items.length; i++) {
        String itemId = items[i]['itemId'];
        bool isVerified = itemVerificationStatus[i];

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection("phoneNumbers")
            .doc(phoneNumber)
            .collection("items")
            .doc(itemId)
            .update({'isVerified': isVerified});

        print("Item $itemId verification status updated to $isVerified"); // Log
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup completed successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error completing pickup: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error completing pickup: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Process Pickup"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Pickup Agent's Phone Number",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                hintText: "Enter phone number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                fetchItems();
              },
              child: const Text("Fetch Items"),
            ),
            const SizedBox(height: 20.0),
            const Text(
              "Items:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            if (items.isEmpty)
              const Text("No items found.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      toggleItemVerification(index);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: itemVerificationStatus[index]
                            ? Colors.green.shade200
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(items[index]['Name'] ?? 'Item Name'),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                completePickup();
              },
              child: const Text("Complete Pickup"),
            ),
          ],
        ),
      ),
    );
  }
}
