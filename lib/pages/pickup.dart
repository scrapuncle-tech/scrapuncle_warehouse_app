import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({Key? key}) : super(key: key);

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  TextEditingController phoneController = TextEditingController();
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> getProducts() async {
    // clear the products before adding new ones
    setState(() {
      products = [];
    });
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    if (snapshot.docs.isNotEmpty) {
      List<Map<String, dynamic>> fetchedProducts = [];
      for (var doc in snapshot.docs) {
        var productData = doc.data() as Map<String, dynamic>;
        // Add isCollected field with initial value of false
        productData['isCollected'] = false; // Initialize isCollected
        fetchedProducts.add(productData);
      }

      setState(() {
        products = fetchedProducts;
      });
    } else {
      // Handle the case where no products are found
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No products found!'),
      ));
    }
  }

  Future<void> completePickup() async {
    String phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number.")),
      );
      return;
    }

    // Get the current supervisor ID
    String? supervisorId = await SharedPreferenceHelper().getUserId();

    if (supervisorId == null || supervisorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Supervisor ID not found. Please login again.")),
      );
      return;
    }

    // Create a new document in whpickup
    CollectionReference whpickupCollection =
        FirebaseFirestore.instance.collection('whpickup');

    //add items selected
    for (int i = 0; i < products.length; i++) {
      if (products[i]['isCollected']) {
        //Add the supervisorId to track down supervisor

        products[i]['supervisorId'] = supervisorId;

        // Add this product details to the whpickup collection
        await whpickupCollection.add(products[i]);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pickup completed successfully!")),
    );
    Navigator.pop(context);
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
                getProducts();
              },
              child: const Text("Get Products"),
            ),
            const SizedBox(height: 20.0),
            const Text(
              "Products:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(products[index]['name'] ?? 'Product Name'),
                    value: products[index]['isCollected'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        products[index]['isCollected'] = value ?? false;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                completePickup(); // Call a new function to complete pickup
              },
              child: const Text("Complete Pickup"),
            ),
          ],
        ),
      ),
    );
  }
}
