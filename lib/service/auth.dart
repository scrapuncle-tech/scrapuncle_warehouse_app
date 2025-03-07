import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/login.dart';
import 'package:scrapuncle_warehouse/service/shared_pref.dart'; // Import for Shared Preferences

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> SignOut(BuildContext context) async {
    // Pass context
    try {
      await auth.signOut();
      // Clear shared preferences
      await SharedPreferenceHelper().saveUserId("");
      await SharedPreferenceHelper().saveUserName("");
      await SharedPreferenceHelper().saveUserPhoneNumber("");
      await SharedPreferenceHelper().saveUserEmail("");
      await SharedPreferenceHelper().saveUserProfile("");

      // Navigate to Login screen (replace current route)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      print("Error signing out: $e");
      // Handle the error (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error signing out: $e"),
        ),
      );
    }
  }

  Future<void> deleteUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        print("User deleted successfully!");
      } else {
        print("No user currently signed in.");
        print("No user currently signed in.");
      }
    } catch (e) {
      print("Error deleting user: $e");
    }
  }
}
