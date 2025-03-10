import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/bottom_nav.dart';
import 'package:scrapuncle_warehouse/service/database.dart'; // Import DatabaseMethods
import 'package:scrapuncle_warehouse/pages/signup.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart'; // Import SharedPreferenceHelper
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "", password = "";
  TextEditingController userEmailController = TextEditingController();
  TextEditingController userPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    userEmailController.dispose();
    userPasswordController.dispose();
    super.dispose();
  }

  userLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // 1. Authenticate with Firebase Auth
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        // 2. Get the Firebase Auth UID.
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // 3. Query Firestore to find the supervisor document with the matching email.
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('supervisors')
            .where('Email',
                isEqualTo: email) // Match on EMAIL, as provided in signup
            .get();

        // 4. Check if a document was found.
        if (querySnapshot.docs.isNotEmpty) {
          // 5. Get the first document (there should only be one).
          DocumentSnapshot supervisorDoc = querySnapshot.docs.first;

          // 6. Extract the supervisorId and PhoneNumber from the document.
          String supervisorId = supervisorDoc.id; // Get DOCUMENT ID
          String supervisorPhone = supervisorDoc['PhoneNumber'];

          // 7. Save both the UID and supervisorId to Shared Preferences.
          await SharedPreferenceHelper().saveUserId(
              uid); // Save Firebase Auth UID for authentication purposes.
          await SharedPreferenceHelper().saveSupervisorId(
              supervisorId); // Save the Firestore document ID.
          await SharedPreferenceHelper()
              .saveUserPhoneNumber(supervisorPhone); // Save the Phone Number

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNav()),
            );
          }
        } else {
          print("Supervisor document not found!");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                  "Supervisor document not found. Please contact the admin."),
            ));
          }
          return; // Important: Don't proceed if no document is found.
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Login failed";
        if (e.code == 'user-not-found') {
          errorMessage = "No user found for that Email";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Wrong Password provided by User";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              errorMessage,
              style: const TextStyle(fontSize: 18),
            ),
          ));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supervisor Login"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset('images/ScrapUncle.png',
                          height: 200, width: 300),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: userEmailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter Email";
                        }
                        if (!value.contains('@')) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: userPasswordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter Password";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
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
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            email = userEmailController.text;
                            password = userPasswordController.text;
                          });
                          userLogin();
                        }
                      },
                      child: const Text('Login',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUp()));
                      },
                      child: const Text(
                        "Don't have an account? Sign up!",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
