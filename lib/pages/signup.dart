import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/login.dart'; // Navigate to Login after signup
import 'package:scrapuncle_warehouse/service/database.dart'; // Import DatabaseMethods
import 'package:scrapuncle_warehouse/service/shared_pref.dart'; // Import SharedPreferenceHelper
import 'package:random_string/random_string.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "", phoneNumber = "";
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController retypePasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  registration() async {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text != retypePasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Passwords do not match"),
        ));
        return;
      }
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        String Id = randomAlphaNumeric(10);
        Map<String, dynamic> addSupervisorInfo = {
          'Name': nameController.text,
          'PhoneNumber': phoneController.text,
          'Email': emailController.text,
          'id': Id,
        };

        await DatabaseMethods().addUserDetail(addSupervisorInfo, Id);

        // Optionally save supervisor info to Shared Preferences (if needed)
        await SharedPreferenceHelper().saveUserName(nameController.text);
        await SharedPreferenceHelper()
            .saveUserPhoneNumber(phoneController.text);
        await SharedPreferenceHelper().saveUserEmail(emailController.text);
        await SharedPreferenceHelper().saveUserId(Id);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Registered Successfully. Please Login.",
            style: TextStyle(fontSize: 20),
          ),
        ));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = "An error occurred";
        if (e.code == 'weak-password') {
          errorMessage = "Password Provided is too Weak";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "Account Already exists";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            errorMessage,
            style: const TextStyle(fontSize: 18),
          ),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("An unexpected error occurred: $e"),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supervisor Sign Up"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child:
                  Image.asset('images/ScrapUncle.png', height: 200, width: 300),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter Name";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter Phone Number";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter Email";
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
                    controller: passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter Password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: retypePasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Re-enter Password";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Re-type Password',
                      hintText: 'Re-enter your password',
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
                          name = nameController.text;
                          phoneNumber = phoneController.text;
                          email = emailController.text;
                          password = passwordController.text;
                        });
                        registration();
                      }
                    },
                    child: const Text('Sign Up',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()));
                    },
                    child: const Text(
                      "Already have an account? Login!",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
