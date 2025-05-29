import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:umbrella/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/services/api_service.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:umbrella/widgets/locker_detail_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:umbrella/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umbrella/widgets/use_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final apiService = ApiService();
  final MapController _mapController = MapController();
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(vsync: this, mapController: _mapController);
  bool _locationPermissionGranted = false;
  bool _isOverdue = false;
  DateTime? _releaseDate;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    fetchAllLockerStatuses();
    loadFavorites();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserFromStorage(); // ✅ 토큰 로딩 보장
      print("불러온 토큰: ${userProvider.token}");
      print("디코딩된 사용자 정보: ${userProvider.userData}");
      await fetchAndSetOverdueStatus(); // ✅ 그 후에 연체 상태 불러오기

      if (!mounted) return;

      checkAndShowOverduePopup();
      if (initialNotificationType == 'expired') {
        _showExpiredPopup();
        initialNotificationType = null;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

// 구글 설문조사 URL
  final String googleSurveyUrl =
      "https://docs.google.com/forms/d/e/1FAIpQLSd***********/viewform";

  // 첫번째 팝업 (예/아니오)
  void _showExpiredPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "우산 반납 기간을 초과하였습니다.\n우산을 분실하셨나요?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 17),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (await canLaunchUrl(Uri.parse(googleSurveyUrl))) {
                      await launchUrl(Uri.parse(googleSurveyUrl),
                          mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('설문조사 페이지를 열 수 없습니다.')));
                    }
                  },
                  child: const Text("예", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black54,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showReturnPleasePopup();
                  },
                  child: const Text("아니오"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 두번째 팝업 (아니오 눌렀을 때)
  void _showReturnPleasePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              "우산을 반납해주세요.",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "우산을 반납하지 않았습니다.\n대여한 우산 반납 후, 우산 대여가 가능합니다.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
                backgroundColor: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("확인"),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Future<void> fetchAndSetOverdueStatus() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.token;
      print("전송할 토큰: $token");

      if (token == null) {
        throw Exception("로그인 정보가 없습니다.");
      }

      final status = await apiService.checkOverdueStatus(token);
      print("초기 로딩: isOverdue=$_isOverdue, releaseDate=$_releaseDate");

      setState(() {
        _isOverdue = status['isOverdue'];
        _releaseDate = status['releaseDate'] != null
            ? DateTime.parse(status['releaseDate'])
            : null;
      });
      print("setState 이후: isOverdue=$_isOverdue, releaseDate=$_releaseDate");
      print("연체 정보 불러오기 성공");
    } catch (e) {
      print("연체 정보 불러오기 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("연체 정보를 불러오는 데 실패했습니다.")),
      );
    }
  }

  void checkAndShowOverduePopup() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token;

    if (token == null) return;

    try {
      final overdueInfo = await apiService.checkOverdueStatus(token);
      final isOverdue = overdueInfo['isOverdue'] == true;
      final releaseDateString = overdueInfo['releaseDate'];

      if (isOverdue && releaseDateString != null) {
        final releaseDate = DateTime.parse(releaseDateString);
        final now = DateTime.now();

        if (releaseDate.isAfter(now)) {
          // releaseDate가 현재보다 미래라서 타이머 돌릴 수 있는 상태
          if (mounted) {
            setState(() {
              _isOverdue = true;
              _releaseDate = releaseDate;
            });
            _showOverduePopup(releaseDate);

            /// 🔽 여기서 타이머 시작
            final duration = releaseDate.difference(now);
            Future.delayed(duration, () {
              if (mounted) {
                setState(() {
                  _isOverdue = false;
                  _releaseDate = null;
                });
              }
            });
          }
        } else {
          // releaseDate가 현재보다 과거 => 이미 연체 기간이 지났음
          developer.log('연체 패널티 기간이 종료됨: $releaseDate');
          if (mounted) {
            setState(() {
              _isOverdue = false;
              _releaseDate = null; // 타이머 돌릴 날짜가 없으니 null 처리하거나 다른 상태로
            });
            // 팝업 띄울 필요 x
          }
        }
      } else {
        // 연체가 아님
        if (mounted) {
          setState(() {
            _isOverdue = false;
            _releaseDate = null;
          });
        }
      }
    } catch (e) {
      print('연체 상태 확인 실패: $e');
    }
  }

  void _showOverduePopup(DateTime releaseDate) {
    final formattedDateTime =
        DateFormat('yyyy년 MM월 dd일 HH시 mm분').format(releaseDate);
    final message = '$formattedDateTime 부터 이용 가능합니다.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 27, 24, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 51, color: Color(0xFF757575)),
            const SizedBox(height: 16),
            const Text(
              "연체로 인한 이용 제한 상태입니다.",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color:
                    releaseDate != null ? Colors.lightBlue : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.lightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  List<LockerStatus> allLockerStatus = [];

  Future<void> fetchAllLockerStatuses() async {
    try {
      final List<LockerStatus> result =
          await ApiService().fetchAllLockerStatuses();
      setState(() {
        allLockerStatus = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("전체 우산함 정보를 불러오는 데 실패했습니다.")),
      );
    }
  }

  bool isFetching = false;
  int umbrellaCount = 0;
  int emptySlotCount = 0;
  Future<void> fetchAndSetLockerStatus(String lockerId) async {
    try {
      final status = await ApiService().fetchLockerStatus(lockerId);
      setState(() {
        // 해당 우산함의 umbrellaCount를 갱신
        final lockerIndex = allLockerStatus.indexWhere(
          (locker) => locker.lockerId == lockerId,
        );

        if (lockerIndex != -1) {
          allLockerStatus[lockerIndex].umbrellaCount =
              status['umbrellaCount']; //우산개수 갱신
        }

        umbrellaCount = status['umbrellaCount'];
        emptySlotCount = 41 - umbrellaCount;
        isFetching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("우산함 정보를 불러오는 데 실패했습니다.")),
      );
    }
  }

//nfc 사용이 가능한지 확인 후 설정창으로 이동
  Future<void> readUmbrellaLockerIdFromNfc({
    required Function(String lockerId) onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("이 기기에서는 NFC를 사용할 수 없습니다."),
        ));
      return;
    }

    NfcManager.instance.startSession(
      alertMessage: '우산함에 휴대폰을 가까이 대주세요.',
      onDiscovered: (NfcTag tag) async {
        try {
          String? lockerId = _getLockerIdFromTag(tag);

          if (lockerId == null) {
            throw Exception("우산함 ID를 읽을 수 없습니다.");
          }

          // iOS는 세션 수동 종료 필요
          NfcManager.instance.stopSession(alertMessage: '우산함 ID 읽기 성공');

          onSuccess(lockerId);
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: '우산함 ID 읽기 실패');
          onError(e.toString());
        }
      },
    );
  }

  String? _getLockerIdFromTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    final cachedMessage = ndef?.cachedMessage;

    if (cachedMessage == null) return null;

    final textRecord = cachedMessage.records.firstWhere(
      (record) => utf8.decode(record.type) == 'T',
      orElse: () => throw Exception("텍스트 형식 NDEF 데이터가 없습니다."),
    );

    final payload = textRecord.payload;
    final langCodeLen = payload[0]; // 첫 바이트는 언어코드 길이
    final lockerId = utf8.decode(payload.sublist(1 + langCodeLen));

    return lockerId;
  }

  void onTapUseButton(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startNfcProcess(context);
        });
        return _buildNfcBottomSheetUI(context);
      },
    );
  }

  void _startNfcProcess(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    readUmbrellaLockerIdFromNfc(
      onSuccess: (lockerId) async {
        try {
          final token = userProvider.token;

          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그인 정보가 없습니다.')),
            );
            return;
          }

          // 서버에 lockerId + token 전송
          await apiService.sendLockerIdAndToken(
            context,
            lockerId,
          );

          // 서버 응답 성공 시 바텀시트 닫기
          Navigator.pop(context);
        } catch (e) {
          developer.log("[LOG] ❌ 서버 통신 에러: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 통신 에러: $e')),
          );
        }
      },
      onError: (errorMsg) {
        developer.log("[LOG] ❌ NFC 읽기 에러: $errorMsg");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      },
    );
  }

  Future<void> requestPermissions() async {
    await _requestLocationPermission();
    await _requestNotificationPermission(); // Android 13 이상 대응
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // 사용자가 "다시 묻지 않음" 선택 → 설정으로 유도
      await Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _updateLocation();
      setState(() {
        _locationPermissionGranted = true;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied ||
        await Permission.notification.isPermanentlyDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        await openAppSettings(); // 유저가 꺼놓은 경우 설정으로 유도
      }
    }
  }

  Future<void> _updateLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // 위치 업데이트 후, 애니메이션을 통해 이동
    _animatedMapController.animateTo(
      dest: LatLng(position.latitude, position.longitude),
      zoom: _mapController.camera.zoom,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                MarkerLayer(
                  markers: allLockerStatus.map((locker) {
                    return Marker(
                      width: 60,
                      height: 60,
                      point: LatLng(locker.latitude, locker.longitude),
                      child: GestureDetector(
                        onTap: () async {
                          if (isFetching) return; // 중복 클릭 방지
                          setState(() => isFetching = true);

                          _animatedMapController.animateTo(
                            dest: LatLng(locker.latitude, locker.longitude),
                            zoom: _mapController.camera.zoom,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          try {
                            await fetchAndSetLockerStatus(
                                locker.lockerId); // 최신 정보 fetch
                            if (!mounted) return;

                            // 우산 개수가 갱신된 후, 말풍선 표시 업데이트
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30)),
                              ),
                              builder: (_) => LockerDetailWidget(
                                isOverdue: _isOverdue,
                                releaseDate: _releaseDate,
                                locationName: locker.locationName ?? '알 수 없음',
                                umbrellaCount: umbrellaCount,
                                emptySlotCount: emptySlotCount,
                                onTapUse: () {
                                  Navigator.pop(context);
                                  onTapUseButton(context);
                                },
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("세부 우산함 정보를 불러오는 데 실패했습니다.")),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => isFetching = false); // 다시 클릭 가능하게
                            }
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 말풍선 UI
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF26539C),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('lib/assets/umbrella.png',
                                      width: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    "${locker.umbrellaCount}", // 갱신된 우산 개수 표시
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                              ),
                            ),
                            // 아래 삼각형
                            Transform.translate(
                              offset: const Offset(0, -6),
                              child: Transform.rotate(
                                angle: 3.14 / 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  color: const Color(0xFF26539C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                if (isSearchOpen) _buildSearchOverlay(),
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: _buildFloatingButtons(),
                ),
                // 조건: _releaseDate와 _isOverdue는 마커를 누른 후에만 설정됨
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: (_releaseDate == null && _isOverdue)
                      ? const SizedBox(height: 50) // releaseDate 아직 안 들어온 상태
                      : UseButton(
                          isOverdue: _isOverdue,
                          releaseDate: _releaseDate,
                          onPressed: () {
                            if (_isOverdue && _releaseDate != null) return;
                            onTapUseButton(context);
                          },
                          onOverdueLifted: () {
                            if (mounted) {
                              setState(() {
                                _isOverdue = false;
                                _releaseDate = null;
                              });
                            }
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcBottomSheetUI(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 45),
          const Text(
            "NFC 태그",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 40),
                Image.asset('lib/assets/tag.png', width: 160),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "휴대전화의 뒷면을 카드 리더기에 대세요.",
            style: TextStyle(fontSize: 13, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text("취소", style: TextStyle(color: Colors.black)),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                    setState(() {
                      favoriteLockers.clear();
                    });
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

  String searchQuery = '';
  List<String> favoriteLockers = [];
  bool isSearchOpen = false;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = context.read<UserProvider>().userId;
    if (userId != null) {
      final storedFavorites = prefs.getStringList('favorites_$userId');
      setState(() {
        favoriteLockers = storedFavorites ?? [];
      });
    }
  }

  // 검색 버튼 (돋보기)
  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search, size: 30, color: Colors.white),
      onPressed: () {
        setState(() {
          isSearchOpen = !isSearchOpen;
          if (isSearchOpen) {
            searchQuery = '';
            _searchController.clear(); // ✅ 텍스트 필드 초기화
          }
        });
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF26539C)),
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
      ),
    );
  }

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Widget _buildSearchOverlay() {
    final filtered = allLockerStatus.where((locker) {
      return locker.locationName.contains(searchQuery);
    }).toList();

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Column(children: [
        // 검색창
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => setState(() => isSearchOpen = false),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '우산함 위치 이름 검색',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    _searchController.clear(); // ✅ 같이 초기화
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 리스트
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            // ⬅️ 여기!
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final locker = filtered[index];
              final isFavorite = favoriteLockers.contains(locker.lockerId);

              return ListTile(
                title: Text(
                  locker.locationName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Color(0xFFFFD700) : Colors.grey[400],
                  ),
                  onPressed: () => toggleFavorite(locker.lockerId),
                ),
                onTap: () async {
                  handleLockerSelection(locker);
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[300], // ✨ 얇고 연한 선
              indent: 16,
              endIndent: 16,
            ),
          ),
        ),
      ]),
    );
  }

  bool _isHandlingTap = false;

  Future<void> handleLockerSelection(locker) async {
    if (_isHandlingTap) return;
    _isHandlingTap = true;

    try {
      setState(() => isSearchOpen = false);

      // 지도 이동 먼저
      await _animatedMapController.animateTo(
        dest: LatLng(locker.latitude + 0.0005, locker.longitude),
        zoom: _mapController.camera.zoom,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // 상태 가져오기
      await fetchAndSetLockerStatus(locker.lockerId);

      // 모달 띄우기
      if (!mounted) return;
      await showModalBottomSheet(
        context: navigatorKey.currentContext ?? context, // <-- 안정적인 context
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (_) => LockerDetailWidget(
          isOverdue: _isOverdue,
          releaseDate: _releaseDate,
          locationName: locker.locationName,
          umbrellaCount: umbrellaCount,
          emptySlotCount: emptySlotCount,
          onTapUse: () {
            Navigator.pop(context);
            onTapUseButton(context);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error handling locker tap: $e');
    } finally {
      _isHandlingTap = false;
    }
  }

  void toggleFavorite(String lockerId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = context.read<UserProvider>().userId;

    if (userId == null) return; // ✅ null 방어

    setState(() {
      if (favoriteLockers.contains(lockerId)) {
        favoriteLockers.remove(lockerId);
      } else {
        favoriteLockers.add(lockerId);
      }

      prefs.setStringList('favorites_$userId', favoriteLockers);

      allLockerStatus.sort((a, b) {
        final aFav = favoriteLockers.contains(a.lockerId) ? 0 : 1;
        final bFav = favoriteLockers.contains(b.lockerId) ? 0 : 1;
        return aFav.compareTo(bFav);
      });
    });
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

class LockerStatus {
  final String lockerId;
  final double latitude;
  final double longitude;
  int umbrellaCount;
  final String locationName;

  LockerStatus(
      {required this.lockerId,
      required this.latitude,
      required this.longitude,
      required this.umbrellaCount,
      required this.locationName});

  // 고정 위치 정보 Map
  static const Map<String, LockerMeta> _lockerMetaMap = {
    'locker1': LockerMeta(36.77203, 126.9316, '미디어랩스'),
    'locker2': LockerMeta(36.77150, 126.9320, '도서관 입구'),
    // 필요한 만큼 추가 가능
  };

  factory LockerStatus.fromJson(Map<String, dynamic> json) {
    final lockerId = json['lockerId'];
    final meta = _lockerMetaMap[lockerId];

    return LockerStatus(
      lockerId: lockerId,
      latitude: meta?.latitude ?? 0.0,
      longitude: meta?.longitude ?? 0.0,
      locationName: meta?.locationName ?? 'Unknown',
      umbrellaCount: json['umbrellaCount'],
    );
  }
}

class LockerMeta {
  final double latitude;
  final double longitude;
  final String locationName;

  const LockerMeta(this.latitude, this.longitude, this.locationName);
}
