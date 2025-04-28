// import 'package:flutter/material.dart';

// class UmbrellaStatusWidget extends StatelessWidget {
//   final int umbrella;
//   final int emptySlot;

//   const UmbrellaStatusWidget({
//     super.key,
//     required this.umbrella,
//     required this.emptySlot,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _buildStatusColumn("$umbrella", "우산", const Color(0xFF0061FF)),
//         Container(
//           height: 50,
//           width: 1,
//           color: Colors.grey[300],
//           margin: const EdgeInsets.symmetric(horizontal: 30),
//         ),
//         _buildStatusColumn("$emptySlot", "빈 슬롯", const Color(0xFFFF0000)),
//       ],
//     );
//   }

//   Widget _buildStatusColumn(String value, String label, Color color) {
//     return SizedBox(
//       width: 50,
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 40,
//               color: color,
//               fontWeight: FontWeight.w100,
//             ),
//           ),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }
