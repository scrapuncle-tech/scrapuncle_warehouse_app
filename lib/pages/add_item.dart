import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItem extends StatefulWidget {
  final String phoneNumber;

  const AddItem({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  TextEditingController driverPhoneNumberController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedItemImage;
  File? selectedDriverImage;
  File? selectedVehicleImage;

  String? userId;
  String currentTime = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initialize();
    // Set the initial time
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

  Future<void> initialize() async {
    setState(() {
      _isLoading = true;
    });
    await getUserId();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> getUserId() async {
    userId = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  Future<void> getItemImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera); // Changed to Camera
    if (image != null) {
      selectedItemImage = File(image.path);
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

  Future<void> getVehicleImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera); // Changed to Camera
    if (image != null) {
      selectedVehicleImage = File(image.path);
      setState(() {});
    }
  }

  @override
  void dispose() {
    driverPhoneNumberController.dispose();
    itemNameController.dispose();
    super.dispose();
  }

  Future<void> uploadItem() async {
    if (selectedItemImage != null &&
        driverPhoneNumberController.text.isNotEmpty &&
        itemNameController.text.isNotEmpty &&
        userId != null) {
      String addId = randomAlphaNumeric(10);

      String itemFileName = '$userId/$addId/itemImage';
      String driverFileName = '$userId/$addId/driverImage';
      String vehicleFileName = '$userId/$addId/vehicleImage';

      Reference itemFirebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("itemImages")
          .child(itemFileName);
      Reference driverFirebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("driverImages")
          .child(driverFileName);
      Reference vehicleFirebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("vehicleImages")
          .child(vehicleFileName);

      String itemDownloadUrl = "";
      String driverDownloadUrl = "";
      String vehicleDownloadUrl = "";

      try {
        await itemFirebaseStorageRef.putFile(selectedItemImage!);
        itemDownloadUrl = await itemFirebaseStorageRef.getDownloadURL();

        if (selectedDriverImage != null) {
          await driverFirebaseStorageRef.putFile(selectedDriverImage!);
          driverDownloadUrl = await driverFirebaseStorageRef.getDownloadURL();
        }
        if (selectedVehicleImage != null) {
          await vehicleFirebaseStorageRef.putFile(selectedVehicleImage!);
          vehicleDownloadUrl = await vehicleFirebaseStorageRef.getDownloadURL();
        }

        Map<String, dynamic> whitems = {
          "ItemImage": itemDownloadUrl,
          "ItemName": itemNameController.text,
          "DriverPhoneNumber": driverPhoneNumberController.text,
          "DriverImage": driverDownloadUrl,
          "VehicleImage": vehicleDownloadUrl,
          "userId": userId,
          "whitemId": addId,
          "DateTime": currentTime,
          "test": "Testing to make sure it pushed in Firebase"
        };

        // Add whitems to firestore

        await FirebaseFirestore.instance
            .collection('whitems')
            .doc(addId)
            .set(whitems);
        print("Item data added successfully to Firestore");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                "Item has been added Successfully",
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              )));
          Navigator.pop(context, whitems);
        }
      } catch (e) {
        print("Error uploading item: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Failed to upload item: $e",
                style: const TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          );
        }
      }
    } else {
      String message = "Please fill all the fields and select an image";
      if (userId == null) {
        message = "User ID not found. Please login again.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            message,
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Add Item"),
          backgroundColor: Colors.green,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
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
                    const SizedBox(height: 20.0),
                    const Text(
                      "Item Name",
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
                          hintText: "Enter ItemName",
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const SizedBox(height: 30.0),
                    const Text(
                      "Upload the Item Picture",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () {
                        getItemImage();
                      },
                      child: Center(
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.green, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: selectedItemImage == null
                                ? const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.green,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      selectedItemImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Text(
                      "Upload the Vehicle Picture",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () {
                        getVehicleImage();
                      },
                      child: Center(
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.green, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: selectedVehicleImage == null
                                ? const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.green,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      selectedVehicleImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Text(
                      "Driver Phone Number",
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
                        controller: driverPhoneNumberController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Driver Phone Number",
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Text(
                      "Upload the Driver Picture",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () {
                        getDriverImage();
                      },
                      child: Center(
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.green, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: selectedDriverImage == null
                                ? const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.green,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      selectedDriverImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: () {
                          uploadItem();
                        },
                        child: const Text('Add Item',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ));
  }
}
