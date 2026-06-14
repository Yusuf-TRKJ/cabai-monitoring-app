import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusCard extends StatelessWidget {

  final String status;
  final Color color;

  const StatusCard({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: color,
          width: 2,
        ),

        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),

      child: Column(
        children: [

          Icon(
            Icons.eco,
            color: color,
            size: 50,
          ),

          const SizedBox(height: 10),

          const Text(
            "STATUS TANAMAN",
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}