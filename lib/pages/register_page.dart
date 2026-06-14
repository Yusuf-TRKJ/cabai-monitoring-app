import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();

  // ─── TEMA WARNA HIJAU GELAP SERAGAM SE-APLIKASI (SMART CHILI) ───
  final Color bgColor = const Color(0xFF051109);       // Hijau super gelap background utama
  final Color cardColor = const Color(0xFF0A1F13);     // Hijau solid container modal
  final Color primary = const Color(0xFF39B54A);       // Hijau neon cerah khas aplikasi
  final Color textDark = Colors.white;                 // Teks utama putih bersih
  final Color textSoft = Colors.white38;               // Teks sekunder/keterangan samar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ================= ICON LAYERED GLOW =================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 45,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),

                /// ================= TITLE =================
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Register Smart Chili Monitoring",
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 35),

                /// ================= EMAIL =================
                _inputField(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                /// ================= PASSWORD =================
                _inputField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 30),

                /// ================= BUTTON REGISTER =================
                GestureDetector(
                  onTap: () async {
                    if (emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: cardColor,
                          content: Text("Email & password wajib diisi", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                        ),
                      );
                      return;
                    }

                    var user = await auth.register(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    if (user != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: cardColor,
                          content: Text("Register berhasil!", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF4A151D),
                          content: Text("Register gagal!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "REGISTER",
                        style: TextStyle(
                          color: Color(0xFF051109), // Teks gelap pekat di atas tombol terang
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                /// ================= TEXTBUTTON LOGIN =================
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primary.withOpacity(0.1),
                  ),
                  child: Text(
                    "Sudah punya akun? Login",
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= INPUT FIELD PREMIUM MATCHING =================
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        color: textDark,
        fontSize: 14,
      ),
      cursorColor: primary,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: primary.withOpacity(0.7),
          size: 20,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: textSoft,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}