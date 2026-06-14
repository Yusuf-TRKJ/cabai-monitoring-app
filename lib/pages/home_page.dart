import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../services/firebase_service.dart';
import 'profile_page.dart';
import 'qos_page.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final firebaseService = FirebaseService();
  MqttServerClient? mqttClient;

  // ------------------------------------------------------------------------
  // STATE VARIABLE UNTUK DATA REAL-TIME (Dikelola Instan oleh MQTT)
  // ------------------------------------------------------------------------
  double currentSoil = 0;
  double currentTemp = 0;
  double currentHumidity = 0;
  String currentPumpStatus = "OFF";
  String currentSystemMode = "AUTO"; // Menyimpan mode kebun saat ini
  String lastUpdateString = "-";
  bool isMqttConnected = false;

  // ------------------------------------------------------------------------
  // PALET WARNA (Sesuai Presisi Gambar Berwarna Gelap Neon)
  // ------------------------------------------------------------------------
  final Color bgColor = const Color(0xFF051109);       // Hijau gelap latar belakang
  final Color appBarColor = const Color(0xFF030A05);   // Lebih gelap untuk App Bar
  final Color cardColor = const Color(0xFF0A1F13);     // Hijau card utama
  final Color itemBgColor = const Color(0xFF0D2818);   // Latar status item kecil di bawah
  
  // Warna Aksent & Status Sensor Default
  final Color soilColor = const Color(0xFFF0A93B);     // Oranye/Kuning Emas
  final Color tempColor = const Color(0xFFE54A4A);     // Merah Ringan
  final Color humidityColor = const Color(0xFF3B8AF0); // Biru Muda
  final Color normalGreen = const Color(0xFF39B54A);   // Hijau Status Sukses

  @override
  void initState() {
    super.initState();
    lastUpdateString = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    _initMqtt();
  }

  @override
  void dispose() {
    mqttClient?.disconnect();
    super.dispose();
  }

  // ------------------------------------------------------------------------
  // FUNGSI KIRIM PERINTAH TOMBOL KE HIVEMQ BROKER
  // ------------------------------------------------------------------------
  void _kirimPerintahMqtt(String perintah) {
    if (mqttClient != null && mqttClient!.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(perintah); 

      mqttClient!.publishMessage(
        'smartchili/kebun/kontrol',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      debugPrint('====== [MQTT OUT] Sukses Kirim Perintah: $perintah ======');
    } else {
      debugPrint('====== [MQTT ERROR] Gagal Kirim, MQTT Tidak Konek! ======');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi broker terputus, gagal mengirim perintah!')),
      );
    }
  }

  // ------------------------------------------------------------------------
  // FUNGSI UTAMA KONEKSI MQTT HIVEMQ CLOUD
  // ------------------------------------------------------------------------
  Future<void> _initMqtt() async {
    mqttClient = MqttServerClient.withPort(
        'f1294383812847e2acb1f7e3cca33804.s1.eu.hivemq.cloud', 
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}', 
        8883
    );

    mqttClient!.secure = true;
    mqttClient!.securityContext = SecurityContext.defaultContext;
    mqttClient!.keepAlivePeriod = 20;
    mqttClient!.logging(on: false);

    mqttClient!.onDisconnected = () {
      if (mounted) {
        setState(() { isMqttConnected = false; });
      }
      debugPrint('====== MQTT TERPUTUS, MENCOBA REKONEKSI... ======');
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && mqttClient != null) {
          _initMqtt();
        }
      });
    };

    mqttClient!.onConnected = () {
      if (mounted) {
        setState(() { isMqttConnected = true; });
      }
      debugPrint('====== MQTT SUKSES TERKONEKSI KE HIVEMQ BROKER! ======');
      mqttClient!.subscribe('smartchili/kebun/sensor', MqttQos.atMostOnce);
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .authenticateAs('chili_receiver', 'Yusuf123') 
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    
    mqttClient!.connectionMessage = connMessage;

    try {
      await mqttClient!.connect();
    } catch (e) {
      debugPrint('Error MQTT Connection: $e');
      mqttClient?.disconnect(); 
    }

    mqttClient!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      debugPrint('====== [MQTT INCOMING]: $payload ======');

      try {
        final Map<String, dynamic> json = jsonDecode(payload);
        
        if (mounted) {
          setState(() {
            currentSoil = (json['soil'] ?? 0).toDouble();
            currentTemp = (json['suhu'] ?? 0).toDouble();
            currentHumidity = (json['humidity'] ?? 0).toDouble();
            currentPumpStatus = (json['pompa'] ?? "OFF").toString().toUpperCase();
            currentSystemMode = (json['mode'] ?? "AUTO").toString().toUpperCase(); 
            lastUpdateString = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
          });
        }
      } catch (e) {
        debugPrint('Gagal Parsing JSON MQTT: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------------------
    // LOGIKA WARNA DINAMIS (GRAFIK + ANGKA + STATUS IKUT BERUBAH)
    // ------------------------------------------------------------------------
    
    // 1. Dinamisasi Warna Grafik & Angka Soil Sensor
    String soilStatus = currentSoil < 2200 ? "BASAH" : (currentSoil <= 3200 ? "NORMAL" : "KERING");
    Color dynamicSoilColor;
    if (soilStatus == "KERING") {
      dynamicSoilColor = tempColor;     // Merah jika Kering
    } else if (soilStatus == "NORMAL") {
      dynamicSoilColor = soilColor;     // Oranye jika Normal
    } else {
      dynamicSoilColor = normalGreen;   // Hijau jika Basah
    }

    // 2. Dinamisasi Warna Grafik & Angka Temperature Sensor
    String tempStatus = currentTemp > 32 ? "PANAS" : (currentTemp >= 24 ? "NORMAL" : "DINGIN");
    Color dynamicTempColor;
    if (tempStatus == "PANAS") {
      dynamicTempColor = tempColor;        // Merah jika Panas
    } else if (tempStatus == "NORMAL") {
      dynamicTempColor = normalGreen;      // Hijau jika Normal
    } else {
      dynamicTempColor = humidityColor;    // Biru jika Dingin
    }

    // 3. Dinamisasi Warna Humidity (Tetap Pas Semula)
    String humidityStatus = "NORMAL";
    Color dynamicHumidityColor = normalGreen;

    Color pumpColor = currentPumpStatus == "ON" ? normalGreen : Colors.white.withOpacity(0.3);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('history').onValue, 
                builder: (context, snapshot) {
                  List<FlSpot> soilSpots = [];
                  List<FlSpot> tempSpots = [];
                  List<FlSpot> humiditySpots = [];
                  List<Map<String, dynamic>> finalSortedHistory = [];

                  if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                    try {
                      final historyData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                      
                      finalSortedHistory = getSortedHistoryList(historyData);

                      soilSpots = getChartSpots(finalSortedHistory, "soil");
                      tempSpots = getChartSpots(finalSortedHistory, "suhu");
                      humiditySpots = getChartSpots(finalSortedHistory, "humidity");
                    } catch (e) {
                      debugPrint("Gagal memuat chart history: $e");
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      children: [
                        /// --- KARTU SOIL SENSOR ---
                        _buildSensorCard(
                          title: "Soil Sensor",
                          subtitle: "Kelembaban Tanah",
                          value: currentSoil,
                          unit: "ADC",
                          status: soilStatus,
                          statusColor: dynamicSoilColor, // Mengikuti warna dinamis
                          chartColor: dynamicSoilColor,  // SEKARANG GARIS GRAFIK & ANGKA IKUT DINAMIS!
                          icon: Icons.eco,
                          minY: 0,
                          maxY: 4095,
                          horizontalInterval: 1024,
                          spots: soilSpots,
                          historyList: finalSortedHistory,
                        ),
                        const SizedBox(height: 14),

                        /// --- KARTU TEMPERATURE ---
                        _buildSensorCard(
                          title: "Temperature",
                          subtitle: "Suhu Udara",
                          value: currentTemp,
                          unit: "°C",
                          status: tempStatus,
                          statusColor: dynamicTempColor, // Mengikuti warna dinamis
                          chartColor: dynamicTempColor,  // SEKARANG GARIS GRAFIK & ANGKA IKUT DINAMIS!
                          icon: Icons.thermostat,
                          minY: 0,
                          maxY: 50,
                          horizontalInterval: 12.5,
                          spots: tempSpots,
                          historyList: finalSortedHistory,
                        ),
                        const SizedBox(height: 14),

                        /// --- KARTU HUMIDITY ---
                        _buildSensorCard(
                          title: "Humidity",
                          subtitle: "Kelembaban Udara",
                          value: currentHumidity,
                          unit: "%",
                          status: humidityStatus,
                          statusColor: dynamicHumidityColor,
                          chartColor: humidityColor, // Sesuai warna dasarnya (Biru)
                          icon: Icons.water_drop,
                          minY: 0,
                          maxY: 100,
                          horizontalInterval: 25,
                          spots: humiditySpots,
                          historyList: finalSortedHistory,
                        ),
                        const SizedBox(height: 14),

                        /// --- KARTU SYSTEM STATUS ---
                        _buildSystemStatusCard(
                          soilStatus: soilStatus,
                          soilColor: dynamicSoilColor,
                          tempStatus: tempStatus,
                          tempColor: dynamicTempColor,
                          pumpStatus: currentPumpStatus,
                          pumpColor: pumpColor,
                        ),
                        const SizedBox(height: 14),

                        /// --- KARTU REMOTE KONTROL DUAL MODE ---
                        _buildRemoteControlCard(),
                        const SizedBox(height: 12),

                        /// --- FOOTER ---
                        _buildFooter(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= WIDGET REMOTE CONTROL CARD =================
  Widget _buildRemoteControlCard() {
    bool isModeAuto = (currentSystemMode == "AUTO");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SYSTEM REMOTE CONTROL", 
            style: TextStyle(color: normalGreen.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
          const SizedBox(height: 4),
          Text(
            "Mode aktif saat ini: $currentSystemMode Mode",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          const SizedBox(height: 14),

          if (isModeAuto) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: itemBgColor,
                  foregroundColor: soilColor,
                  side: BorderSide(color: soilColor.withOpacity(0.4), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.tune, size: 16),
                onPressed: () => _kirimPerintahMqtt("OFF"), 
                label: const Text("PINDAH KE MODE MANUAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ],

          if (!isModeAuto) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentSystemMode == "ON" ? humidityColor : itemBgColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    onPressed: () => _kirimPerintahMqtt("ON"),
                    label: const Text("MANUAL ON", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentSystemMode == "OFF" ? tempColor : itemBgColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.stop, size: 16),
                    onPressed: () => _kirimPerintahMqtt("OFF"),
                    label: const Text("MANUAL OFF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: normalGreen,
                  side: BorderSide(color: normalGreen.withOpacity(0.5), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.brightness_auto, size: 16),
                onPressed: () => _kirimPerintahMqtt("AUTO"),
                label: const Text("KEMBALI KE MODE OTOMATIS (AUTO)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ================= WIDGET CUSTOM APP BAR =================
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: appBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.menu, color: Colors.white, size: 26),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SMART CHILI",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMqttConnected ? "Live via MQTT Broker" : "Menghubungkan MQTT...",
                    style: TextStyle(
                      color: isMqttConnected ? normalGreen : Colors.amber.withOpacity(0.7), 
                      fontSize: 12,
                      fontWeight: isMqttConnected ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.history, color: Colors.white, size: 24),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
              ),
              const SizedBox(width: 18),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QoSPage())),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ================= WIDGET SENSOR CARD (FIX JAM REAL-TIME) =================
  Widget _buildSensorCard({
    required String title,
    required String subtitle,
    required double value,
    required String unit,
    required String status,
    required Color statusColor,
    required Color chartColor,
    required IconData icon,
    required double minY,
    required double maxY,
    required double horizontalInterval,
    required List<FlSpot> spots,
    required List<Map<String, dynamic>> historyList,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value.toStringAsFixed(title == "Soil Sensor" ? 0 : 1),
                        style: TextStyle(color: chartColor, fontSize: 24, fontWeight: FontWeight.bold, height: 1),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // AREA LINE CHART (FL CHART)
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.isEmpty ? 5 : spots.length.toDouble() - 1,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: horizontalInterval,
                  verticalInterval: 1, 
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.06),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.06),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        String label = title == "Temperature" ? value.toStringAsFixed(1) : value.toInt().toString();
                        if (title == "Temperature" && value == 25.0) label = "25";
                        return Text(
                          label,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1, 
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < historyList.length) {
                          int ts = historyList[index]['timestamp'] ?? 0;
                          if (ts != 0) {
                            DateTime date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                            String timeStr = DateFormat('HH:mm').format(date);
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timeStr, 
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true, 
                    color: chartColor, // MEWARNAI GARIS GRAFIK SECARA DINAMIS
                    barWidth: 2.0,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => true, 
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3, 
                          color: bgColor, 
                          strokeWidth: 2, 
                          strokeColor: chartColor // TITIK SIMPUL JUGA DINAMIS
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartColor.withOpacity(0.18), // GRADIENT BAWAH GRAFIK JUGA IKUT DINAMIS
                          chartColor.withOpacity(0.0)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 2, color: chartColor),
              const SizedBox(width: 8),
              Text("$title ($unit)", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  /// ================= WIDGET SYSTEM STATUS =================
  Widget _buildSystemStatusCard({
    required String soilStatus, required Color soilColor,
    required String tempStatus, required Color tempColor,
    required String pumpStatus, required Color pumpColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SYSTEM STATUS", 
            style: TextStyle(color: normalGreen.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statusItem(Icons.eco, "SOIL", soilStatus, soilColor)),
              const SizedBox(width: 10),
              Expanded(child: _statusItem(Icons.thermostat, "TEMP", tempStatus, tempColor)),
              const SizedBox(width: 10),
              Expanded(child: _statusItem(Icons.water_drop, "PUMP", pumpStatus, pumpColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.35), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= WIDGET FOOTER APP =================
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, color: Colors.white.withOpacity(0.35), size: 13),
          const SizedBox(width: 4),
          Text("Last Update: $lastUpdateString", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
          const SizedBox(width: 12),
          Container(width: 1, height: 10, color: Colors.white.withOpacity(0.15)),
          const SizedBox(width: 12),
          Container(
            width: 6, 
            height: 6, 
            decoration: BoxDecoration(
              color: isMqttConnected ? normalGreen : Colors.orange, 
              shape: BoxShape.circle
            )
          ),
          const SizedBox(width: 6),
          Text(
            isMqttConnected ? "Online (MQTT)" : "Offline", 
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)
          ),
        ],
      ),
    );
  }

  /// ================= LOGIKA BARU KUMPULKAN DAN URUTKAN HISTORY DATA =================
  List<Map<String, dynamic>> getSortedHistoryList(Map history) {
    List<Map<String, dynamic>> sortedList = [];
    
    history.forEach((key, value) {
      if (value is Map) {
        sortedList.add(Map<String, dynamic>.from(value));
      }
    });

    sortedList.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

    if (sortedList.length > 7) {
      sortedList = sortedList.sublist(sortedList.length - 7);
    }
    
    return sortedList;
  }

  /// Converted dari List Map terurut ke format FlSpot milik grafik
  List<FlSpot> getChartSpots(List<Map<String, dynamic>> historyList, String fieldKey) {
    List<FlSpot> spots = [];
    for (int i = 0; i < historyList.length; i++) {
      double val = (historyList[i][fieldKey] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }
}