import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/service/auth.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? profile, name, email, phoneNumber;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImage = File(image.path);
      setState(() {
        uploadItem();
      });
    }
  }

  uploadItem() async {
    if (selectedImage != null) {
      String addId = randomAlphaNumeric(10);

      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child("profileImages").child(addId);
      final UploadTask task = firebaseStorageRef.putFile(selectedImage!);

      var downloadUrl = await (await task).ref.getDownloadURL();
      await SharedPreferenceHelper().saveUserProfile(downloadUrl);
      setState(() {});
    }
  }

  getthesharedpref() async {
    profile = await SharedPreferenceHelper().getUserProfile();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    phoneNumber = await SharedPreferenceHelper().getUserPhoneNumber();
    setState(() {});
  }

  onthisload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    onthisload();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supervisor Profile"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  getImage();
                },
                child: Stack(
                  children: [
                    Material(
                      elevation: 10.0,
                      borderRadius: BorderRadius.circular(60),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: selectedImage == null
                            ? (profile == null
                                ? Image.network(
                                    "https://i.pravatar.cc/300",
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    profile!,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ))
                            : Image.file(
                                selectedImage!,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name ?? "Loading...",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Name",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          name ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    const Icon(Icons.email),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          email ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Phone Number",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          phoneNumber ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  AuthMethods().deleteUser();
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Delete Account",
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  AuthMethods().SignOut(context);
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label:
                    const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
