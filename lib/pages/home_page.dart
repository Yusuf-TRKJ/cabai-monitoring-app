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
                child: CircularProgressIndicator(color: neonBlue),
              );
            }

            final data = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map);

            final sensor = Map<String, dynamic>.from(data['sensor'] ?? {});
            final control = Map<String, dynamic>.from(data['control'] ?? {});
            final history = Map<String, dynamic>.from(data['history'] ?? {});

            final soil = (sensor['soil'] ?? 0).toDouble();
            final temp = (sensor['suhu'] ?? 0).toDouble();
            final pressure = (sensor['tekanan'] ?? 0).toDouble();

            final mode = control['mode'] ?? "MANUAL";
            final pompa = control['pompa'] ?? "OFF";

            return Center(
              child: Container(
                width: 400,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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

                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Smart Farm",
                                  style: TextStyle(
                                      color: neonBlue,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text(_getDate(),
                                  style:
                                      const TextStyle(color: Colors.white60)),
                              Text(_getTime(),
                                  style: TextStyle(color: neonBlue)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.logout, color: neonBlue),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => LoginPage()),
                                  );
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProfilePage()),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.white12,
                                  child:
                                      Icon(Icons.person, color: neonBlue),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      // GRAPH (UPGRADE)
                      _chartCard("Soil Moisture",
                          getChartData(history, "soil"), soil),
                      const SizedBox(height: 15),
                      _chartCard("Temperature (°C)",
                          getChartData(history, "suhu"), temp),
                      const SizedBox(height: 15),
                      _chartCard("Pressure (hPa)",
                          getChartData(history, "tekanan"), pressure),

                      const SizedBox(height: 20),

                      // DATA
                      Row(
                        children: [
                          Expanded(child: _mini("Soil", "${soil.toInt()}")),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _mini("Temp",
                                  "${temp.toStringAsFixed(1)}°C")),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                              child: _mini("Pressure",
                                  "${pressure.toStringAsFixed(1)} hPa")),
                          const SizedBox(width: 10),
                          Expanded(child: _mini("Pompa", pompa)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(child: _mini("Mode", mode)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // CONTROL
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
                          const SizedBox(height: 10),
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

  // STATUS
  String getStatus(String title, double v) {
    if (title.contains("Soil")) {
      if (v > 3000) return "Kering";
      if (v > 1500) return "Lembab";
      return "Basah";
    } else if (title.contains("Temperature")) {
      if (v > 32) return "Panas";
      if (v < 25) return "Dingin";
      return "Normal";
    } else {
      if (v > 1010) return "Tinggi";
      if (v < 1000) return "Rendah";
      return "Stabil";
    }
  }

  // HISTORY
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

    if (spots.length > 20) {
      spots = spots.sublist(spots.length - 20);
    }

    return spots;
  }

  // CHART PROFESSIONAL
  Widget _chartCard(String title, List<FlSpot> spots, double value) {
    Color lineColor = neonBlue;

    if (title.contains("Temperature")) {
      lineColor = Colors.orange;
    } else if (title.contains("Pressure")) {
      lineColor = Colors.green;
    }

    final status = getStatus(title, value);

    return Container(
      height: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: neonBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: neonBlue)),

          // 🔥 NILAI BESAR
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),

          Text("Status: $status",
              style: const TextStyle(color: Colors.white60)),

          const SizedBox(height: 10),

          Expanded(
            child: spots.isEmpty
                ? const Center(
                    child: Text("No Data",
                        style: TextStyle(color: Colors.white38)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white10,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.white10,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: lineColor,
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

  Widget _mini(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: neonBlue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          Text(value, style: TextStyle(color: neonBlue)),
        ],
      ),
    );
  }

  Widget _btn(String text, bool active, bool isOn, VoidCallback onTap) {
    Color color;

    if (active) {
      color = isOn ? Colors.green : Colors.red;
    } else {
      color = Colors.grey.shade800;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text, // 🔥 FIX BUG
          style: const TextStyle(
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