import 'package:flutter/material.dart';
import 'package:scrapuncle_warehouse/pages/home.dart';
import 'package:scrapuncle_warehouse/pages/pickup.dart'; //Import PickupPage
import 'package:scrapuncle_warehouse/pages/profile.dart'; //Import Profile page

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key}) : super(key: key);

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  // Define the pages to be displayed in the BottomNavigationBar
  static List<Widget> _widgetOptions = <Widget>[
    const HomePage(), // Home Page
    const PickupPage(), // Pickup Page
    // const Profile(), // Profile Page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping), //Changed to a shipping icon
            label: 'Pickup',
            backgroundColor: Colors.green,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person),
          //   label: 'Profile',
          //   backgroundColor: Colors.green,
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
