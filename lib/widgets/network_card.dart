import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NetworkCard extends StatelessWidget {

  const NetworkCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: AppColors.neonBlue,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: const [

          Text(
            "NETWORK STATUS",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 15),

          Row(
            children: [

              Icon(
                Icons.wifi,
                color: Colors.green,
              ),

              SizedBox(width: 10),

              Text(
                "WiFi Connected",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [

              Icon(
                Icons.settings_input_antenna,
                color: Colors.green,
              ),

              SizedBox(width: 10),

              Text(
                "LoRa Active",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [

              Icon(
                Icons.cloud_done,
                color: Colors.green,
              ),

              SizedBox(width: 10),

              Text(
                "Firebase Online",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}