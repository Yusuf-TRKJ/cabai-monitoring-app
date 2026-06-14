import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QoSPage extends StatelessWidget {
  QoSPage({super.key});

  final DatabaseReference ref = FirebaseDatabase.instance.ref();

  // Penyelarasan Palet Warna Tema Gelap (Smart Chili)
  final Color bgColor = const Color(0xFF051109);       
  final Color appBarColor = const Color(0xFF030A05);   
  final Color cardColor = const Color(0xFF0A1F13);     
  final Color itemBgColor = const Color(0xFF0D2818);   
  
  // Aksen Warna Status Jaringan & Sensor
  final Color normalGreen = const Color(0xFF39B54A);   
  final Color soilColor = const Color(0xFFF0A93B);     
  final Color tempColor = const Color(0xFFE54A4A);     
  final Color humidityColor = const Color(0xFF3B8AF0); 
  final Color qosColor = const Color(0xFFA855F7);      

  // === DIALOG KONFIRMASI HAPUS SEMUA LOG ===
  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          title: const Text(
            "Hapus Semua Log", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Text(
            "Apakah Anda yakin ingin menghapus seluruh data riwayat sensor? Tindakan ini tidak dapat dibatalkan.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              child: const Text("Batal", style: TextStyle(color: Colors.white38)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Hapus Semua", 
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                try {
                  await FirebaseDatabase.instance.ref("history").remove();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: cardColor,
                        content: Text(
                          "Semua log riwayat berhasil dibersihkan", 
                          style: TextStyle(color: normalGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF4A151D),
                        content: Text("Gagal menghapus data: $e", style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ─── 🔥 FUNGSI GENERATOR DAN DOWNLOAD PDF ASLI REALTIME ───
  void _exportToPDF(List<Map<String, dynamic>> dataList, double avgSuhu, double avgHum, double avgSoil) async {
    final pdf = pw.Document();

    final primaryHex = PdfColor.fromHex('#39B54A');
    final darkBgHex = PdfColor.fromHex('#051109');
    final cardBgHex = PdfColor.fromHex('#0A1F13');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: darkBgHex),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HEADER LAPORAN
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SMART CHILI IOT REPORT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryHex)),
                        pw.Text("Laporan Riwayat QoS & Data Sensor Kebun Cabai", style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      ],
                    ),
                    pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Divider(color: primaryHex, thickness: 1.5),
                pw.SizedBox(height: 15),

                // CARD RANGKUMAN STATISTIK
                pw.Text("RANGKUMAN STATISTIK RATA-RATA", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryHex)),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfSummaryCard("Avg Soil Moisture", "${avgSoil.toStringAsFixed(0)}%", cardBgHex, PdfColor.fromHex('#F0A93B')),
                    _buildPdfSummaryCard("Avg Suhu Udara", "${avgSuhu.toStringAsFixed(1)}°C", cardBgHex, PdfColor.fromHex('#E54A4A')),
                    _buildPdfSummaryCard("Avg Kelembapan", "${avgHum.toStringAsFixed(0)}%", cardBgHex, PdfColor.fromHex('#3B8AF0')),
                  ],
                ),
                pw.SizedBox(height: 20),

                // TABEL DATA LOG
                pw.Text("LOG RIWAYAT SENSOR TERBARU (MAX 25 RECORD)", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryHex)),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#143d25'), width: 0.8),
                  children: [
                    // Heading Tabel
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: cardBgHex),
                      children: [
                        _buildPdfCell("Waktu Log", isHeader: true, color: primaryHex),
                        _buildPdfCell("Soil", isHeader: true, color: PdfColor.fromHex('#F0A93B')),
                        _buildPdfCell("Suhu", isHeader: true, color: PdfColor.fromHex('#E54A4A')),
                        _buildPdfCell("Humidity", isHeader: true, color: PdfColor.fromHex('#3B8AF0')),
                        _buildPdfCell("Status Sinyal", isHeader: true, color: PdfColor.fromHex('#FFA855F7')),
                      ],
                    ),
                    // Isi Baris Data
                    ...dataList.take(25).map((Map<String, dynamic> log) {
                      int ts = log['timestamp'] ?? 0;
                      String timeStr = ts != 0 
                          ? DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts * 1000))
                          : "-";
                      return pw.TableRow(
                        children: [
                          _buildPdfCell(timeStr),
                          _buildPdfCell("${(log['soil'] ?? 0).toStringAsFixed(0)}%"),
                          _buildPdfCell("${(log['suhu'] ?? 0).toStringAsFixed(1)}°C"),
                          _buildPdfCell("${(log['humidity'] ?? 0).toStringAsFixed(0)}%"),
                          _buildPdfCell("QoS ${log['qos'] ?? 1}"),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Membuka jendela download/cetak PDF bawaan OS HP
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Smart_Chili_${DateFormat('ddMMyy_HHmm').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildPdfSummaryCard(String label, String val, PdfColor bg, PdfColor valColor) {
    return pw.Container(
      width: 170,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
          pw.SizedBox(height: 3),
          pw.Text(val, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "QoS Monitoring & Logs",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: CircularProgressIndicator(color: normalGreen),
            );
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final sensor = Map<String, dynamic>.from(data['sensor'] ?? {});
          final history = Map<String, dynamic>.from(data['history'] ?? {});

          final int rssi = sensor['rssi'] ?? 0;
          final double snr = (sensor['snr'] ?? 0).toDouble();
          final ts = sensor['timestamp'] ?? 0;

          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          double delay = (ts == 0) ? 0 : (now - ts).toDouble();
          if (delay > 50000 || delay < 0) delay = 0; 

          int totalData = history.length;
          double expected = 6.0;
          double loss = 0.0;

          if (totalData <= expected) {
            loss = ((expected - totalData) / expected) * 100;
          }
          loss = loss.clamp(0.0, 100.0).toDouble();

          final statusAlat = Map<String, dynamic>.from(data['status_alat'] ?? {});
          String statusPengirim = statusAlat['pengirim'] ?? 'offline';
          String statusPenerima = statusAlat['penerima'] ?? 'offline';
          // ignore: unused_local_variable
          int tsPenerima = statusAlat['timestamp_penerima'] ?? 0; 

          bool isOnline = (statusPengirim == "online") && (statusPenerima == "online") && (delay < 180);

          String delayStatus = "Offline";
          Color delayColor = tempColor;
          
          if (isOnline) {
            if (delay >= 0 && delay < 15) {
              delayStatus = "Sangat Baik";
              delayColor = normalGreen;
            } else if (delay >= 15 && delay < 45) {
              delayStatus = "Baik";
              delayColor = Colors.orange;
            } else {
              delayStatus = "Buruk";
              delayColor = tempColor;
            }
          }

          String lossStatus = "Buruk (No Data)";
          Color lossColor = tempColor;
          
          if (totalData > 0) {
            if (loss == 0) {
              lossStatus = "Sangat Baik";
              lossColor = normalGreen;
            } else if (loss > 0 && loss < 20) {
              lossStatus = "Baik";
              lossColor = Colors.orange;
            } else {
              lossStatus = "Buruk";
              lossColor = tempColor;
            }
          }

          Color rssiColor = (isOnline && rssi > -90) ? normalGreen : Colors.orange;
          Color snrColor = (isOnline && snr > 5) ? normalGreen : Colors.orange;

          // ─── PROSES EKSTRAKSI DATA & LOGIKA REKAP RATA-RATA ───
          double totalSuhu = 0;
          double totalHum = 0;
          double totalSoil = 0;

          List<Map<String, dynamic>> historyList = [];
          history.forEach((key, value) {
            if (value is Map) {
              double suhu = (value['suhu'] ?? 0.0).toDouble();
              double hum = (value['humidity'] ?? 0.0).toDouble();
              double soil = (value['soil'] ?? 0.0).toDouble();

              totalSuhu += suhu;
              totalHum += hum;
              totalSoil += soil;

              historyList.add(Map<String, dynamic>.from(value));
            }
          });
          
          historyList.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

          // Hasil Kalkulasi Ringkasan Data Rata-rata
          double avgSuhu = totalData > 0 ? totalSuhu / totalData : 0.0;
          double avgHum = totalData > 0 ? totalHum / totalData : 0.0;
          double avgSoil = totalData > 0 ? totalSoil / totalData : 0.0;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. BANNER UTAMA STATUS SISTEM ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOnline ? cardColor : const Color(0xFF4A151D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isOnline ? normalGreen.withOpacity(0.3) : tempColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOnline ? Icons.check_circle : Icons.error_outline,
                              color: isOnline ? normalGreen : tempColor,
                              size: 35,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnline ? "SISTEM ONLINE" : "SISTEM OFFLINE",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    isOnline 
                                        ? "Seluruh hardware di kebun & rumah aktif normal" 
                                        : "Alat di kebun mati, penerima putus internet, atau lora loss",
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // --- 2. METRIK RESPON ---
                      Text(
                        "METRIK RESPON",
                        style: TextStyle(color: normalGreen.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      _buildMainCard(
                        title: "Delay Terakhir",
                        value: isOnline ? "${delay.toStringAsFixed(1)} detik" : "0.0 detik",
                        status: isOnline ? delayStatus : "Offline",
                        color: isOnline ? delayColor : tempColor,
                        icon: Icons.speed,
                      ),
                      const SizedBox(height: 18),

                      // --- 3. METRIK GRID JARINGAN ---
                      Text(
                        "KUALITAS JARINGAN",
                        style: TextStyle(color: normalGreen.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.5, // 🛠️ Diperlebar agar teks muat sempurna tidak terpotong
                        children: [
                          _buildGridCard(
                            title: "Packet Loss",
                            value: "${loss.toStringAsFixed(1)} %",
                            status: lossStatus,
                            color: lossColor,
                            icon: Icons.network_check,
                          ),
                          _buildGridCard(
                            title: "RSSI Sinyal",
                            value: isOnline ? "$rssi dBm" : "0 dBm",
                            status: isOnline ? (rssi > -90 ? "Baik" : "Lemah") : "Mati",
                            color: isOnline ? rssiColor : tempColor,
                            icon: Icons.network_cell,
                          ),
                          _buildGridCard(
                            title: "SNR Noise",
                            value: isOnline ? "${snr.toStringAsFixed(1)} dB" : "0.0 dB",
                            status: isOnline ? (snr > 5 ? "Stabil" : "Noise") : "Mati",
                            color: isOnline ? snrColor : tempColor,
                            icon: Icons.wifi_tethering,
                          ),
                          _buildGridCard(
                            title: "Total Simpan",
                            value: "$totalData log",
                            status: "Database",
                            color: humidityColor,
                            icon: Icons.storage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ─── 4. CARD SUMMARY RATA-RATA ───
                      Text(
                        "REKAP RATA-RATA DATA SENSOR",
                        style: TextStyle(color: normalGreen.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSummaryMiniCard("Avg Soil", avgSoil.toStringAsFixed(0), Icons.eco, soilColor),
                          _buildSummaryMiniCard("Avg Suhu", "${avgSuhu.toStringAsFixed(1)}°C", Icons.thermostat, tempColor),
                          _buildSummaryMiniCard("Avg Hum", "${avgHum.toStringAsFixed(0)}%", Icons.water_drop, humidityColor),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // --- 5. SEKTOR DAFTAR REKAP TABEL ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TABEL REKAP RIWAYAT (LOGS)",
                                style: TextStyle(color: normalGreen.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$totalData Records Terdeteksi",
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              )
                            ],
                          ),
                          if (historyList.isNotEmpty)
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: normalGreen,
                                    foregroundColor: bgColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    minimumSize: const Size(0, 28)
                                  ),
                                  onPressed: () {
                                    _exportToPDF(historyList, avgSuhu, avgHum, avgSoil);
                                  },
                                  icon: const Icon(Icons.picture_as_pdf, size: 12),
                                  label: const Text("Export PDF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    minimumSize: const Size(0, 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 12),
                                  label: const Text("Clear", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showClearAllDialog(context),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (historyList.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: const Center(
                            child: Text("Tidak ada riwayat log data ditemukan.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ),
                        )
                      ] else ...[
                        // ─── 🛠️ VISUAL TABEL YANG SUDAH MELEBAR PENUH KE KANAN LAYAR ───
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.03), width: 1.5)
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: double.infinity, // <--- Memaksa lebar container mengikuti lebar layar penuh
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.2)),
                                horizontalMargin: 10,
                                columnSpacing: 10, // Jarak antar kolom membagi rata layar secara dinamis
                                headingRowHeight: 40,
                                dataRowHeight: 45,
                                columns: [
                                  DataColumn(label: Expanded(child: Text('Waktu Log', textAlign: TextAlign.center, style: TextStyle(color: normalGreen, fontWeight: FontWeight.bold, fontSize: 11)))),
                                  DataColumn(label: Expanded(child: Text('Soil', textAlign: TextAlign.center, style: TextStyle(color: soilColor, fontWeight: FontWeight.bold, fontSize: 11)))),
                                  DataColumn(label: Expanded(child: Text('Suhu', textAlign: TextAlign.center, style: TextStyle(color: tempColor, fontWeight: FontWeight.bold, fontSize: 11)))),
                                  DataColumn(label: Expanded(child: Text('Hum', textAlign: TextAlign.center, style: TextStyle(color: humidityColor, fontWeight: FontWeight.bold, fontSize: 11)))),
                                  DataColumn(label: Expanded(child: Text('QoS', textAlign: TextAlign.center, style: TextStyle(color: qosColor, fontWeight: FontWeight.bold, fontSize: 11)))),
                                ],
                                rows: historyList.take(20).map((logData) {
                                  int logTs = logData['timestamp'] ?? 0;
                                  String formattedTime = "-";
                                  if (logTs != 0) {
                                    DateTime date = DateTime.fromMillisecondsSinceEpoch(logTs * 1000);
                                    formattedTime = DateFormat('dd/MM HH:mm').format(date);
                                  }

                                  String logSoil = "${(logData['soil'] ?? 0).toStringAsFixed(0)}%";
                                  String logSuhu = "${(logData['suhu'] ?? 0).toStringAsFixed(1)}°C";
                                  String logHumid = "${(logData['humidity'] ?? 0).toStringAsFixed(0)}%";
                                  String logQos = "QoS ${(logData['qos'] ?? 1)}";

                                  return DataRow(cells: [
                                    DataCell(Center(child: Text(formattedTime, style: const TextStyle(color: Colors.white, fontSize: 11)))),
                                    DataCell(Center(child: Text(logSoil, style: TextStyle(color: soilColor.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold)))),
                                    DataCell(Center(child: Text(logSuhu, style: const TextStyle(color: Colors.white70, fontSize: 11)))),
                                    DataCell(Center(child: Text(logHumid, style: const TextStyle(color: Colors.white70, fontSize: 11)))),
                                    DataCell(Center(child: Text(logQos, style: TextStyle(color: qosColor.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold)))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.02))
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard({
    required String title,
    required String value,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: itemBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 1),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.3),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String value,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color.withOpacity(0.6), size: 16),
            ],
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            status,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}