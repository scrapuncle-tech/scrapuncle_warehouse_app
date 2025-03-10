import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:scrapuncle_warehouse/pages/home.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:scrapuncle_warehouse/pages/add_item.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

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
  String currentTime = "";
  File? selectedVehicleImage;
  File? selectedDriverImage;
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker

  @override
  void initState() {
    super.initState();
    _updateCurrentTime(); // Initial time setting.
  }

  void _updateCurrentTime() {
    setState(() {
      currentTime = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
    });
    // Update every minute.  We do this here, not in build, to avoid
    // unnecessary rebuilds.
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _updateCurrentTime();
      }
    });
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

    //Removing Item Name from whpickup
    // if (itemName.isEmpty) {
    //   _showError("Please enter an item name.");
    //   return;
    // }

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
    // Get today's date in 'yyyy-MM-dd' format
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. Upload Images and Get URLs (if they exist)
      // Removed the item images part

      String vehicleImageUrl = "";
      if (selectedVehicleImage != null) {
        String vehicleFileName =
            'vehicleImages/$supervisorPhone/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference vehicleRef =
            FirebaseStorage.instance.ref().child(vehicleFileName);
        await vehicleRef.putFile(selectedVehicleImage!);
        vehicleImageUrl = await vehicleRef.getDownloadURL();
      }

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
        'supervisorPhoneNumber': supervisorPhone, //From SharedPref
        'agentPhoneNumber': phoneNumber, // From the text field
        'dateTime': currentTime, // Use the captured currentTime
        'itemName': itemName, // From the text field.
        'vehicleImage': vehicleImageUrl, // URL, possibly empty
        'driverImage': driverImageUrl, // URL, possibly empty
        'driverPhoneNumber': driverPhoneNumber,
        'vehicleNumber': vehicleNumber,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error completing pickup! Check Logs"),
              backgroundColor: Colors.red),
        );
      }
      print("Error completing pickup: $error"); // Log the error
    }
  }

  void _showError(String message) {
    if (mounted) {
      // Important: Check if the widget is still mounted
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
        title: const Text("New Pickup"), // Consistent title
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Realtime Time/Date: $currentTime", // Display current time
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            //Removed item name from the page
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
            TextField(
              controller: driverPhoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Driver Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: vehicleNumberController,
              keyboardType: TextInputType
                  .text, // Changed to text, since vehicle numbers are not strictly numeric.
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping), //Using a truck icon
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
                backgroundColor: Colors.green, // Changed button color
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12), // Added some padding
                textStyle: const TextStyle(fontSize: 16), // Adjusted font size
              ),
              child: const Text("Add Items",
                  style: TextStyle(color: Colors.white)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10.0),
                const SizedBox(height: 10.0),
                const Text(
                  "Click Photo of Driver From Camera",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: getDriverImage,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Take Photo",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                  )
                else
                  const Center(
                    child: Text(
                      "No Driver image",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ), // Placeholder

                const SizedBox(height: 24),
                const Text(
                  "Click Photo of Vehicle From Camera",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: getVehicleImage,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Take Photo",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                  )
                else
                  const Center(
                    child: Text(
                      "No Vehicle image",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                // Placeholder

                // Add more widgets for other input fields here
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completePickup,
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
            const SizedBox(height: 24), // Keep the spacing.
          ],
        ),
      ),
    );
  }
}
