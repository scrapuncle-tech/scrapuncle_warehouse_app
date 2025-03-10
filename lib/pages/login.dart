import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/home.dart';
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
        //First sign in
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        //Get the UID after successful signin
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // After successful authentication, fetch the supervisor document from Firestore
        //Query the database by where the email is the same
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('supervisors')
            .where('Email', isEqualTo: email)
            .get();
        // .doc(FirebaseAuth.instance.currentUser!.uid)
        // .get();

        if (snapshot.docs.isNotEmpty) {
          //Get the doc
          DocumentSnapshot supervisorDoc = snapshot.docs.first;
          print(supervisorDoc['PhoneNumber']);
          print(supervisorDoc['id']);

          //Store both UID and the supervisorId to Shared Preferences
          await SharedPreferenceHelper().saveUserId(uid); //Corrected Line

          await SharedPreferenceHelper()
              .saveSupervisorId(supervisorDoc['id']); //Corrected line
          await SharedPreferenceHelper()
              .saveUserPhoneNumber(supervisorDoc['PhoneNumber']); //Correct line
        } else {
          print("Supervisor document not found!");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                  "Supervisor document not found. Please contact the admin."),
            ));
          }
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
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
