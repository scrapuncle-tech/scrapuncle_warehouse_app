import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:scrapuncle_warehouse/pages/add_item.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Import dart:io for File
import 'package:scrapuncle_warehouse/pages/home.dart'; // Import HomePage
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

import 'package:image_picker/image_picker.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({Key? key}) : super(key: key);

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  List<Map<String, dynamic>> products =
      []; //Still kept the products here just in case to use it in the future
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

    // Prepare the data to be stored in whpickup.  This is where we combine all info.

    Map<String, dynamic> pickupData = {
      'supervisorPhoneNumber': supervisorPhone, //From SharedPref
      'agentPhoneNumber': phoneNumber, // From the text field
      'dateTime': currentTime, // Current time.
      'itemName': itemNameController.text, // Item name.
      'itemImages': [], // Placeholder, updated below
      'vehicleImage': "", // Placeholder, updated below
      'driverImage': "", //Placeholder, updated below
    };

    //Upload Images to cloud and get the URL
    List<String> itemImageUrls = [];
    for (File imageFile in itemImages) {
      String fileName =
          'itemImages/$supervisorUid/${DateTime.now().millisecondsSinceEpoch}_${itemImages.indexOf(imageFile)}.jpg'; //Unique name
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(imageFile);
      String downloadURL = await ref.getDownloadURL();
      itemImageUrls.add(downloadURL); //Collect all the links
    }
    pickupData['itemImages'] = itemImageUrls;

    // Upload vehicle image and get URL, upload only if the image exists
    String vehicleImageUrl = ""; //Default is ""
    if (selectedVehicleImage != null) {
      String vehicleFileName =
          'vehicleImages/$supervisorUid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference vehicleRef =
          FirebaseStorage.instance.ref().child(vehicleFileName);
      await vehicleRef.putFile(selectedVehicleImage!);
      vehicleImageUrl = await vehicleRef.getDownloadURL();
    }
    pickupData['vehicleImage'] = vehicleImageUrl; // Store the URL

    // Upload driver image and get URL, upload only if the image exists
    String driverImageUrl = "";
    if (selectedDriverImage != null) {
      String driverFileName =
          'driverImages/$supervisorUid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference driverRef =
          FirebaseStorage.instance.ref().child(driverFileName);
      await driverRef.putFile(selectedDriverImage!);
      driverImageUrl = await driverRef.getDownloadURL();
    }
    pickupData['driverImage'] = driverImageUrl; // Store the URL.

    // Add the pickup data to the whpickup collection

    try {
      await whpickupCollection.add(pickupData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup completed successfully!")),
      );
      //Go back to home page
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      print("Error is here: $e");
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
            // const SizedBox(height: 20.0), // Spacing Removed the get products button
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
