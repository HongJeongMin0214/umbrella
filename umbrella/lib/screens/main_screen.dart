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

  Future<void> _updateLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _mapController.move(LatLng(position.latitude, position.longitude), 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(), // ✅ 좌측 메뉴 추가
      body: Stack(
        children: [
          // 지도 (FlutterMap)
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialZoom: 17,
              initialCenter: LatLng(36.77203, 126.9316),
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              if (_locationPermissionGranted)
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
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(20),
                      height: 230, // 모달 높이 조절 가능
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 상단 바 (모달 핸들)
                          Container(
                            width: 50,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 227, 227, 227),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 장소명 & 즐겨찾기 아이콘
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "미디어랩스",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 78, 78, 78),
                                ),
                              ),

                              // 즐겨찾기 아이콘
                            ],
                          ),

                          // 우산 & 빈 슬롯 정보
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 50,
                                child: Column(
                                  children: [
                                    Text(
                                      "4",
                                      style: TextStyle(
                                          fontSize: 40,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w100),
                                    ),
                                    Text(
                                      "우산",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 50,
                                width: 1,
                                color: Colors.grey[300],
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 30),
                              ),
                              const SizedBox(
                                width: 50,
                                child: Column(
                                  children: [
                                    Text(
                                      "6",
                                      style: TextStyle(
                                          fontSize: 40,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w100),
                                    ),
                                    Text(
                                      "빈 슬롯",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 이용하기 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                              onPressed: () {
                                print("이용하기 버튼 클릭됨");
                              },
                              child: const Text(
                                "이용하기",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: const LatLng(36.77200, 126.9317),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ 타원형 배경
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20), // 둥근 모서리
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.water_drop,
                                    color: Colors.white, size: 14), // 우산 아이콘
                                SizedBox(width: 3),
                                Text(
                                  "4", // 숫자
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 2)
                              ],
                            ),
                          ),
                          // ✅ 아래 삼각형 (Transform 사용)
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: Transform.rotate(
                              angle: 3.14 / 4, // 45도 회전
                              child: Container(
                                width: 10,
                                height: 10,
                                color: Colors.blue, // 삼각형과 같은 색상
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

  // ✅ 햄버거 버튼 (Builder로 감싸서 context 오류 해결)
  Widget _buildMenuButton() {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.menu, size: 30, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // ✅ Drawer 열기
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.blue),
            shape: WidgetStateProperty.all(const CircleBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
          ),
        );
      },
    );
  }

  // ✅ Drawer (좌측 메뉴)
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          _buildDrawerMenuItem(Icons.history, "이용 내역"),
          _buildDrawerMenuItem(Icons.info, "이용 안내"),
          _buildDrawerMenuItem(Icons.headset_mic, "고객센터"),
        ],
      ),
    );
  }

  // ✅ Drawer 상단 프로필 영역 (정렬 및 디자인 개선)
  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "김이박",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "kimyee123",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 프로필 수정 아이콘 (">")
          const Icon(Icons.chevron_right, size: 30, color: Colors.grey),
        ],
      ),
    );
  }

  // ✅ Drawer 메뉴 리스트 스타일 개선
  Widget _buildDrawerMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        print("$title 클릭됨");
        Navigator.pop(context);
      },
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
