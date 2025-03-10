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
              "Item Name: ${itemData['itemName'] ?? 'N/A'}", // Correct field name
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Supervisor Phone: ${itemData['supervisorPhoneNumber'] ?? 'N/A'}", // Correct field name
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Agent Phone: ${itemData['agentPhoneNumber'] ?? 'N/A'}", // Correct field name
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),

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
              "Vehicle Number: ${itemData['vehicleNumber'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            if (itemData['vehicleImage'] != null &&
                itemData['vehicleImage'].isNotEmpty)
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
                    itemData['vehicleImage'], // Correct field name
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                          Icons.error); // Placeholder for broken images
                    },
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
              "Driver Phone: ${itemData['driverPhoneNumber'] ?? 'N/A'}", // Correct field name
              style: const TextStyle(fontSize: 16),
            ),
            if (itemData['driverImage'] != null &&
                itemData['driverImage'].isNotEmpty)
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
                    itemData['driverImage'], // Correct field name
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                          Icons.error); // Placeholder for broken images.
                    },
                  ),
                ],
              ),

            // added a part where all the images collected from the pickup page is outputted
            const SizedBox(height: 20),
            const Text(
              "Item Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (itemData['itemImages'] != null &&
                (itemData['itemImages'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Item Images:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 200, // Set a fixed height for the horizontal list
                    child: ListView.builder(
                      scrollDirection:
                          Axis.horizontal, // Display images horizontally
                      itemCount: itemData['itemImages'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Add some spacing
                          child: Image.network(
                            itemData['itemImages']
                                [index], // Access each image URL
                            height: 200,
                            width: 200, // Adjust the image size as needed
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error); // Placeholder
                            },
                          ),
                        );
                      },
                    ),
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
