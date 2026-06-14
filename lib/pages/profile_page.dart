import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ─── TEMA WARNA HIJAU GELAP SERAGAM SE-APLIKASI (SMART CHILI) ───
  final Color bg1 = const Color(0xFF051109);       // Hijau super gelap background utama
  final Color cardColor = const Color(0xFF0A1F13); // Hijau solid untuk card container
  final Color appBarColor = const Color(0xFF030A05); // Warna AppBar gelap proporsional
  final Color neonGreen = const Color(0xFF39B54A); // Hijau neon cerah khas dashboard utama
  final Color neonRed = const Color(0xFFE54A4A);   // Aksen merah tegas untuk logout

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg1,
      appBar: AppBar(
        backgroundColor: appBarColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "PROFIL USER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ─── 1. AVATAR DENGAN BORDER HIJAU CERAH & GLOW ───
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), // Jarak border
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withOpacity(0.2),
                          blurRadius: 25,
                          spreadRadius: 2,
                        )
                      ],
                      border: Border.all(color: neonGreen.withOpacity(0.8), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: cardColor,
                      child: const Icon(Icons.person_rounded, size: 55, color: Colors.white),
                    ),
                  ),
                  // Tombol edit kecil menempel di kanan bawah avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: neonGreen,
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ─── 2. CARD CONTAINER HIJAU MODAL ───
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.03), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "INFORMASI AKUN",
                      style: TextStyle(
                        color: neonGreen.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Email
                    _inputField(
                      controller: emailController,
                      hint: "Email Akun",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Input Password
                    _inputField(
                      controller: passwordController,
                      hint: "Password Baru",
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                    ),
                    const SizedBox(height: 30),

                    // 🔥 BUTTON UPDATE
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: cardColor,
                            content: Text(
                              "Profil berhasil diperbarui!", 
                              style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: neonGreen,
                          boxShadow: [
                            BoxShadow(
                              color: neonGreen.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "SIMPAN PERUBAHAN",
                            style: TextStyle(
                              color: Color(0xFF051109), // Teks gelap pekat di atas tombol terang
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 🔥 BUTTON LOGOUT (SAMAR MERAH/SOFT BENING)
                    GestureDetector(
                      onTap: () {
                        // Tambahkan fungsi logout firebase di sini nanti bang
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: neonRed.withOpacity(0.06),
                          border: Border.all(color: neonRed.withOpacity(0.25)),
                        ),
                        child: Center(
                          child: Text(
                            "KELUAR AKUN",
                            style: TextStyle(
                              color: neonRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 INPUT FIELD PREMIUM STYLE MATCHING
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: neonGreen,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: neonGreen.withOpacity(0.7), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonGreen.withOpacity(0.8), width: 1.5),
        ),
      ),
    );
  }
}