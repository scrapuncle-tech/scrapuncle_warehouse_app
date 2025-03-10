import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:random_string/random_string.dart';

class AddItem extends StatefulWidget {
  final String phoneNumber;

  const AddItem({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = []; // List to store multiple images
  String currentTime = "";
  bool _isLoading = false;

  List<Map<String, dynamic>> productList = [];
  Map<String, dynamic>? selectedProduct;
  String selectedUnit = "";
  String productName = ""; // For "Other" product

  TextEditingController kgController = TextEditingController();
  TextEditingController gramController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController totalPriceController =
      TextEditingController(); // Read-only

  @override
  void initState() {
    super.initState();
    currentTime = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      List<Map<String, dynamic>> products = querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "name": doc["name"],
          "unit": doc["unit"],
          "price": doc["price"],
        };
      }).toList();

      setState(() {
        productList = products;
        productList.add({"id": "other", "name": "Other"}); // Add "Other" option
      });
    } catch (e) {
      // Show error using ScaffoldMessenger
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to fetch products: $e",
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void updateTotalPrice() {
    double price = double.tryParse(priceController.text) ?? 0.0;
    double total = 0.0;

    if (selectedUnit == "weight") {
      double kg = double.tryParse(kgController.text) ?? 0.0;
      double grams = double.tryParse(gramController.text) ?? 0.0;
      double weightInKg = kg + (grams / 1000);
      total = weightInKg * price;
    } else if (selectedUnit == "quantity") {
      int quantity = int.tryParse(quantityController.text) ?? 0;
      total = quantity * price;
    }

    totalPriceController.text =
        total.toStringAsFixed(2); // Show 2 decimal places
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path)); // Add to the list
      });
    }
  }

  //Remove Image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadItem() async {
    // Input Validation (same as before, but now checks for at least one image)
    if (_selectedImages.isEmpty) {
      _showError("Please take at least one photo of the item.");
      return;
    }

    if (selectedProduct == null) {
      _showError("Please select a product.");
      return;
    }

    // Validate "Other" product input
    if (selectedProduct!['id'] == 'other') {
      if (productName.isEmpty) {
        _showError("Please enter a product name.");
        return;
      }
      if (selectedUnit.isEmpty) {
        _showError("Please select a unit.");
        return;
      }
    }

    if (selectedUnit == "weight" &&
        kgController.text.isEmpty &&
        gramController.text.isEmpty) {
      _showError("Please enter weight.");
      return;
    }

    if (selectedUnit == "quantity" && quantityController.text.isEmpty) {
      _showError("Please enter quantity.");
      return;
    }

    if (priceController.text.isEmpty) {
      _showError("Please enter price per unit");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? supervisorPhone =
          await SharedPreferenceHelper().getUserPhoneNumber();
      if (supervisorPhone == null || supervisorPhone.isEmpty) {
        if (mounted) {
          _showError("Supervisor phone number not found. Please log in again.");
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Upload Images and Get URLs
      List<String> imageUrls = [];
      for (File imageFile in _selectedImages) {
        String fileName =
            'itemImages/$supervisorPhone/${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(imageFile)}.jpg'; // Include index in filename.
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(imageFile);
        String downloadURL = await ref.getDownloadURL();
        imageUrls.add(downloadURL);
      }

      // 2. Prepare Data
      String itemId = randomAlphaNumeric(10);
      Map<String, dynamic> itemData = {
        'whitemId': itemId,
        'images': imageUrls, // Now a list of URLs
        'supervisorPhoneNumber': supervisorPhone, //From SharedPref
        'agentPhoneNumber': widget.phoneNumber, //Passed from PickupPage
        'dateTime': currentTime, //Current time
      };

      //Handle "Other" product case:

      if (selectedProduct!['id'] == 'other') {
        itemData['product'] = {
          'id':
              'custom_$itemId', // Use a unique ID, to prevent any problems in the cloud
          'name': productName, // Custom product name
          'unit': selectedUnit,
          'price':
              double.tryParse(priceController.text) ?? 0.0, //Parse the value
        };
      } else {
        itemData['product'] = selectedProduct; // The selected product
      }

      // Weight/Quantity
      if (selectedUnit == "weight") {
        itemData['weightOrQuantity'] =
            "${kgController.text.isEmpty ? '0' : kgController.text} kg, ${gramController.text.isEmpty ? '0' : gramController.text} grams";
      } else if (selectedUnit == "quantity") {
        itemData['weightOrQuantity'] = quantityController.text;
      }

      //Total Price
      itemData['totalPrice'] = totalPriceController.text;

      // 3. Write to Firestore
      await FirebaseFirestore.instance
          .collection('whitems')
          .doc(itemId)
          .set(itemData);

      // 4. Success Handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Item added successfully!"),
        ));
        Navigator.pop(context); //Go back!
      }
    } catch (e) {
      print("Error uploading item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to upload item: $e",
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ));
      }
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
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
        title: const Text("Add Item"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Added current time display.
                    "Realtime Time/Date: $currentTime",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Select Product",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedProduct,
                    items: productList
                        .map((product) => DropdownMenuItem(
                              value: product,
                              child: Text(product["name"]),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProduct = value;
                        selectedUnit = value?["unit"] ?? "";
                        priceController.text =
                            value?["price"]?.toString() ?? "";
                        // Clear other fields when product changes
                        kgController.text = "";
                        gramController.text = "";
                        quantityController.text = "";
                        totalPriceController.text = "";
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Product",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  // "Other" product options
                  if (selectedProduct?["id"] == "other") ...[
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Product Name",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => productName = val,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUnit.isEmpty ? null : selectedUnit,
                      items: ["weight", "quantity"]
                          .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(
                                  unit[0].toUpperCase() + unit.substring(1))))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedUnit = value!;
                        // Clear fields when unit type changes
                        kgController.text = "";
                        gramController.text = "";
                        quantityController.text = "";
                        totalPriceController.text = "";
                      }),
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Price per Unit",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => updateTotalPrice(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Weight fields (show only if unit is weight)
                  if (selectedUnit == "weight") ...[
                    const Text("Enter Weight",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: kgController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Kilograms (kg)",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => updateTotalPrice(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: gramController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Grams (g)",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => updateTotalPrice(),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Quantity field (show only if unit is quantity)
                  if (selectedUnit == "quantity") ...[
                    const Text("Enter Quantity",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => updateTotalPrice(),
                    ),
                  ],

                  // Total price field (read-only, shows calculated price)
                  if (selectedUnit.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: totalPriceController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Total Price",
                        filled: true,
                        fillColor: Colors.grey,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text("Upload Item Picture",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
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

                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Image.file(_selectedImages[index],
                                  width: 100, height: 100, fit: BoxFit.cover),
                              Positioned(
                                // Position the close button
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    color: Colors.red,
                                    child: const Icon(Icons.close,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _uploadItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text('Add Item',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
