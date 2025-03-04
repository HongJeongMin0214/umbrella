import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController();
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  // 위치 권한 요청 및 현재 위치 가져오기
  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _updateLocation();
      setState(() {
        _locationPermissionGranted = true;
      });
    }
  }

  // 현재 위치를 가져와 지도 중심 이동
  Future<void> _updateLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _mapController.move(LatLng(position.latitude, position.longitude), 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도 (FlutterMap)
          FlutterMap(
            mapController: _mapController, // 지도 컨트롤러 추가
            options: const MapOptions(
              initialZoom: 17,
              initialCenter: LatLng(36.77203, 126.9316),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              if (_locationPermissionGranted) // 위치 권한이 허용된 경우만 표시
                CurrentLocationLayer(
                  style: LocationMarkerStyle(
                    showAccuracyCircle: false,
                    showHeadingSector: true,
                    accuracyCircleColor: Colors.blue.withOpacity(0.2),
                    marker: const DefaultLocationMarker(
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          // UI 오버레이 요소
          Positioned(
            top: 40,
            left: 16,
            child: _buildMenuButton(),
          ),
          Positioned(
            top: 40,
            left: MediaQuery.of(context).size.width / 2 - 80,
            child: _buildTopContainer(),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: _buildSearchButton(),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: _buildFloatingButtons(),
          ),
        ],
      ),
    );
  }

  // 햄버거 메뉴 버튼
  Widget _buildMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu, size: 30, color: Colors.white),
      onPressed: () {
        print("메뉴 버튼 클릭됨");
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.blue),
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
      ),
    );
  }

  // 상단 중앙 컨테이너 (곡률 있음)
  Widget _buildTopContainer() {
    return Container(
      width: 160,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // 검색 버튼 (돋보기)
  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search, size: 30, color: Colors.white),
      onPressed: () {
        print("검색 버튼 클릭됨");
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.blue),
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
      ),
    );
  }

  // 하단 우측 아이콘 버튼 3개 (날씨, 클립, 좌표)
  Widget _buildFloatingButtons() {
    return Column(
      children: [
        _buildRoundIconButton(Icons.wb_sunny, "날씨"),
        const SizedBox(height: 10),
        _buildRoundIconButton(Icons.attach_file, "클립"),
        const SizedBox(height: 10),
        _buildRoundIconButton(Icons.my_location, "좌표"),
      ],
    );
  }

  // 공통 아이콘 버튼 스타일
  Widget _buildRoundIconButton(IconData icon, String label) {
    return FloatingActionButton(
      heroTag: label,
      onPressed: () {
        print("$label 버튼 클릭됨");
        if (label == "좌표") {
          _updateLocation(); // 좌표 버튼 클릭 시 현재 위치로 이동
        }
      },
      backgroundColor: Colors.blue,
      child: Icon(icon, color: Colors.white),
    );
  }
}
