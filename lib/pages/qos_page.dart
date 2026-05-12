import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class QoSPage extends StatelessWidget {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();

  final Color neonBlue = const Color(0xFF4DA6FF);
  final Color bgBlack = const Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("QoS Monitoring"),
        centerTitle: true,
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text("No Data",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map);

          final sensor =
              Map<String, dynamic>.from(data['sensor'] ?? {});
          final history =
              Map<String, dynamic>.from(data['history'] ?? {});

          /// =========================
          /// 🔥 DELAY (AMAN)
          /// =========================
          final ts = sensor['timestamp'] ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          double delay = (ts == 0) ? 0 : (now - ts).toDouble();

          /// =========================
          /// 🔥 PACKET LOSS (FIX ERROR NEGATIF)
          /// =========================
          int totalData = history.length;
          double expected = 6; // asumsi 10 detik

          double loss = 0;

          if (totalData <= expected) {
            loss = ((expected - totalData) / expected) * 100;
          } else {
            loss = 0;
          }

          loss = loss.clamp(0, 100);

          /// =========================
          /// 🔥 STATUS + WARNA
          /// =========================
          String delayStatus;
          Color delayColor;

          if (delay == 0) {
            delayStatus = "Menunggu Data";
            delayColor = Colors.grey;
          } else if (delay < 5) {
            delayStatus = "Sangat Baik";
            delayColor = Colors.green;
          } else if (delay < 10) {
            delayStatus = "Baik";
            delayColor = Colors.orange;
          } else {
            delayStatus = "Buruk";
            delayColor = Colors.red;
          }

          String lossStatus;
          Color lossColor;

          if (loss == 0) {
            lossStatus = "Sangat Baik";
            lossColor = Colors.green;
          } else if (loss < 10) {
            lossStatus = "Baik";
            lossColor = Colors.orange;
          } else {
            lossStatus = "Buruk";
            lossColor = Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                /// 🔥 DELAY CARD
                _card(
                  "Delay",
                  "${delay.toStringAsFixed(1)} s",
                  delayStatus,
                  delayColor,
                  Icons.speed,
                ),

                const SizedBox(height: 20),

                /// 🔥 PACKET LOSS CARD
                _card(
                  "Packet Loss",
                  "${loss.toStringAsFixed(1)} %",
                  lossStatus,
                  lossColor,
                  Icons.network_check,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔥 CARD UPGRADE (TIDAK POLOS)
  Widget _card(String title, String value, String status,
      Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [

          /// TITLE + ICON
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(color: color, fontSize: 18)),
            ],
          ),

          const SizedBox(height: 15),

          /// VALUE
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          /// STATUS
          Text(
            status,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// PROGRESS BAR (BIAR GA POLOS)
          LinearProgressIndicator(
            value: 0.7,
            color: color,
            backgroundColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}