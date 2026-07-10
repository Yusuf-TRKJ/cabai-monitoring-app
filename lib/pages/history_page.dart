import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref("history");
  
  // Status filter aktif: 'semua', 'hari_ini', 'kemarin', 'minggu_lalu', atau 'kustom_tanggal'
  String _activeFilter = 'semua'; 
  DateTime? _selectedCustomDate; // Menyimpan tanggal pilihan dari kalender picker

  // ─── PENYELARASAN PALET WARNA PREMIUM DARK CORPORATE (SESUAI REQUEST) ───
  final Color bgColor = const Color(0xFF0F1115);       // Hitam keabuan premium (Slate Dark)
  final Color cardColor = const Color(0xFF161920);     // Material Card Matte
  final Color primary = const Color(0xFF34D399);       // Soft Mint Green (Aksen Utama Aplikasi)
  final Color textDark = Colors.white;                  // Teks utama putih bersih
  final Color textSoft = Colors.white38;               // Teks sekunder/keterangan samar

  // Fungsi pembantu untuk memfilter data berdasarkan tanggal
  bool _applyFilter(dynamic timestampRaw) {
    if (timestampRaw == null) return false;

    try {
      DateTime dataDate;
      
      if (timestampRaw is int) {
        int convertedTimestamp = timestampRaw.toString().length < 13 ? timestampRaw * 1000 : timestampRaw;
        dataDate = DateTime.fromMillisecondsSinceEpoch(convertedTimestamp);
      } else if (timestampRaw is String) {
        dataDate = DateTime.parse(timestampRaw);
      } else {
        return false;
      }

      DateTime now = DateTime.now();
      
      // Ambil tanggal saja tanpa jam untuk komparasi akurat
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime checkingDate = DateTime(dataDate.year, dataDate.month, dataDate.day);

      // Logika Filter Kalender Kustom
      if (_activeFilter == 'kustom_tanggal' && _selectedCustomDate != null) {
        DateTime targetDate = DateTime(_selectedCustomDate!.year, _selectedCustomDate!.month, _selectedCustomDate!.day);
        return checkingDate.isAtSameMomentAs(targetDate);
      }

      // Logika Filter Tombol Bawaan
      if (_activeFilter == 'semua') return true;
      
      if (_activeFilter == 'hari_ini') {
        return checkingDate.isAtSameMomentAs(today);
      } else if (_activeFilter == 'kemarin') {
        DateTime yesterday = today.subtract(const Duration(days: 1));
        return checkingDate.isAtSameMomentAs(yesterday);
      } else if (_activeFilter == 'minggu_lalu') {
        DateTime oneWeekAgo = today.subtract(const Duration(days: 7));
        return checkingDate.isAfter(oneWeekAgo.subtract(const Duration(days: 1))) && 
               checkingDate.isBefore(today.add(const Duration(days: 1)));
      }
    } catch (e) {
      return false; 
    }
    return false;
  }

  // Fungsi untuk memunculkan kalender date picker HP
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedCustomDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primary,
              onPrimary: const Color(0xFF0F1115),
              surface: cardColor,
              onSurface: textDark,
            ),
            dialogBackgroundColor: bgColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedCustomDate = picked;
        _activeFilter = 'kustom_tanggal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "History Sensor", 
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        iconTheme: IconThemeData(color: textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Bagian Atas: Tombol Filter & Kalender ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: Colors.black.withOpacity(0.15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  _buildFilterButton("Semua", "semua"),
                  _buildFilterButton("Hari Ini", "hari_ini"),
                  _buildFilterButton("Kemarin", "kemarin"),
                  _buildFilterButton("Minggu Lalu", "minggu_lalu"),
                  
                  // ─── TOMBOL KALENDER KUSTOM ───
                  _buildCalendarFilterButton(),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),

          // --- Bagian List History Data ---
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: ref.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                final rawData = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                final keys = rawData.keys.toList();

                keys.sort((a, b) {
                  final itemA = Map<String, dynamic>.from(rawData[a]);
                  final itemB = Map<String, dynamic>.from(rawData[b]);
                  
                  dynamic tA = itemA['timestamp'] ?? 0;
                  dynamic tB = itemB['timestamp'] ?? 0;

                  int timeA = tA is int ? (tA.toString().length < 13 ? tA * 1000 : tA) : DateTime.parse(tA.toString()).millisecondsSinceEpoch;
                  int timeB = tB is int ? (tB.toString().length < 13 ? tB * 1000 : tB) : DateTime.parse(tB.toString()).millisecondsSinceEpoch;

                  return timeB.compareTo(timeA); 
                });

                final filteredKeys = keys.where((key) {
                  final item = Map<String, dynamic>.from(rawData[key]);
                  return _applyFilter(item['timestamp']);
                }).toList();

                if (filteredKeys.isEmpty) {
                  return Center(
                    child: Text(
                      "Tidak ada data pada periode ini.",
                      style: TextStyle(color: textSoft, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredKeys.length,
                  itemBuilder: (context, index) {
                    final String currentKey = filteredKeys[index];
                    final item = Map<String, dynamic>.from(rawData[currentKey]);

                    dynamic rawTimestamp = item['timestamp'];
                    String formattedTime = "-";
                    
                    try {
                      if (rawTimestamp != null) {
                        DateTime parsedDate;
                        if (rawTimestamp is int) {
                          int convertedTimestamp = rawTimestamp.toString().length < 13 ? rawTimestamp * 1000 : rawTimestamp;
                          parsedDate = DateTime.fromMillisecondsSinceEpoch(convertedTimestamp);
                        } else {
                          parsedDate = DateTime.parse(rawTimestamp.toString());
                        }
                        formattedTime = DateFormat('dd MMM yyyy - HH:mm').format(parsedDate);
                      }
                    } catch (_) {}

                    // ─── LOGIKA WARNA DINAMIS ORIGINAL (TIDAK DIUBAH) ───
                    final rawSoil = item['soil'];
                    double soilValue = 0.0;
                    if (rawSoil != null) {
                      soilValue = double.tryParse(rawSoil.toString()) ?? 0.0;
                    }

                    Color soilTextColor;
                    if (soilValue >= 3500.0) {
                      soilTextColor = const Color(0xFFEF4444); // Kering -> Merah asli
                    } else if (soilValue >= 2000.0 && soilValue < 3500.0) {
                      soilTextColor = const Color(0xFFFF9800); // Normal -> Orange asli
                    } else {
                      soilTextColor = const Color(0xFF39B54A); // Basah -> Hijau asli bawaan
                    }

                    // ─── PEMBULATAN ANGKA DESIMAL AGAR RAPI ───
                    String displaySuhu = "-";
                    dynamic rawSuhu = item['suhu'];
                    if (rawSuhu != null) {
                      double? parsedSuhu = double.tryParse(rawSuhu.toString());
                      displaySuhu = parsedSuhu != null ? parsedSuhu.toStringAsFixed(1) : rawSuhu.toString();
                    }

                    String displayHumidity = "-";
                    dynamic rawHumidity = item['humidity'];
                    if (rawHumidity != null) {
                      double? parsedHum = double.tryParse(rawHumidity.toString());
                      displayHumidity = parsedHum != null ? parsedHum.toStringAsFixed(1) : rawHumidity.toString();
                    }

                    String pompaStatus = (item['pompa_rekap'] ?? 'OFF').toString().toUpperCase();
                    bool isPompaOn = pompaStatus == 'ON';

                    // ─── IMPLEMENTASI SWIPE TO DELETE RAHASIA ───
                    return Dismissible(
                      key: Key(currentKey),
                      direction: DismissDirection.endToStart, 
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D191E), // Diubah ke warna maroon gelap corporate
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                      ),
                      onDismissed: (direction) {
                        ref.child(currentKey).remove();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Log data telah dihapus'),
                            backgroundColor: Color(0xFF2D191E),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withOpacity(0.02), width: 1.5), 
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "🌱 Soil: ${item['soil'] ?? '-'}",
                                style: TextStyle(
                                  color: soilTextColor, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  color: textSoft,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "🌡️ Suhu: $displaySuhu °C  |  💧 Lembab: $displayHumidity %",
                                  style: TextStyle(
                                    color: textDark.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      "🔌 Status Pompa: ",
                                      style: TextStyle(
                                        color: Colors.white60, 
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPompaOn 
                                            ? primary.withOpacity(0.12) 
                                            : const Color(0xFFEF4444).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pompaStatus,
                                        style: TextStyle(
                                          color: isPompaOn ? primary : const Color(0xFFEF4444),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembuat Tombol Filter Utama
  Widget _buildFilterButton(String label, String filterValue) {
    bool isSelected = _activeFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primary : cardColor,
          foregroundColor: isSelected ? const Color(0xFF0F1115) : textDark.withOpacity(0.8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.04),
              width: 1,
            ),
          ),
        ),
        onPressed: () {
          setState(() {
            _activeFilter = filterValue;
            _selectedCustomDate = null; 
          });
        },
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Widget Pembuat Tombol Kalender Picker
  Widget _buildCalendarFilterButton() {
    bool isSelected = _activeFilter == 'kustom_tanggal';
    String label = isSelected && _selectedCustomDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedCustomDate!)
        : "Cari Tgl";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primary : cardColor,
          foregroundColor: isSelected ? const Color(0xFF0F1115) : textDark.withOpacity(0.8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.04),
              width: 1,
            ),
          ),
        ),
        onPressed: () => _pickDate(context),
        icon: Icon(
          Icons.calendar_month_rounded, 
          size: 16, 
          color: isSelected ? const Color(0xFF0F1115) : primary
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}