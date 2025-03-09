import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:scrapuncle_warehouse/pages/add_item.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Import dart:io for File

import 'package:image_picker/image_picker.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({Key? key}) : super(key: key);

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  List<Map<String, dynamic>> products = [];
  String currentTime = "";
  List<File> itemImages = [];
  File? selectedVehicleImage;
  File? selectedDriverImage;

  Future<void> getVehicleImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera); // Changed to Camera
    if (image != null) {
      selectedVehicleImage = File(image.path);
      setState(() {});
    }
  }

  Future<void> getDriverImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera); // Changed to Camera
    if (image != null) {
      selectedDriverImage = File(image.path);
      setState(() {});
    }
  }

  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    currentTime = DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now());

    // Update the time every minute
    Future.delayed(Duration.zero, () async {
      while (mounted) {
        await Future.delayed(const Duration(minutes: 1));
        if (mounted) {
          setState(() {
            currentTime =
                DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now());
          });
        }
      }
    });
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

    // Get the current supervisor Firebase Auth UID and supervisorPhone
    String? supervisorUid = await SharedPreferenceHelper().getUserId();
    String? supervisorPhone =
        await SharedPreferenceHelper().getUserPhoneNumber();

    if (supervisorUid == null ||
        supervisorUid.isEmpty ||
        supervisorPhone == null ||
        supervisorPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Supervisor Phone Number not found. Please login again.")),
      );
      return;
    }

    // Create a new document in whpickup
    CollectionReference whpickupCollection =
        FirebaseFirestore.instance.collection('whpickup');

    //add items selected
    for (int i = 0; i < products.length; i++) {
      if (products[i]['isCollected']) {
        //Add the supervisorPhone to track down supervisor

        products[i]['supervisorPhoneNumber'] = supervisorPhone;

        // Add the currentTime
        products[i]['DateTime'] = currentTime;

        // Add this product details to the whpickup collection
        await whpickupCollection.add(products[i]);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pickup completed successfully!")),
    );
    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        itemImages.add(File(pickedFile.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Process Pickup"),
          backgroundColor: Colors.green,
          actions:
              //Add the superivosrPhone to show in the UI

              [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "The phone number: ${phoneController.text}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Realtime Time/Date",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                currentTime,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Text(
              "Enter Item Name",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Item Name",
                ),
              ),
            ),
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
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                getProducts();
              },
              child: const Text("Update phone Number"),
            ),
            const SizedBox(height: 20.0), // Spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddItem(phoneNumber: phoneController.text),
                  ),
                );
              },
              child: const Text("Add Details"),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10.0),
                const Text(
                  "Click Photos of Items From Camera",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _pickImage();
                  },
                  child: const Text("Take items photos"),
                ),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: itemImages.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          itemImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  "Click Photo of Driver From Camera",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    getDriverImage();
                  },
                  child: const Text("Take driver photos"),
                ),
                if (selectedDriverImage != null)
                  Image.file(
                    selectedDriverImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                else
                  Container(),
                const SizedBox(height: 10.0),
                const Text(
                  "Click Photo of Vehicle From Camera",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    getVehicleImage();
                  },
                  child: const Text("Take vehicle photos"),
                ),
                if (selectedVehicleImage != null)
                  Image.file(
                    selectedVehicleImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                else
                  Container(),
              ],
            ),

            // const SizedBox(height: 20.0),
            // const Text(
            //   "Products:",
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 10.0),
            // ListView.builder(
            //   shrinkWrap: true, // add this
            //   physics: const NeverScrollableScrollPhysics(), // add this
            //   itemCount: products.length,
            //   itemBuilder: (context, index) {
            //     return CheckboxListTile(
            //       title: Text(products[index]['name'] ?? 'Product Name'),
            //       value: products[index]['isCollected'] ?? false,
            //       onChanged: (bool? value) {
            //         setState(() {
            //           products[index]['isCollected'] = value ?? false;
            //         });
            //       },
            //     );
            //   },
            // ),
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
