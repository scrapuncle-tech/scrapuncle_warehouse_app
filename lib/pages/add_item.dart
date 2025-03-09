import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart'; // Import random_string

class AddItem extends StatefulWidget {
  final String phoneNumber;

  const AddItem({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  String currentTime = "";
  bool _isLoading = false;
  List<Map<String, dynamic>> products = [];
  String? supervisorPhoneNumber;

  @override
  void initState() {
    super.initState();
    initialize();
    currentTime = DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now());

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
    supervisorPhoneNumber = await SharedPreferenceHelper()
        .getUserPhoneNumber(); // Get supervisor's phone number

    await getProducts();
    setState(() {
      _isLoading = false;
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

  Future<void> uploadItems() async {
    // Get the list of collected products
    List<Map<String, dynamic>> collectedProducts =
        products.where((product) => product['isCollected'] == true).toList();

    if (collectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No products selected!'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (supervisorPhoneNumber == null || supervisorPhoneNumber!.isEmpty) {
        //null check
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Supervisor Phone Number not found."),
          ));
        }

        return;
      }
      // Store the collected products
      for (var item in collectedProducts) {
        String whitemId = randomAlphaNumeric(10);
        item['whitemId'] = whitemId;
        item['phoneNumber'] = widget.phoneNumber;
        item['DateTime'] = currentTime; //now add the date and time
        item['supervisorPhoneNumber'] =
            supervisorPhoneNumber; // Add supervisor's phone number
        await FirebaseFirestore.instance
            .collection('whitems')
            .doc(whitemId)
            .set(item);
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Items has been added Successfully",
            style: TextStyle(fontSize: 18.0, color: Colors.white),
          )));

      Navigator.pop(context); //Return to the pickup page
    } catch (e) {
      print("Error uploading items: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Failed to upload items: $e",
          style: const TextStyle(fontSize: 18.0, color: Colors.white),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Details"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    "Products:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  ListView.builder(
                    shrinkWrap: true, // add this
                    physics: const NeverScrollableScrollPhysics(), // add this
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
                  const SizedBox(height: 20.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: uploadItems,
                      child: const Text("Add Items"), // Changed the button name
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
