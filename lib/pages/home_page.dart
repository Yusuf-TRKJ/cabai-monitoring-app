import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final firebaseService = FirebaseService();

  final Color neonBlue = const Color(0xFF4DA6FF);
  final Color bgBlack = const Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,

      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: firebaseService.getAllData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(color: neonBlue));
            }

            final data = snapshot.data!.snapshot.value as Map;

            final sensor = data['sensor'] ?? {};
            final control = data['control'] ?? {};

            final soil = sensor['soil'] ?? 0;
            final humid = sensor['kelembapan'] ?? 0;
            final mode = control['mode'] ?? "MANUAL";
            final pompa = control['pompa'] ?? "OFF";

            return Center(
              child: Container(
                width: 400,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: neonBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: neonBlue.withOpacity(0.6),
                      blurRadius: 30,
                    )
                  ],
                ),

                child: SingleChildScrollView(
                  child: Column(
                    children: [

                      // 🔥 HEADER
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Smart Farm",
                                  style: TextStyle(
                                      color: neonBlue,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text(_getDate(),
                                  style:
                                      TextStyle(color: Colors.white60)),
                              Text(_getTime(),
                                  style: TextStyle(color: neonBlue)),
                            ],
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.logout,
                                    color: neonBlue),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            LoginPage()),
                                  );
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ProfilePage()),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundColor:
                                      Colors.white12,
                                  child: Icon(Icons.person,
                                      color: neonBlue),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),

                      SizedBox(height: 20),

                      // 🔥 GRAPH SOIL
                      _chartCard("Soil", soil.toDouble()),

                      SizedBox(height: 15),

                      // 🔥 GRAPH HUMID
                      _chartCard("Humidity", humid.toDouble()),

                      SizedBox(height: 20),

                      // 🔥 DATA
                      Row(
                        children: [
                          Expanded(child: _mini("Soil", "$soil")),
                          SizedBox(width: 10),
                          Expanded(child: _mini("Humid", "$humid%")),
                        ],
                      ),

                      SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(child: _mini("Mode", mode)),
                          SizedBox(width: 10),
                          Expanded(child: _mini("Pompa", pompa)),
                        ],
                      ),

                      SizedBox(height: 20),

                      // 🔥 CONTROL
                      Column(
                        children: [
                          Switch(
                            value: mode == "AUTO",
                            activeColor: neonBlue,
                            onChanged: (value) {
                              firebaseService.setMode(
                                  value ? "AUTO" : "MANUAL");
                            },
                          ),

                          SizedBox(height: 10),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _btn("ON", pompa == "ON", true, () {
                                firebaseService.setPompa("ON");
                              }),
                              _btn("OFF", pompa == "OFF", false, () {
                                firebaseService.setPompa("OFF");
                              }),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 🔥 CHART (GARIS HITAM)
  Widget _chartCard(String title, double value) {
    return Container(
      height: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: neonBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: neonBlue)),
          SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, value),
                      FlSpot(1, value),
                    ],
                    isCurved: true,
                    color: Colors.black, // 🔥 INI PERUBAHAN
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 MINI INFO
  Widget _mini(String title, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: neonBlue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(color: Colors.white60)),
          Text(value,
              style: TextStyle(color: neonBlue)),
        ],
      ),
    );
  }

  // 🔥 BUTTON BARU (NO GLOW)
  Widget _btn(String text, bool active, bool isOn, VoidCallback onTap) {
    Color color;

    if (active) {
      color = isOn ? Colors.green : Colors.red;
    } else {
      color = Colors.grey[800]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  String _getDate() {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }
}