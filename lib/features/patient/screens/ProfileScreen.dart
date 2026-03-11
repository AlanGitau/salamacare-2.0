import 'package:flutter/material.dart';
import 'package:signup/MedicalForm.dart';

//import 'MedicalForm.dart';

class Profilescreen extends StatelessWidget {
  const Profilescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('settings'),
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const Medicalform()),
  );
},

          ),

          const ListTile(
            leading: Icon(Icons.question_mark_rounded),
            title: Text('FAQ'),
          ),

          const ListTile(
            leading: Icon(Icons.logout),
            title: Text('log out',
            style: TextStyle(color: Colors.red),
            ),
          )
        ],
      )
    );
  }
}