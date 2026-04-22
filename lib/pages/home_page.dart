import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatelessWidget {
  final firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Monitoring Cabai")),

      body: StreamBuilder<DatabaseEvent>(
        stream: firebaseService.getAllData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: Text("Loading..."));
          }

          final data = snapshot.data!.snapshot.value as Map;

          final sensor = data['sensor'];
          final control = data['control'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔥 SENSOR DATA
                Text("Soil: ${sensor['soil']}"),
                Text("Kelembapan: ${sensor['kelembapan']}%"),
                SizedBox(height: 20),

                // 🔥 MODE SWITCH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mode: ${control['mode']}"),
                    Switch(
                      value: control['mode'] == "AUTO",
                      onChanged: (value) {
                        firebaseService
                            .setMode(value ? "AUTO" : "MANUAL");
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // 🔥 POMPA CONTROL
                Text("Pompa: ${control['pompa']}"),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        firebaseService.setPompa("ON");
                      },
                      child: Text("ON"),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        firebaseService.setPompa("OFF");
                      },
                      child: Text("OFF"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}