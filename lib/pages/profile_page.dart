import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [

                // 🔥 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Profile",
                      style: TextStyle(
                        color: neon,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: Icon(Icons.arrow_back, color: neon),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // 🔥 AVATAR
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: neon.withOpacity(0.2),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, size: 40, color: neon),
                  ),
                ),

                SizedBox(height: 30),

                // 🔥 CARD CLEAN
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),

                    // 🔥 BORDER SOFT
                    border: Border.all(color: Colors.white12),

                    // 🔥 GLOW HALUS
                    boxShadow: [
                      BoxShadow(
                        color: neon.withOpacity(0.15),
                        blurRadius: 20,
                      )
                    ],
                  ),

                  child: Column(
                    children: [

                      _inputField(
                        controller: emailController,
                        hint: "Email",
                        icon: Icons.email,
                      ),

                      SizedBox(height: 15),

                      _inputField(
                        controller: passwordController,
                        hint: "Password Baru",
                        icon: Icons.lock,
                        obscure: true,
                      ),

                      SizedBox(height: 25),

                      // 🔥 BUTTON CLEAN
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Update berhasil (dummy)"),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),

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
                              "UPDATE",
                              style: TextStyle(
                                color: neon,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  // 🔥 INPUT STYLE CLEAN
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
        fillColor: Colors.white.withOpacity(0.04),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neon.withOpacity(0.5)),
        ),
      ),
    );
  }
}