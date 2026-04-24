import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();

  final Color neon = const Color(0xFF4DA6FF);
  final Color bg1 = const Color(0xFF050A1A);
  final Color bg2 = const Color(0xFF1A1C3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),

              // 🔥 CARD BARU (LEBIH CLEAN)
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6), // 🔥 lebih gelap
                  borderRadius: BorderRadius.circular(20),

                  // 🔥 BORDER HITAM (BUKAN BIRU LAGI)
                  border: Border.all(
                    color: Colors.white12,
                  ),

                  // 🔥 GLOW HALUS (TIDAK NORAK)
                  boxShadow: [
                    BoxShadow(
                      color: neon.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 1,
                    )
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Icon(Icons.eco, size: 50, color: neon),

                    SizedBox(height: 10),

                    Text(
                      "Smart Farm",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: neon,
                      ),
                    ),

                    SizedBox(height: 25),

                    _inputField(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                    ),

                    SizedBox(height: 15),

                    _inputField(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock,
                      obscure: true,
                    ),

                    SizedBox(height: 25),

                    // 🔥 BUTTON (LEBIH SOFT)
                    GestureDetector(
                      onTap: () async {
                        var user = await auth.login(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );

                        if (user != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomePage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Login gagal!")),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),

                          // 🔥 warna dalam (bukan border)
                          color: neon.withOpacity(0.1),

                          border: Border.all(
                            color: neon.withOpacity(0.4),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: neon.withOpacity(0.25),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              color: neon,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterPage()),
                        );
                      },
                      child: Text(
                        "Belum punya akun? Register",
                        style: TextStyle(color: neon.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 INPUT STYLE BARU (LEBIH SOFT)
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),

      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: neon),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),

        filled: true,

        // 🔥 background dalam (bukan glow luar)
        fillColor: Colors.white.withOpacity(0.04),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white12, // 🔥 bukan biru lagi
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: neon.withOpacity(0.5), // 🔥 soft focus
          ),
        ),
      ),
    );
  }
}