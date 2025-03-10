import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/home.dart';
import 'package:scrapuncle_warehouse/service/database.dart'; // You might not directly use this, but good practice to keep
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:scrapuncle_warehouse/pages/add_item.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    _updateCurrentTime(); // Initial time setting.
  }

  void _updateCurrentTime() {
    setState(() {
      currentTime = DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now());
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        itemImages.add(File(pickedFile.path));
      });
    }
  }

  // Remove image at an index
  void _removeImage(int index) {
    setState(() {
      itemImages.removeAt(index);
    });
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
    // Get today's date in 'yyyy-MM-dd' format
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. Upload Images and Get URLs (if they exist)
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
        'DateTime': currentTime, // Use the captured currentTime
        'itemName': itemName, // From the text field.
        'itemImages': itemImageUrls, // List of image URLs
        'vehicleImage': vehicleImageUrl, // URL, possibly empty
        'driverImage': driverImageUrl, // URL, possibly empty
        'driverPhoneNumber': driverPhoneNumberController.text,
        'vehicleNumber': vehicleNumberController.text,
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
        title: const Text("Process Pickup"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Enter phone number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10.0),
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
                const SizedBox(height: 8.0),
                TextField(
                  // Added text field for driver phone number
                  controller: driverPhoneNumberController,
                  decoration: const InputDecoration(
                    labelText: "Driver Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
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
                TextField(
                  //Added text field for vehicle number
                  controller: vehicleNumberController,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping), //Using a truck icon
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
            const SizedBox(height: 20.0),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _completePickup();
              },
              child: const Text("Complete Pickup"),
            ),
          ],
        ),
      ),
    );
  }
}
