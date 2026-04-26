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
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(
                  child: CircularProgressIndicator(color: neonBlue));
            }

            final data =
                Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

            final sensor = Map<String, dynamic>.from(data['sensor'] ?? {});
            final control = Map<String, dynamic>.from(data['control'] ?? {});
            final history = Map<String, dynamic>.from(data['history'] ?? {});

            // 🔥 FIX KEY SESUAI FIREBASE
            final soil = (sensor['soil'] ?? 0).toDouble();
            final temp = (sensor['suhu'] ?? 0).toDouble();
            final pressure = (sensor['tekanan'] ?? 0).toDouble();

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

                      // 🔥 GRAPH REALTIME
                      _chartCard("Soil Moisture", getChartData(history, "soil")),
                      SizedBox(height: 15),
                      _chartCard("Temperature (°C)", getChartData(history, "suhu")),
                      SizedBox(height: 15),
                      _chartCard("Pressure (hPa)", getChartData(history, "tekanan")),

                      SizedBox(height: 20),

                      // 🔥 DATA
                      Row(
                        children: [
                          Expanded(child: _mini("Soil", "${soil.toInt()}")),
                          SizedBox(width: 10),
                          Expanded(child: _mini("Temp", "${temp.toStringAsFixed(1)}°C")),
                        ],
                      ),

                      SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(child: _mini("Pressure", "${pressure.toStringAsFixed(1)} hPa")),
                          SizedBox(width: 10),
                          Expanded(child: _mini("Pompa", pompa)),
                        ],
                      ),

                      SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(child: _mini("Mode", mode)),
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

  // 🔥 AMBIL DATA HISTORY
  List<FlSpot> getChartData(Map history, String key) {
    List<FlSpot> spots = [];
    int index = 0;

    history.forEach((k, v) {
      if (v[key] != null) {
        double value = (v[key] as num).toDouble();
        spots.add(FlSpot(index.toDouble(), value));
        index++;
      }
    });

    return spots;
  }

  // 🔥 CHART REALTIME
  Widget _chartCard(String title, List<FlSpot> spots) {
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
          Text(title, style: TextStyle(color: neonBlue)),
          SizedBox(height: 10),
          Expanded(
            child: spots.isEmpty
                ? Center(
                    child: Text("No Data",
                        style: TextStyle(color: Colors.white38)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: neonBlue,
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
          Text(title, style: TextStyle(color: Colors.white60)),
          Text(value, style: TextStyle(color: neonBlue)),
        ],
      ),
    );
  }

  // 🔥 BUTTON
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