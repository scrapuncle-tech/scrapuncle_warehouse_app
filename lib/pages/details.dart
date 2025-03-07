import 'package:flutter/material.dart';

class Details extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const Details({Key? key, required this.itemData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Details"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Item Name: ${itemData['Name'] ?? 'N/A'}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Weight/Quantity: ${itemData['WeightOrQuantity'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Pickup Agent Phone: ${itemData['PhoneNumber'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Vehicle Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Vehicle Number: ${itemData['VehicleNumber'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            if (itemData['VehicleImage'] != null &&
                itemData['VehicleImage'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Vehicle Image:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Image.network(
                    itemData['VehicleImage'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              "Driver Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Driver Phone: ${itemData['DriverPhoneNumber'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            if (itemData['DriverImage'] != null &&
                itemData['DriverImage'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Driver Image:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Image.network(
                    itemData['DriverImage'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Text(
              "Date/Time: ${itemData['DateTime'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
