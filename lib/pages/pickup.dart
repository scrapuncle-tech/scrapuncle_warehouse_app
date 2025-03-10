import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/home.dart';
import 'package:scrapuncle_warehouse/service/database.dart'; // You might not directly use this, but good practice to keep
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:scrapuncle_warehouse/pages/add_item.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Add this import

class PickupPage extends StatefulWidget {
  const PickupPage({Key? key}) : super(key: key);

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  TextEditingController driverPhoneNumberController =
      TextEditingController(); // NEW
  TextEditingController vehicleNumberController =
      TextEditingController(); // NEW
  List<Map<String, dynamic>> products = []; //No changes
  String currentTime = "";
  List<File> itemImages = []; // For multiple item images
  File? selectedVehicleImage;
  File? selectedDriverImage;
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        itemImages.add(File(pickedFile.path));
      });
    }
  }

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

  // Remove image at an index
  void _removeImage(int index) {
    setState(() {
      itemImages.removeAt(index);
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

  Future<void> _completePickup() async {
    final String phoneNumber = phoneController.text.trim();
    final String itemName = itemNameController.text.trim();
    final String driverPhoneNumber =
        driverPhoneNumberController.text.trim(); // NEW
    final String vehicleNumber = vehicleNumberController.text.trim(); // NEW

    if (phoneNumber.isEmpty) {
      _showError("Please enter a pickup agent's phone number.");
      return;
    }

    if (itemName.isEmpty) {
      _showError("Please enter an item name.");
      return;
    }

    if (itemImages.isEmpty) {
      _showError("Please take at least one item photo.");
      return;
    }
    if (driverPhoneNumber.isEmpty) {
      _showError("Please enter the driver's phone number."); //NEW
      return;
    }
    if (vehicleNumber.isEmpty) {
      _showError("Please enter the vehicle number."); //NEW
      return;
    }

    String? supervisorPhone =
        await SharedPreferenceHelper().getUserPhoneNumber();
    if (supervisorPhone == null || supervisorPhone.isEmpty) {
      _showError("Supervisor phone number not found.  Please log in again.");
      return;
    }
    try {
      // 1. Upload Images and Get URLs
      List<String> itemImageUrls = [];
      for (File imageFile in itemImages) {
        String fileName =
            'itemImages/$supervisorPhone/${DateTime.now().millisecondsSinceEpoch}_${itemImages.indexOf(imageFile)}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(imageFile);
        String downloadURL = await ref.getDownloadURL();
        itemImageUrls.add(downloadURL);
      }

      String vehicleImageUrl = "";
      if (selectedVehicleImage != null) {
        String vehicleFileName =
            'vehicleImages/$supervisorPhone/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference vehicleRef =
            FirebaseStorage.instance.ref().child(vehicleFileName);
        await vehicleRef.putFile(selectedVehicleImage!);
        vehicleImageUrl = await vehicleRef.getDownloadURL();
      }

      // Upload driver image and get URL, upload only if the image exists
      String driverImageUrl = "";
      if (selectedDriverImage != null) {
        String driverFileName =
            'driverImages/$supervisorPhone/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference driverRef =
            FirebaseStorage.instance.ref().child(driverFileName);
        await driverRef.putFile(selectedDriverImage!);
        driverImageUrl = await driverRef.getDownloadURL();
      }
      // 2. Prepare Data for Firestore
      Map<String, dynamic> pickupData = {
        'supervisorPhoneNumber': supervisorPhone,
        'agentPhoneNumber': phoneNumber,
        'dateTime': currentTime,
        'itemName': itemName,
        'itemImages': itemImageUrls,
        'vehicleImage': vehicleImageUrl,
        'driverImage': driverImageUrl,
        'driverPhoneNumber': driverPhoneNumber, // NEW
        'vehicleNumber': vehicleNumber, // NEW
      };

      // 3. Write to Firestore
      await FirebaseFirestore.instance.collection('whpickup').add(pickupData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Pickup completed successfully!"),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error!"), backgroundColor: Colors.red),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Realtime Time/Date: $currentTime",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: itemNameController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Pickup Agent's Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text("Add Details"),
            ),
            const SizedBox(height: 24),
            const Text(
              "Item Images",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: itemImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(itemImages[index],
                            width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            color: Colors.red,
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Driver Phone Number", // Added driver phone number heading
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              // Added text field for driver phone number
              controller: driverPhoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Driver Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              "Driver Image",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: getDriverImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedDriverImage != null)
              Image.file(
                selectedDriverImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 24),
            const Text(
              "Vehicle Number", // Added vehicle number heading
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              //Added text field for vehicle number
              controller: vehicleNumberController,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping), //Using a truck icon
              ),
            ),
            const Text(
              "Vehicle Image",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: getVehicleImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedVehicleImage != null)
              Image.file(
                selectedVehicleImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _completePickup();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Complete Pickup",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
