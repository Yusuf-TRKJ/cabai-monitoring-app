import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatelessWidget {
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

              // 🔥 CARD BARU (CLEAN)
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6), // 🔥 lebih elegan
                  borderRadius: BorderRadius.circular(20),

                  // 🔥 border soft (bukan neon lagi)
                  border: Border.all(
                    color: Colors.white12,
                  ),

                  // 🔥 glow tipis (premium)
                  boxShadow: [
                    BoxShadow(
                      color: neon.withOpacity(0.15),
                      blurRadius: 20,
                    )
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Icon(Icons.person_add, size: 50, color: neon),

                    SizedBox(height: 10),

                    Text(
                      "Buat Akun Baru",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: neon,
                      ),
                    ),

                    SizedBox(height: 25),

                    // 🔥 EMAIL
                    _inputField(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                    ),

                    SizedBox(height: 15),

                    // 🔥 PASSWORD
                    _inputField(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock,
                      obscure: true,
                    ),

                    SizedBox(height: 25),

                    // 🔥 BUTTON REGISTER (SOFT GLOW)
                    GestureDetector(
                      onTap: () async {
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Email & password wajib diisi"),
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
                              content: Text("Register berhasil!"),
                            ),
                          );

                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Register gagal!"),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),

                          // 🔥 isi tombol (bukan border doang)
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
                            "REGISTER",
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
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Sudah punya akun? Login",
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

  // 🔥 INPUT CLEAN STYLE
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

        // 🔥 soft background
        fillColor: Colors.white.withOpacity(0.04),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white12,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: neon.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}