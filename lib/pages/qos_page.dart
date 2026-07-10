import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class QoSPage extends StatefulWidget {
  const QoSPage({super.key});

  @override
  State<QoSPage> createState() => _QoSPageState();
}

class _QoSPageState extends State<QoSPage> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();

  // ========================================================================
  // PENYELARASAN PALET WARNA PREMIUM DARK CORPORATE (SAMA DENGAN HOME)
  // ========================================================================
  final Color bgColor = const Color(0xFF0F1115);       // Hitam keabuan premium (Slate Dark)
  final Color appBarColor = const Color(0xFF161920);   // Sedikit lebih terang dari bg
  final Color cardColor = const Color(0xFF161920);     // Material Card Matte
  
  // Aksen Warna Status Lembut (Muted / Pastel - Tidak Alay)
  final Color normalGreen = const Color(0xFF34D399);   // Soft Mint Green (Bukan Neon)
  final Color warningOrange = const Color(0xFFFBBF24); // Soft Amber
  final Color dangerRed = const Color(0xFFF87171);     // Soft Muted Red
  final Color humidityColor = const Color(0xFF38BDF8); // Soft Ocean Blue

  // === FUNGSI PENENTU WARNA DINAMIS BERDASARKAN AMBANG BATAS ===
  Color _getSoilColor(double value) {
    if (value <= 2300) return normalGreen; // Basah
    if (value <= 3200) return warningOrange; // Normal
    return dangerRed; // Kering
  }

  Color _getTempColor(double value) {
    if (value >= 25.0 && value <= 32.0) return normalGreen; // Normal
    if (value > 32.0 && value <= 35.0) return warningOrange; // Hangat
    return dangerRed; // Terlalu Dingin / Terlalu Panas
  }

  Color _getHumColor(double value) {
    if (value >= 60.0 && value <= 80.0) return normalGreen; // Normal/Ideal
    return dangerRed; // Terlalu Kering / Terlalu Basah
  }

  // === FUNGSI RESET SEMUA LOG HISTORY ===
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppThemeDialog(
          cardColor: cardColor,
          normalGreen: normalGreen,
          dangerRed: dangerRed,
          ref: ref,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Status Koneksi & Jaringan LoRa",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: CircularProgressIndicator(color: normalGreen));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final sensor = Map<String, dynamic>.from(data['sensor'] ?? {});
          final history = Map<String, dynamic>.from(data['history'] ?? {});

          final int rssi = sensor['rssi'] ?? 0;
          final double snr = (sensor['snr'] ?? 0).toDouble();
          final ts = sensor['timestamp'] ?? 0;

          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          double currentDelay = (ts == 0) ? 0 : (now - ts).toDouble();

          int totalData = history.length;

          final statusAlat = Map<String, dynamic>.from(data['status_alat'] ?? {});
          bool isOnline = (statusAlat['pengirim'] == "online") && (statusAlat['penerima'] == "online") && (currentDelay < 180);

          // PROSES HITUNG RATA-RATA DARI HISTORY
          double totalSuhu = 0, totalHum = 0, totalSoil = 0;
          
          history.forEach((key, value) {
            if (value is Map) {
              totalSuhu += (value['suhu'] ?? 0.0).toDouble();
              totalHum += (value['humidity'] ?? 0.0).toDouble();
              totalSoil += (value['soil'] ?? 0.0).toDouble();
            }
          });
          
          double avgSuhu = totalData > 0 ? totalSuhu / totalData : 0.0;
          double avgHum = totalData > 0 ? totalHum / totalData : 0.0;
          double avgSoil = totalData > 0 ? totalSoil / totalData : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Status Online / Offline Alat
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOnline ? cardColor : const Color(0xFF2D191E), // Soft dark red tint untuk offline
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isOnline ? normalGreen.withOpacity(0.2) : dangerRed.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(isOnline ? Icons.check_circle : Icons.error_outline, color: isOnline ? normalGreen : dangerRed, size: 35),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isOnline ? "SISTEM ONLINE" : "SISTEM OFFLINE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                            Text(isOnline ? "Seluruh hardware di kebun & rumah aktif normal" : "Alat di kebun mati atau lora loss", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Kualitas Jaringan LoRa
                Text("KUALITAS JARINGAN LORA", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4,
                  children: [
                    _buildGridCard("RSSI Sinyal", isOnline ? "$rssi dBm" : "0 dBm", isOnline ? (rssi > -90 ? "Baik" : "Lemah") : "Mati", isOnline ? normalGreen : dangerRed, Icons.network_cell),
                    _buildGridCard("SNR Noise", isOnline ? "${snr.toStringAsFixed(1)} dB" : "0.0 dB", isOnline ? (snr > 5 ? "Stabil" : "Noise") : "Mati", isOnline ? normalGreen : dangerRed, Icons.wifi_tethering),
                    _buildGridCard("Total Data", "$totalData Log", "Database", humidityColor, Icons.storage),
                    
                    // ACTION CARD UNTUK RESET DATA
                    GestureDetector(
                      onLongPress: _showResetDialog,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241418), // Merah maroon elegan sangat gelap
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: dangerRed.withOpacity(0.15))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers_clear_rounded, color: dangerRed, size: 16),
                                const SizedBox(width: 6),
                                const Expanded(child: Text("Sistem Aksi", style: TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text("Reset Log", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text("Tahan Lama", style: TextStyle(color: dangerRed, fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Rekap Nilai Rata-Rata Sensor
                Text("DATA RATA RATA", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSummaryMiniCard("Avg Soil", avgSoil.toStringAsFixed(0), Icons.eco, _getSoilColor(avgSoil)),
                    _buildSummaryMiniCard("Avg Suhu", "${avgSuhu.toStringAsFixed(1)}°C", Icons.thermostat, _getTempColor(avgSuhu)),
                    _buildSummaryMiniCard("Avg Hum", "${avgHum.toStringAsFixed(0)}%", Icons.water_drop, _getHumColor(avgHum)),
                  ],
                ),
                const SizedBox(height: 25),

                // Catatan info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.03))
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Gunakan halaman khusus 'History' untuk melihat log rincian data parameter sensor secara mendetail.",
                          style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER UI ---
  Widget _buildGridCard(String title, String value, String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Widget terpisah untuk Dialog agar menghindari bug context transisi tema gelap
class AppThemeDialog extends StatelessWidget {
  final Color cardColor;
  final Color normalGreen;
  final Color dangerRed;
  final DatabaseReference ref;

  const AppThemeDialog({
    super.key,
    required this.cardColor,
    required this.normalGreen,
    required this.dangerRed,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 22),
            SizedBox(width: 8),
            Text("Konfirmasi Reset", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Apakah abang yakin ingin menghapus seluruh riwayat log data sensor di database?", style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () {
              ref.child("history").remove();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Seluruh log history database berhasil dibersihkan!'),
                  backgroundColor: dangerRed,
                ),
              );
            },
            child: Text("Hapus Semua", style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}