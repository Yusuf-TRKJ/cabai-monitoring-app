import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();

  // ─── TEMA WARNA HIJAU GELAP SERAGAM SE-APLIKASI (SMART CHILI) ───
  final Color darkBg = const Color(0xFF051109);       // Hijau super gelap background utama
  final Color cardColor = const Color(0xFF0A1F13);     // Hijau solid container modal
  final Color primary = const Color(0xFF39B54A);       // Hijau neon cerah khas aplikasi
  final Color textDark = Colors.white;                 // Teks utama putih bersih
  final Color textSoft = Colors.white38;               // Teks sekunder/keterangan samar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
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
                /// ================= LOGO LAYERED GLOW =================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 45,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),

                /// ================= TITLE =================
                Text(
                  "Smart Chili",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Monitoring System",
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 14,
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

                /// ================= BUTTON LOGIN =================
                GestureDetector(
                  onTap: () async {
                    var user = await auth.login(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    if (user != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF4A151D), // Merah gelap untuk error
                          content: const Text(
                            "Login gagal! Periksa akun Anda.",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
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
                        "LOGIN",
                        style: TextStyle(
                          color: Color(0xFF051109), // Teks gelap di atas tombol terang
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                /// ================= REGISTER LINK =================
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primary.withOpacity(0.1),
                  ),
                  child: Text(
                    "Belum punya akun? Register",
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