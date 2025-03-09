import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/auth.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrapuncle_warehouse/pages/details.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? supervisorUid; // Firebase Auth UID
  String? supervisorId; // ID from Firestore

  @override
  void initState() {
    super.initState();
    getSupervisorIds();
  }

  Future<void> getSupervisorIds() async {
    supervisorUid = await SharedPreferenceHelper().getUserId();
    supervisorId =
        await SharedPreferenceHelper().getSupervisorId(); //Get supervisorId

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SupervisorID: ${supervisorId ?? 'Supervisor'}!", // Show the supervisorId now, not UID
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Completed Pickups",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('whpickup')
                  .where('supervisorId',
                      isEqualTo:
                          supervisorId) //Now compare with the supervisor id
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No completed pickups yet.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var itemData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Details(itemData: itemData),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Item Name: ${itemData['name'] ?? 'N/A'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  "Price: ${itemData['price'] ?? 'N/A'}"), // changed to the products' prices
                              Text(
                                  "Unit: ${itemData['unit'] ?? 'N/A'}"), // added the products' unit
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
