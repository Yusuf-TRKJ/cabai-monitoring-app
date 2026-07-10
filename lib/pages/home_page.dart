import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../services/firebase_service.dart';
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
  // STATE VARIABLE UNTUK DATA REAL-TIME
  // ------------------------------------------------------------------------
  double currentSoil = 0;
  double currentTemp = 0;
  double currentHumidity = 0;
  String currentPumpStatus = "OFF";
  String currentSystemMode = "AUTO"; 
  String lastUpdateString = "-";
  bool isMqttConnected = false;

  // ------------------------------------------------------------------------
  // PALET WARNA PROFESSIONAL PREMIUM DARK (MATTE / DEEP THEME)
  // ------------------------------------------------------------------------
  final Color bgColor = const Color(0xFF0F1115);       // Hitam keabuan premium (Slate Dark)
  final Color appBarColor = const Color(0xFF161920);   // Sedikit lebih terang dari bg
  final Color cardColor = const Color(0xFF161920);     // Material Card Matte
  final Color itemBgColor = const Color(0xFF212631);   // Latar status kecil / tombol sekunder
  
  // Warna Grafik Nyaman Dimata (Muted Slate / Pastel Industrial)
  final Color soilColor = const Color(0xFF64748B);     // Slate Gray (Netral)
  final Color tempColor = const Color(0xFFE2E8F0);     // Off-White / Light Gray
  final Color humidityColor = const Color(0xFF38BDF8); // Soft Ocean Blue (Teduh)
  final Color statusSuccess = const Color(0xFF34D399); // Soft Mint Green (Bukan Neon)
  final Color statusWarning = const Color(0xFFFBBF24); // Soft Amber
  final Color statusDanger = const Color(0xFFF87171);  // Soft Muted Red

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

  List<Map<String, dynamic>> getSortedHistoryList(Map<String, dynamic> rawData) {
    List<Map<String, dynamic>> list = [];
    rawData.forEach((key, val) {
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    });
    list.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
    
    if (list.length > 6) {
      list = list.sublist(list.length - 6);
    }
    return list;
  }

  List<FlSpot> getChartSpots(List<Map<String, dynamic>> sortedList, String key) {
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedList.length; i++) {
      double val = (sortedList[i][key] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    String soilStatus = currentSoil < 2200 ? "BASAH" : (currentSoil <= 3200 ? "NORMAL" : "KERING");
    Color dynamicSoilColor = soilStatus == "KERING" ? statusDanger : (soilStatus == "NORMAL" ? statusWarning : statusSuccess);

    String tempStatus = currentTemp >= 32.0 ? "PANAS" : (currentTemp >= 24.0 ? "NORMAL" : "DINGIN");
    Color dynamicTempColor = tempStatus == "PANAS" ? statusDanger : (tempStatus == "NORMAL" ? statusSuccess : humidityColor);

    String humidityStatus = currentHumidity < 40 ? "KERING" : (currentHumidity > 85 ? "SANGAT BASAH" : "NORMAL");
    Color dynamicHumidityColor = currentHumidity < 40 ? statusDanger : humidityColor;

    Color pumpColor = currentPumpStatus == "ON" ? statusSuccess : Colors.white.withOpacity(0.3);

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
                        _buildSensorCard(
                          title: "Soil Sensor",
                          subtitle: "Kelembaban Tanah",
                          value: currentSoil,
                          unit: "ADC",
                          status: soilStatus,
                          statusColor: dynamicSoilColor, 
                          chartColor: soilColor,  
                          icon: Icons.eco_outlined,
                          minY: 0,
                          maxY: 4000,
                          horizontalInterval: 1000,
                          spots: soilSpots,
                          historyList: finalSortedHistory,
                        ),
                        const SizedBox(height: 14),

                        _buildSensorCard(
                          title: "Temperature",
                          subtitle: "Suhu Udara",
                          value: currentTemp,
                          unit: "°C",
                          status: tempStatus,
                          statusColor: dynamicTempColor, 
                          chartColor: tempColor,  
                          icon: Icons.thermostat_outlined,
                          minY: 0,
                          maxY: 50,
                          horizontalInterval: 10,
                          spots: tempSpots,
                          historyList: finalSortedHistory,
                        ),
                        const SizedBox(height: 14),

                        _buildSensorCard(
                          title: "Humidity",
                          subtitle: "Kelembaban Udara",
                          value: currentHumidity,
                          unit: "%",
                          status: humidityStatus,
                          statusColor: dynamicHumidityColor,
                          chartColor: humidityColor, 
                          icon: Icons.water_drop_outlined,
                          minY: 0,
                          maxY: 100,
                          horizontalInterval: 20, 
                          spots: humiditySpots,
                          historyList: finalSortedHistory,
                        ),
                        const SizedBox(height: 14),

                        _buildSystemStatusCard(
                          soilStatus: soilStatus,
                          soilColor: dynamicSoilColor,
                          tempStatus: tempStatus,
                          tempColor: dynamicTempColor,
                          pumpStatus: currentPumpStatus,
                          pumpColor: pumpColor,
                        ),
                        const SizedBox(height: 14),

                        _buildRemoteControlCard(),
                        const SizedBox(height: 12),

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
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
          const SizedBox(height: 4),
          Text(
            "Mode aktif saat ini: $currentSystemMode Mode",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          const SizedBox(height: 14),

          if (isModeAuto) ...[
            Theme(
              data: ThemeData(elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(elevation: 0))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: itemBgColor,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  onPressed: () => _kirimPerintahMqtt("OFF"), 
                  label: const Text("PINDAH KE MODE MANUAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],

          if (!isModeAuto) ...[
            Theme(
              data: ThemeData(elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(elevation: 0))),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPumpStatus == "ON" ? humidityColor : itemBgColor,
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
                        backgroundColor: currentPumpStatus == "OFF" ? statusDanger : itemBgColor,
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
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.8),
                side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.brightness_auto, size: 16),
              onPressed: () => _kirimPerintahMqtt("AUTO"),
              label: const Text("KEMBALI KE MODE OTOMATIS (AUTO)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

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
                      color: isMqttConnected ? statusSuccess : statusWarning, 
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
            ],
          ),
        ],
      ),
    );
  }

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

    double calculatedMinY = minY;
    double calculatedMaxY = maxY;
    double intervalGrid = horizontalInterval;

    if (title == "Soil Sensor") {
      calculatedMinY = 0;
      calculatedMaxY = 4000;
      intervalGrid = 1000; 
    } else if (title == "Temperature") {
      calculatedMinY = 0;
      calculatedMaxY = 50;
      intervalGrid = 10;   
    } else if (title == "Humidity") {
      calculatedMinY = 0;
      calculatedMaxY = 100;
      intervalGrid = 20;   
    }

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
                    child: Icon(icon, color: Colors.white70, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
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
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(unit, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
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
          
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.isEmpty ? 5 : spots.length.toDouble() - 1,
                minY: calculatedMinY, 
                maxY: calculatedMaxY, 
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: intervalGrid,
                  verticalInterval: 1, 
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
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
                      interval: intervalGrid,
                      getTitlesWidget: (value, meta) {
                        if (value >= calculatedMinY && value <= calculatedMaxY && (value % intervalGrid == 0)) {
                          return Text(
                            value.toInt().toString(), 
                            // WARNA PUTIH TEGAS PADA ANGKA SUMBU Y GRAFIK
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 11, 
                              fontWeight: FontWeight.bold
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1, 
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < historyList.length) {
                          int ts = historyList[index]['timestamp'] ?? 0;
                          if (ts != 0) {
                            DateTime date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                            
                            // FORMAT WAKTU DIKUNCI JAM DAN MENIT (HH:mm) TANPA DETIK
                            String timeStr = DateFormat('HH:mm').format(date);
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timeStr, 
                                // WARNA PUTIH TEGAS PADA TEKS WAKTU SUMBU X GRAFIK
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold
                                )
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
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true, 
                    curveSmoothness: 0.35, 
                    preventCurveOverShooting: true, 
                    color: chartColor.withOpacity(0.8), 
                    barWidth: 2.5, 
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => true, 
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3, 
                          color: chartColor, 
                          strokeWidth: 0, 
                          strokeColor: Colors.transparent
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartColor.withOpacity(0.12), 
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
              Container(width: 12, height: 2, color: chartColor.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text("$title ($unit)", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

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
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusItem("Tanah", soilStatus, soilColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusItem("Suhu", tempStatus, tempColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusItem("Pompa", pumpStatus, pumpColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        "Last Update: $lastUpdateString",
        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontStyle: FontStyle.italic),
      ),
    );
  }
}