import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:umbrella/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/services/api_service.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:jwt_decoder/jwt_decoder.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final apiService = ApiService();
  String? _nfcResult;
  bool _isScanning = false;
  final MapController _mapController = MapController();
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  // Future<void> scanAndSendNfc(BuildContext context) async {
  //   setState(() {
  //     _isScanning = true;
  //     _nfcResult = null;
  //   });

  //   try {
  //     final tag = await FlutterNfcKit.poll();
  //     final umbrellaLockerId = tag.id;

  //     final userProfile = await apiService.getUserProfile(context);
  //     final userId = userProfile?['id'];

  //     if (userId == null) {
  //       setState(() {
  //         _nfcResult = '❌ 사용자 정보 없음';
  //       });
  //       return;
  //     }

  //     await apiService.sendUmbrellaUsage(userId, umbrellaLockerId);

  //     setState(() {
  //       _nfcResult =
  //           '✅ 우산함 ID: $umbrellaLockerId\n✅ 사용자 ID: $userId\n📡 서버 전송 완료';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _nfcResult = '❌ NFC 또는 서버 오류: $e';
  //     });
  //   } finally {
  //     await FlutterNfcKit.finish();
  //     setState(() {
  //       _isScanning = false;
  //     });
  //   }
  // }
  // NFC 스캔 후 우산함 ID와 사용자 ID를 서버로 보내는 함수
  Future<void> scanAndSendNfc(BuildContext context) async {
    setState(() {
      _isScanning = true;
      _nfcResult = null;
    });

    await Future.delayed(const Duration(seconds: 2)); // 가짜 대기 시간

    // 여기서 가짜 NFC ID를 넣어줌
    const fakeLockerId = "LOCKER123";

    final userProvider = context.read<UserProvider>();
    final token = userProvider.token;

    if (token == null) {
      developer.log("❌ 사용자 토큰 없음");
      return;
    }

    // JWT Payload을 디코딩하여 사용자 ID 추출
    final userId = _decodeJwtPayload(token)['id'];
    if (userId == null) {
      developer.log("❌ 사용자 ID 없음");
      return;
    }

    setState(() {
      _nfcResult = fakeLockerId;
    });

    developer.log("📦 전송 중... 사용자 ID: $userId, 우산함 ID: $fakeLockerId");

    // 서버로 사용자 ID와 우산함 ID 전송
    await ApiService().sendUmbrellaUsage(userId, fakeLockerId);

    setState(() {
      _isScanning = false;
    });
  }

  // JWT 디코딩 함수
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      // JWT의 페이로드를 디코딩해서 반환
      final payload = JwtDecoder.decode(token);
      return payload;
    } catch (e) {
      developer.log("❌ JWT 디코딩 오류: $e");
      return {};
    }
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawerEnableOpenDragGesture: false,
        drawer:
            _buildDrawer(context.watch<UserProvider>(), context), // ✅ 좌측 메뉴 추가
        body: Stack(
          children: [
            // 지도 (FlutterMap)
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialZoom: 17,
                minZoom: 13,
                maxZoom: 18,
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
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(20),
                        height: 230, // 모달 높이 조절 가능
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
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
                                            color: Color(0xFF0061FF),
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
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 30),
                                ),
                                const SizedBox(
                                  width: 50,
                                  child: Column(
                                    children: [
                                      Text(
                                        "6",
                                        style: TextStyle(
                                            fontSize: 40,
                                            color: Color(0xFFFF0000),
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
                                  backgroundColor: const Color(0xFF00B2FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                onPressed: () {
                                  print("이용하기 버튼 클릭됨");
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor:
                                        Colors.transparent, // 바텀시트의 배경을 투명하게 설정
                                    isScrollControlled: true, // 바텀시트 크기 조절 가능
                                    builder: (context) {
                                      // 바텀시트가 렌더링된 후 NFC 스캔 시작
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        scanAndSendNfc(context);
                                      });
                                      return Container(
                                        margin: const EdgeInsets.all(15),
                                        height: 450,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              30), // 둥근 모서리
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 45),
                                            const Text(
                                              "NFC 태그",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 20),
                                            // NFC 아이콘
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors
                                                    .transparent, // 아이콘 배경색
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(width: 40),
                                                  Image.asset(
                                                      'lib/assets/tag.png',
                                                      width: 160),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // 설명 텍스트
                                            const Text(
                                              "휴대전화의 뒷면을 카드 리더기에 대세요.",
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black),
                                            ),
                                            // 결과 보여주는 부분
                                            if (_isScanning)
                                              CircularProgressIndicator(),
                                            if (_nfcResult != null)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  _nfcResult!,
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 14),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            if (_nfcResult == null &&
                                                !_isScanning)
                                              const Text(
                                                "우산함 ID를 스캔 중입니다...",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14),
                                                textAlign: TextAlign.center,
                                              ),
                                            const SizedBox(height: 20),
                                            // 취소 버튼
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 0, 20, 0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 40,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context), // 바텀시트 닫기
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
                                                    ),
                                                  ),
                                                  child: const Text("취소",
                                                      style: TextStyle(
                                                          color: Colors.black)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
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
                                color: const Color(0xFF26539C),
                                borderRadius:
                                    BorderRadius.circular(20), // 둥근 모서리
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'lib/assets/umbrella.png',
                                    width: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    "4", // 숫자
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(width: 2)
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
                                  color: const Color(0xFF26539C), // 삼각형과 같은 색상
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
              left: MediaQuery.of(context).size.width / 2 - 120,
              child: _buildTopContainer(),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: _buildSearchButton(),
            ),
            Positioned(
              bottom: 30,
              right: 16,
              child: _buildFloatingButtons(),
            ),
          ],
        ),
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
            backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
            shape: WidgetStateProperty.all(const CircleBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
          ),
        );
      },
    );
  }

  // ✅ Drawer (좌측 메뉴)
  Widget _buildDrawer(UserProvider userProvider, BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(userProvider, context),

          // ✅ 메뉴: 로그인 상태일 때만 추가 메뉴 보이기
          if (userProvider.isLoggedIn) ...[
            _buildDrawerMenuItem(Icons.history, "이용 내역"),
            Divider(height: 1, color: Colors.grey[300]),
            _buildDrawerMenuItem(Icons.info_outline, "이용 안내"),
            Divider(height: 1, color: Colors.grey[300]),
            _buildDrawerMenuItem(Icons.headset_mic, "고객센터"),
            Divider(height: 1, color: Colors.grey[300]),
            const Spacer(),
            // 하단 로그아웃 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "로그아웃",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final userProvider = context.read<UserProvider>();
                  await userProvider.logout();
                  if (context.mounted) {
                    context.go('/'); // 첫 화면으로 이동
                  }
                },
              ),
            ),
          ] else ...[
            // ✅ 로그아웃 상태일 때는 '이용 안내'만
            _buildDrawerMenuItem(Icons.info_outline, "이용 안내"),
          ],
        ],
      ),
    );
  }

  // ✅ Drawer 상단 프로필 영역 (정렬 및 디자인 개선)
  Widget _buildDrawerHeader(UserProvider userProvider, BuildContext context) {
    if (!userProvider.isLoggedIn) {
      return ListTile(
        leading: const Icon(Icons.login),
        title: const Text('로그인'),
        onTap: () {
          context.go('/login');
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.userName ?? '사용자',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  userProvider.userData?['id'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              context.push('/profile');
            },
          ),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        print("$title 클릭됨");
        Navigator.pop(context);
        if (title == "이용 안내") {
          showOnboardingDialog(context);
        }
      },
    );
  }

  // 상단 중앙 컨테이너 (곡률 있음)
  Widget _buildTopContainer() {
    return Container(
      width: 240,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF26539C),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Image.asset('lib/assets/nii_nae.jpg'),
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
        backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
      ),
    );
  }

  // 하단 우측 아이콘 버튼 3개 (날씨, 클립, 좌표)
  Widget _buildFloatingButtons() {
    return Column(
      children: [
        _buildRoundIconButton(Icons.cloud, "날씨"),
        const SizedBox(height: 10),
        _buildRoundIconButton(Icons.wifi_tethering_error_rounded, "클립"),
        const SizedBox(height: 10),
        _buildRoundIconButton(Icons.my_location, "좌표"),
      ],
    );
  }

  // 공통 아이콘 버튼 스타일
  Widget _buildRoundIconButton(IconData icon, String label) {
    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
      child: FloatingActionButton(
        heroTag: label,
        onPressed: () {
          print("$label 버튼 클릭됨");
          if (label == "좌표") {
            _updateLocation(); // 좌표 버튼 클릭 시 현재 위치로 이동
          }
        },
        backgroundColor: const Color(0xFF5075AF),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _OnboardingPopup extends StatefulWidget {
  @override
  _OnboardingPopupState createState() => _OnboardingPopupState();
}

class _OnboardingPopupState extends State<_OnboardingPopup> {
  int currentIndex = 0; // 현재 페이지 인덱스
  final int totalPages = 9; // 전체 페이지 수

  final List<Map<String, String>> onboardingData = [
    {"title": "어떻게 대여/반납하나요?", "description": "지도에서 반납할 보관함 위치를\n확인하세요."},
    {"title": "어떻게 대여/반납하나요?", "description": "또는, 반납할 보관함을 검색하세요."},
    {
      "title": "어떻게 대여/반납하나요?",
      "description": "이용하기 버튼을 누르고 휴대폰을 보관함\nNFC 리더기에 가져다 대세요."
    },
    {"title": "어떻게 대여/반납하나요?", "description": "우산함 화면에 표시된 안내를 따라\n진행해 주세요."},
    {"title": "우산을 분실하셨나요?", "description": "우산과 연결이 끊긴 지점을\n확인해 주세요."},
    {
      "title": "우산을 분실하셨나요?",
      "description": "우산이 끊긴 위치에 도착하여, 해당 핀을\n터치해 내 우산 찾기를 시작해 주세요."
    },
    {"title": "서비스 구역 준수", "description": "대여한 우산은 지정된 서비스 구역\n내에서만 사용 가능합니다."},
    {
      "title": "반납 기간",
      "description": "대여 후 3일 이내 반납해 주세요. 3일 초과 시\n초과 일수의 2배 요금이 부과됩니다."
    },
    {
      "title": "우산 분실 및 미반납",
      "description": "우산 분실 시 보증금 10,000원이 부과되며,\n반납하지 않으면 다음 대여가 제한됩니다."
    },
  ];

  void nextPage() {
    if (currentIndex < totalPages - 1) {
      setState(() => currentIndex++);
    }
  }

  void prevPage() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 450,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ 제목
          const SizedBox(
            height: 30,
          ),
          Text(
            onboardingData[currentIndex]["title"]!,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          // ✅ 중앙 이미지 (사용자가 직접 추가)
          Image.asset(
            'lib/assets/icons/${currentIndex + 1}.jpg',
            width: 170,
            height: 170,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 15),

          // ✅ 설명 텍스트
          Text(
            onboardingData[currentIndex]["description"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),

          // ✅ 페이지 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentIndex
                      ? const Color(0xFF26539C)
                      : const Color(0xFF26539C).withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // ✅ 하단 네비게이션 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: prevPage,
                color: currentIndex > 0
                    ? Colors.black
                    : Colors.transparent, // 첫 페이지에서는 비활성화 색상
              ),
              if (currentIndex < totalPages - 1)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: nextPage,
                )
              else
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context), // 마지막 페이지에서는 닫기 버튼
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void showOnboardingDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)), // 둥근 모서리
        child: _OnboardingPopup(), // ✅ 별도 StatefulWidget으로 분리
      );
    },
  );
}

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:umbrella/services/auth_service.dart';
// import 'package:go_router/go_router.dart';
// import 'package:umbrella/provider/user_provider.dart';
// import 'package:provider/provider.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _MainScreenState createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   final MapController _mapController = MapController();
//   bool _locationPermissionGranted = false;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermission();
//   }
// final List<Map<String, dynamic>> umbrellaStations = [
//     {
//       "id": "station1",
//       "name": "우산함 1",
//       "location": LatLng(36.77203, 126.9316),
//     },
//     {
//       "id": "station2",
//       "name": "우산함 2",
//       "location": LatLng(36.77350, 126.9320),
//     },
//     {
//       "id": "station3",
//       "name": "우산함 3",
//       "location": LatLng(36.77100, 126.9305),
//     },
//   ];

//   Set<Marker> _createMarkers() {
//     return umbrellaStations.map((station) {
//       return Marker(
//         markerId: MarkerId(station['id']),
//         position: station['location'],
//         infoWindow: InfoWindow(title: station['name']),
//         onTap: () => _fetchAndShowLockerInfo(station['id']),
//       );
//     }).toSet();
//   }

//   Future<void> _fetchAndShowLockerInfo(String stationId) async {
//     try {
//       final response = await http.get(Uri.parse('https://your-api-url.com/lockers/$stationId'));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final umbrellas = data['umbrellas'];
//         final emptySlots = data['empty_slots'];

//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: const Text('우산함 정보'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text('남은 우산 개수: $umbrellas'),
//                 Text('빈 슬롯 개수: $emptySlots'),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 child: const Text('확인'),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ],
//           ),
//         );
//       } else {
//         _showErrorDialog('서버 오류: ${response.statusCode}');
//       }
//     } catch (e) {
//       _showErrorDialog('데이터를 불러오는 데 실패했습니다.');
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('에러'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             child: const Text('확인'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }
//   Future<void> _requestPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.whileInUse ||
//         permission == LocationPermission.always) {
//       _updateLocation();
//       setState(() {
//         _locationPermissionGranted = true;
//       });
//     }
//   }

//   Future<void> _updateLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     _mapController.move(LatLng(position.latitude, position.longitude), 17);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       child: Scaffold(
//         drawerEnableOpenDragGesture: false,
//         drawer:
//             _buildDrawer(context.watch<UserProvider>(), context), // ✅ 좌측 메뉴 추가
//         body: Stack(
//           children: [
//             // 지도 (FlutterMap)
//             FlutterMap(
//               mapController: _mapController,
//               options: const MapOptions(
//                 initialZoom: 17,
//                 minZoom: 13,
//                 maxZoom: 18,
//                 initialCenter: LatLng(36.77203, 126.9316),
//                 interactionOptions: InteractionOptions(
//                   flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
//                 ),
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                 ),
//                 if (_locationPermissionGranted)
//                   CurrentLocationLayer(
//                     style: LocationMarkerStyle(
//                       showAccuracyCircle: false,
//                       showHeadingSector: true,
//                       accuracyCircleColor: Colors.blue.withOpacity(0.2),
//                       marker: const DefaultLocationMarker(
//                         color: Colors.red,
//                       ),
//                     ),
//                   ),
//                 GestureDetector(
//                   onTap: () {
//                     showModalBottomSheet(
//                       context: context,
//                       shape: const RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.vertical(top: Radius.circular(30)),
//                       ),
//                       builder: (context) => Container(
//                         padding: const EdgeInsets.all(20),
//                         height: 230, // 모달 높이 조절 가능
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           borderRadius:
//                               BorderRadius.vertical(top: Radius.circular(30)),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             // 상단 바 (모달 핸들)
//                             Container(
//                               width: 50,
//                               height: 3,
//                               decoration: BoxDecoration(
//                                 color: const Color.fromARGB(255, 227, 227, 227),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             const SizedBox(height: 10),

//                             // 장소명 & 즐겨찾기 아이콘
//                             const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "미디어랩스",
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     color: Color.fromARGB(255, 78, 78, 78),
//                                   ),
//                                 ),

//                                 // 즐겨찾기 아이콘
//                               ],
//                             ),

//                             // 우산 & 빈 슬롯 정보
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const SizedBox(
//                                   width: 50,
//                                   child: Column(
//                                     children: [
//                                       Text(
//                                         "4",
//                                         style: TextStyle(
//                                             fontSize: 40,
//                                             color: Color(0xFF0061FF),
//                                             fontWeight: FontWeight.w100),
//                                       ),
//                                       Text(
//                                         "우산",
//                                         style: TextStyle(color: Colors.grey),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Container(
//                                   height: 50,
//                                   width: 1,
//                                   color: Colors.grey[300],
//                                   margin: const EdgeInsets.symmetric(
//                                       horizontal: 30),
//                                 ),
//                                 const SizedBox(
//                                   width: 50,
//                                   child: Column(
//                                     children: [
//                                       Text(
//                                         "6",
//                                         style: TextStyle(
//                                             fontSize: 40,
//                                             color: Color(0xFFFF0000),
//                                             fontWeight: FontWeight.w100),
//                                       ),
//                                       Text(
//                                         "빈 슬롯",
//                                         style: TextStyle(color: Colors.grey),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 20),

//                             // 이용하기 버튼
//                             SizedBox(
//                               width: double.infinity,
//                               height: 40,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF00B2FF),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(40),
//                                   ),
//                                 ),
//                                 onPressed: () {
//                                   print("이용하기 버튼 클릭됨");
//                                   showModalBottomSheet(
//                                     context: context,
//                                     backgroundColor: Colors
//                                         .transparent, // ✅ 바텀시트의 배경을 투명하게 설정
//                                     isScrollControlled: true, // ✅ 바텀시트 크기 조절 가능
//                                     builder: (context) {
//                                       return Container(
//                                         margin: const EdgeInsets.all(15),
//                                         height: 450,
//                                         decoration: BoxDecoration(
//                                           color: Colors.white,
//                                           borderRadius: BorderRadius.circular(
//                                               30), // ✅ 둥근 모서리
//                                         ),
//                                         child: Column(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             const SizedBox(height: 45),
//                                             const Text(
//                                               "NFC 태그",
//                                               style: TextStyle(
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.bold),
//                                             ),
//                                             const SizedBox(height: 20),
//                                             // ✅ NFC 아이콘
//                                             Container(
//                                               padding: const EdgeInsets.all(20),
//                                               decoration: BoxDecoration(
//                                                 color: Colors
//                                                     .transparent, // ✅ 아이콘 배경색
//                                                 borderRadius:
//                                                     BorderRadius.circular(10),
//                                               ),
//                                               child: Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.center,
//                                                 children: [
//                                                   const SizedBox(
//                                                     width: 40,
//                                                   ),
//                                                   Image.asset(
//                                                     'lib/assets/tag.png',
//                                                     width: 160,
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             const SizedBox(height: 20),
//                                             // ✅ 설명 텍스트
//                                             const Text(
//                                               "휴대전화의 뒷면을 카드 리더기에 대세요.",
//                                               style: TextStyle(
//                                                   fontSize: 13,
//                                                   color: Colors.black),
//                                             ),
//                                             const SizedBox(height: 20),
//                                             // ✅ 취소 버튼
//                                             Padding(
//                                               padding:
//                                                   const EdgeInsets.fromLTRB(
//                                                       20, 0, 20, 0),
//                                               child: SizedBox(
//                                                 width: double.infinity,
//                                                 height: 40,
//                                                 child: TextButton(
//                                                   onPressed: () =>
//                                                       Navigator.pop(
//                                                           context), // ✅ 바텀시트 닫기
//                                                   style: TextButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.grey[300],
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               7),
//                                                     ),
//                                                   ),
//                                                   child: const Text("취소",
//                                                       style: TextStyle(
//                                                           color: Colors.black)),
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(height: 10),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   );
//                                 },
//                                 child: const Text(
//                                   "이용하기",
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                   child: MarkerLayer(
//                     markers: [
//                       Marker(
//                         width: 60,
//                         height: 60,
//                         point: const LatLng(36.77200, 126.9317),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             // ✅ 타원형 배경
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 1),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF26539C),
//                                 borderRadius:
//                                     BorderRadius.circular(20), // 둥근 모서리
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Image.asset(
//                                     'lib/assets/umbrella.png',
//                                     width: 12,
//                                   ),
//                                   const SizedBox(width: 3),
//                                   const Text(
//                                     "4", // 숫자
//                                     style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w400),
//                                   ),
//                                   const SizedBox(width: 2)
//                                 ],
//                               ),
//                             ),
//                             // ✅ 아래 삼각형 (Transform 사용)
//                             Transform.translate(
//                               offset: const Offset(0, -6),
//                               child: Transform.rotate(
//                                 angle: 3.14 / 4, // 45도 회전
//                                 child: Container(
//                                   width: 10,
//                                   height: 10,
//                                   color: const Color(0xFF26539C), // 삼각형과 같은 색상
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             // UI 오버레이 요소
//             Positioned(
//               top: 40,
//               left: 16,
//               child: _buildMenuButton(),
//             ),
//             Positioned(
//               top: 40,
//               left: MediaQuery.of(context).size.width / 2 - 120,
//               child: _buildTopContainer(),
//             ),
//             Positioned(
//               top: 40,
//               right: 16,
//               child: _buildSearchButton(),
//             ),
//             Positioned(
//               bottom: 30,
//               right: 16,
//               child: _buildFloatingButtons(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ 햄버거 버튼 (Builder로 감싸서 context 오류 해결)
//   Widget _buildMenuButton() {
//     return Builder(
//       builder: (context) {
//         return IconButton(
//           icon: const Icon(Icons.menu, size: 30, color: Colors.white),
//           onPressed: () {
//             Scaffold.of(context).openDrawer(); // ✅ Drawer 열기
//           },
//           style: ButtonStyle(
//             backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
//             shape: WidgetStateProperty.all(const CircleBorder()),
//             padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
//           ),
//         );
//       },
//     );
//   }

//   // ✅ Drawer (좌측 메뉴)
//   Widget _buildDrawer(UserProvider userProvider, BuildContext context) {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           _buildDrawerHeader(userProvider, context),

//           // ✅ 메뉴: 로그인 상태일 때만 추가 메뉴 보이기
//           if (userProvider.isLoggedIn) ...[
//             _buildDrawerMenuItem(Icons.history, "이용 내역"),
//             Divider(height: 1, color: Colors.grey[300]),
//             _buildDrawerMenuItem(Icons.info_outline, "이용 안내"),
//             Divider(height: 1, color: Colors.grey[300]),
//             _buildDrawerMenuItem(Icons.headset_mic, "고객센터"),
//             Divider(height: 1, color: Colors.grey[300]),
//             const Spacer(),
//             // 하단 로그아웃 버튼
//             Padding(
//               padding: const EdgeInsets.only(bottom: 30),
//               child: ListTile(
//                 leading: const Icon(Icons.logout, color: Colors.red),
//                 title: const Text(
//                   "로그아웃",
//                   style: TextStyle(color: Colors.red),
//                 ),
//                 onTap: () async {
//                   final userProvider = context.read<UserProvider>();
//                   await userProvider.logout();
//                   if (context.mounted) {
//                     context.go('/'); // 첫 화면으로 이동
//                   }
//                 },
//               ),
//             ),
//           ] else ...[
//             // ✅ 로그아웃 상태일 때는 '이용 안내'만
//             _buildDrawerMenuItem(Icons.info_outline, "이용 안내"),
//           ],
//         ],
//       ),
//     );
//   }

//   // ✅ Drawer 상단 프로필 영역 (정렬 및 디자인 개선)
//   Widget _buildDrawerHeader(UserProvider userProvider, BuildContext context) {
//     if (!userProvider.isLoggedIn) {
//       return ListTile(
//         leading: const Icon(Icons.login),
//         title: const Text('로그인'),
//         onTap: () {
//           context.go('/login');
//         },
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
//       color: Colors.white,
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.grey[300],
//             child: const Icon(Icons.person, size: 40, color: Colors.white),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   userProvider.userName ?? '사용자',
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   userProvider.userData?['id'] ?? '',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.chevron_right),
//             onPressed: () {
//               context.push('/profile');
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ Drawer 메뉴 리스트 스타일 개선
//   Widget _buildDrawerMenuItem(IconData icon, String title) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.grey[700]),
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//       ),
//       onTap: () {
//         print("$title 클릭됨");
//         Navigator.pop(context);
//         if (title == "이용 안내") {
//           showOnboardingDialog(context);
//         }
//       },
//     );
//   }

//   // 상단 중앙 컨테이너 (곡률 있음)
//   Widget _buildTopContainer() {
//     return Container(
//       width: 240,
//       height: 50,
//       decoration: BoxDecoration(
//         color: const Color(0xFF26539C),
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Image.asset('lib/assets/nii_nae.jpg'),
//     );
//   }

//   // 검색 버튼 (돋보기)
//   Widget _buildSearchButton() {
//     return IconButton(
//       icon: const Icon(Icons.search, size: 30, color: Colors.white),
//       onPressed: () {
//         print("검색 버튼 클릭됨");
//       },
//       style: ButtonStyle(
//         backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
//         shape: WidgetStateProperty.all(const CircleBorder()),
//         padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
//       ),
//     );
//   }

//   // 하단 우측 아이콘 버튼 3개 (날씨, 클립, 좌표)
//   Widget _buildFloatingButtons() {
//     return Column(
//       children: [
//         _buildRoundIconButton(Icons.cloud, "날씨"),
//         const SizedBox(height: 10),
//         _buildRoundIconButton(Icons.wifi_tethering_error_rounded, "클립"),
//         const SizedBox(height: 10),
//         _buildRoundIconButton(Icons.my_location, "좌표"),
//       ],
//     );
//   }

//   // 공통 아이콘 버튼 스타일
//   Widget _buildRoundIconButton(IconData icon, String label) {
//     return Container(
//       width: 50,
//       height: 50,
//       clipBehavior: Clip.hardEdge,
//       decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
//       child: FloatingActionButton(
//         heroTag: label,
//         onPressed: () {
//           print("$label 버튼 클릭됨");
//           if (label == "좌표") {
//             _updateLocation(); // 좌표 버튼 클릭 시 현재 위치로 이동
//           }
//         },
//         backgroundColor: const Color(0xFF5075AF),
//         child: Icon(icon, color: Colors.white),
//       ),
//     );
//   }
// }

// class _OnboardingPopup extends StatefulWidget {
//   @override
//   _OnboardingPopupState createState() => _OnboardingPopupState();
// }

// class _OnboardingPopupState extends State<_OnboardingPopup> {
//   int currentIndex = 0; // 현재 페이지 인덱스
//   final int totalPages = 9; // 전체 페이지 수

//   final List<Map<String, String>> onboardingData = [
//     {"title": "어떻게 대여/반납하나요?", "description": "지도에서 반납할 보관함 위치를\n확인하세요."},
//     {"title": "어떻게 대여/반납하나요?", "description": "또는, 반납할 보관함을 검색하세요."},
//     {
//       "title": "어떻게 대여/반납하나요?",
//       "description": "이용하기 버튼을 누르고 휴대폰을 보관함\nNFC 리더기에 가져다 대세요."
//     },
//     {"title": "어떻게 대여/반납하나요?", "description": "우산함 화면에 표시된 안내를 따라\n진행해 주세요."},
//     {"title": "우산을 분실하셨나요?", "description": "우산과 연결이 끊긴 지점을\n확인해 주세요."},
//     {
//       "title": "우산을 분실하셨나요?",
//       "description": "우산이 끊긴 위치에 도착하여, 해당 핀을\n터치해 내 우산 찾기를 시작해 주세요."
//     },
//     {"title": "서비스 구역 준수", "description": "대여한 우산은 지정된 서비스 구역\n내에서만 사용 가능합니다."},
//     {
//       "title": "반납 기간",
//       "description": "대여 후 3일 이내 반납해 주세요. 3일 초과 시\n초과 일수의 2배 요금이 부과됩니다."
//     },
//     {
//       "title": "우산 분실 및 미반납",
//       "description": "우산 분실 시 보증금 10,000원이 부과되며,\n반납하지 않으면 다음 대여가 제한됩니다."
//     },
//   ];

//   void nextPage() {
//     if (currentIndex < totalPages - 1) {
//       setState(() => currentIndex++);
//     }
//   }

//   void prevPage() {
//     if (currentIndex > 0) {
//       setState(() => currentIndex--);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 320,
//       height: 450,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // ✅ 제목
//           const SizedBox(
//             height: 30,
//           ),
//           Text(
//             onboardingData[currentIndex]["title"]!,
//             style: const TextStyle(
//               fontSize: 18,
//             ),
//           ),
//           const SizedBox(height: 20),

//           // ✅ 중앙 이미지 (사용자가 직접 추가)
//           Image.asset(
//             'lib/assets/icons/${currentIndex + 1}.jpg',
//             width: 170,
//             height: 170,
//             fit: BoxFit.contain,
//           ),

//           const SizedBox(height: 15),

//           // ✅ 설명 텍스트
//           Text(
//             onboardingData[currentIndex]["description"]!,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 14, color: Colors.grey),
//           ),
//           const Spacer(),

//           // ✅ 페이지 인디케이터
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               totalPages,
//               (index) => Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 3),
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: index == currentIndex
//                       ? const Color(0xFF26539C)
//                       : const Color(0xFF26539C).withOpacity(0.4),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 15),

//           // ✅ 하단 네비게이션 버튼
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new),
//                 onPressed: prevPage,
//                 color: currentIndex > 0
//                     ? Colors.black
//                     : Colors.transparent, // 첫 페이지에서는 비활성화 색상
//               ),
//               if (currentIndex < totalPages - 1)
//                 IconButton(
//                   icon: const Icon(Icons.arrow_forward_ios),
//                   onPressed: nextPage,
//                 )
//               else
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context), // 마지막 페이지에서는 닫기 버튼
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// void showOnboardingDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20)), // 둥근 모서리
//         child: _OnboardingPopup(), // ✅ 별도 StatefulWidget으로 분리
//       );
//     },
//   );
// }
