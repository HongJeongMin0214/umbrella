import 'package:flutter/material.dart';

class LockerDetailWidget extends StatelessWidget {
  final String locationName;
  final int umbrellaCount;
  final int emptySlotCount;
  final VoidCallback onTapUse;

  const LockerDetailWidget({
    super.key,
    required this.locationName,
    required this.umbrellaCount,
    required this.emptySlotCount,
    required this.onTapUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 230,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 227, 227, 227),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locationName,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 78, 78, 78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Text(
                      "$umbrellaCount",
                      style: const TextStyle(
                        fontSize: 40,
                        color: Color(0xFF0061FF),
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    const Text("우산", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 30),
              ),
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Text(
                      "$emptySlotCount",
                      style: const TextStyle(
                        fontSize: 40,
                        color: Color(0xFFFF0000),
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    const Text("빈 슬롯", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onTapUse,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B2FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: const Text(
                "이용하기",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LockerStatus {
  final String lockerId;
  final double latitude;
  final double longitude;
  final int umbrellaCount;

  LockerStatus({
    required this.lockerId,
    required this.latitude,
    required this.longitude,
    required this.umbrellaCount,
  });

  factory LockerStatus.fromJson(Map<String, dynamic> json) {
    return LockerStatus(
      lockerId: json['lockerId'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      umbrellaCount: json['umbrellaCount'],
    );
  }
}
