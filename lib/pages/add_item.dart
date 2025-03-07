import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart'; // Import for local storage
import 'package:intl/intl.dart'; // For date formatting

class AddItem extends StatefulWidget {
  final String phoneNumber; // Receive phone number from PickupPage

  const AddItem({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  TextEditingController nameController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController vehicleNumberController =
      TextEditingController(); //Vehicle number
  TextEditingController driverPhoneNumberController =
      TextEditingController(); //Driver phone number
  final ImagePicker _picker = ImagePicker();
  File? selectedItemImage; //Item Image
  File? selectedVehicleImage; //Vehicle Image
  File? selectedDriverImage; //Driver Image
  String? userId;
  String currentTime = ""; // Store the real-time date and time
  bool _isLoading = false; // Add a loading indicator

  @override
  void initState() {
    super.initState();
    initialize();
    // Set the initial time
    currentTime = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());

    // Update the time every minute
    Future.delayed(Duration.zero, () async {
      while (mounted) {
        await Future.delayed(const Duration(minutes: 1));
        if (mounted) {
          setState(() {
            currentTime =
                DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedItemImage = File(image.path);
      setState(() {});
    }
  }

  Future<void> getVehicleImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedVehicleImage = File(image.path);
      setState(() {});
    }
  }

  Future<void> getDriverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedDriverImage = File(image.path);
      setState(() {});
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    vehicleNumberController.dispose();
    driverPhoneNumberController.dispose();
    super.dispose();
  }

  Future<void> uploadItem() async {
    if (selectedItemImage != null &&
        nameController.text.isNotEmpty &&
        weightController.text.isNotEmpty &&
        vehicleNumberController.text.isNotEmpty && //Vehicle Number is added
        driverPhoneNumberController
            .text.isNotEmpty && //Driver Phone Number is added
        userId != null) {
      String addId = randomAlphaNumeric(10);

      String itemFileName = '$userId/$addId/itemImage';
      String vehicleFileName = '$userId/$addId/vehicleImage';
      String driverFileName = '$userId/$addId/driverImage';

      Reference itemFirebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("itemImages")
          .child(itemFileName);
      Reference vehicleFirebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("vehicleImages")
          .child(vehicleFileName);
      Reference driverFirebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("driverImages")
          .child(driverFileName);

      String itemDownloadUrl = "";
      String vehicleDownloadUrl = "";
      String driverDownloadUrl = "";

      try {
        await itemFirebaseStorageRef.putFile(selectedItemImage!);
        itemDownloadUrl = await itemFirebaseStorageRef.getDownloadURL();

        if (selectedVehicleImage != null) {
          await vehicleFirebaseStorageRef.putFile(selectedVehicleImage!);
          vehicleDownloadUrl = await vehicleFirebaseStorageRef.getDownloadURL();
        }

        if (selectedDriverImage != null) {
          await driverFirebaseStorageRef.putFile(selectedDriverImage!);
          driverDownloadUrl = await driverFirebaseStorageRef.getDownloadURL();
        }

        Map<String, dynamic> addItem = {
          "ItemImage": itemDownloadUrl,
          "PhoneNumber": widget.phoneNumber, // Use passed phone number
          "Name": nameController.text,
          "WeightOrQuantity": weightController.text,
          "VehicleNumber": vehicleNumberController.text, //Vehicle number
          "VehicleImage": vehicleDownloadUrl, //vehicle photo
          "DriverPhoneNumber":
              driverPhoneNumberController.text, //Driver phone number
          "DriverImage": driverDownloadUrl, //Driver Photo
          "userId": userId,
          "itemId": addId,
          "DateTime": currentTime,
        };

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                "Item has been added Successfully",
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              )));
          Navigator.pop(context, addItem);
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

  // Function to add data to Firebase Realtime Database
  Future<void> addDataToRealtimeDatabase(Map<String, dynamic> itemData) async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref(); // Get reference to the root
    try {
      await ref
          .child('items')
          .child(userId!)
          .child(itemData['itemId'])
          .set(itemData);
      print("Data added to Realtime Database successfully!");
    } catch (e) {
      print("Error adding data to Realtime Database: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Failed to upload item to Realtime Database: $e",
              style: const TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
        );
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
                child: CircularProgressIndicator(), // Show loading indicator
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
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Item Name",
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Text(
                      "Item Weight or Quantity",
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
                        controller: weightController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Item Weight or Quantity",
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Text(
                      "Vehicle Number",
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
                        controller: vehicleNumberController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Vehicle Number",
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
