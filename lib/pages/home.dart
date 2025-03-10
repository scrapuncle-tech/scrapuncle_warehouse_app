import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/auth.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/pages/details.dart';
import 'package:intl/intl.dart';
import 'package:scrapuncle_warehouse/pages/pickup.dart'; // Import PickupPage

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? supervisorUid; // Firebase Auth UID
  String? supervisorPhone; //  Phone Number

  @override
  void initState() {
    super.initState();
    getSupervisorDetails();
  }

  Future<void> getSupervisorDetails() async {
    supervisorUid = await SharedPreferenceHelper().getUserId();
    supervisorPhone = await SharedPreferenceHelper()
        .getUserPhoneNumber(); //Get phonenumber from sharedpreferences

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Get today's date in the same format as stored in Firestore

    return Scaffold(
      appBar: AppBar(
        title: const Text("Warehouse - Home"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: () {
              AuthMethods().SignOut(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        // Removed SingleChildScrollView
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Supervisor: ${supervisorPhone ?? 'Supervisor'}!", // Show the supervisorPhone now
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20.0),
            child: Text(
              "Completed Pickups",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('whpickup')
                .where('supervisorPhoneNumber', isEqualTo: supervisorPhone)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No completed pickups yet.'),
                );
              }

              return Expanded(
                // Added Expanded
                child: ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Ensure scrolling works
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var itemData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    return InkWell(
                      // Changed to InkWell for tap feedback
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Details(itemData: itemData),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Item Name: ${itemData['itemName'] ?? 'N/A'}", // changed to new field name
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  "Driver Number: ${itemData['driverPhoneNumber'] ?? 'N/A'}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Add this FAB
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PickupPage()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
