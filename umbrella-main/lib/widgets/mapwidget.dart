// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:umbrella/screens/main_screen.dart';

// class UmbrellaBox {
//   final String id;
//   final String name;
//   final double lat;
//   final double lng;

//   UmbrellaBox({
//     required this.id,
//     required this.name,
//     required this.lat,
//     required this.lng,
//   });
// }

// class MapWidget extends StatelessWidget {
//   final void Function(String boxId, String boxName) onBoxTap;

//   const MapWidget({super.key, required this.onBoxTap});

//   @override
//   Widget build(BuildContext context) {
//     List<UmbrellaBox> boxes = [
//       UmbrellaBox(id: '1', name: '미디어랩스', lat: 37.5665, lng: 126.9780),
//       UmbrellaBox(id: '2', name: '서울역', lat: 37.5547, lng: 126.9706),
//     ];

//     return FlutterMap(
//       options: MapOptions(center: LatLng(37.5665, 126.9780), zoom: 13),
//       children: [
//         TileLayer(
//           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//           userAgentPackageName: 'com.example.app',
//         ),
//         MarkerLayer(
//           markers: boxes.map((box) {
//             return Marker(
//               point: LatLng(box.lat, box.lng),
//               width: 40,
//               height: 40,
//               builder: (ctx) => GestureDetector(
//                 onTap: () => onBoxTap(box.id, box.name),
//                 child:
//                     const Icon(Icons.location_on, color: Colors.blue, size: 40),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }

// // void _onTapBox(UmbrellaBox box) async {
// //   final result = await ApiService().fetchUmbrellaStatus(box.id.toString());

// //   setState(() {
// //     umbrella = result['umbrella'] ?? 0;
// //     emptySlot = result['emptySlot'] ?? 0;
// //   });

// //   if (context.mounted) {
// //     showModalBottomSheet(
// //       context: context,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
// //       ),
// //       builder: (context) => Container(
// //         padding: const EdgeInsets.all(20),
// //         height: 230,
// //         child: Column(
// //           children: [
// //             Text('${box.name}의 상태', style: const TextStyle(fontSize: 18)),
// //             const SizedBox(height: 20),
// //             UmbrellaStatusWidget(
// //               umbrella: umbrella,
// //               emptySlot: emptySlot,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
