import 'package:flutter/material.dart';

class TiltingPhoneIcon extends StatefulWidget {
  const TiltingPhoneIcon({super.key});

  @override
  State<TiltingPhoneIcon> createState() => _TiltingPhoneIconState();
}

class _TiltingPhoneIconState extends State<TiltingPhoneIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 1700000),
    )..repeat(reverse: true);

    _tiltAnimation = Tween<double>(
      begin: -0.5,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 7),
            color: Colors.white,
          ),
        ),
        ClipOval(
          child: SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _tiltAnimation,
              builder: (context, child) {
                return Center(
                  child: Transform.scale(
                    scale: 1.2,
                    child: Transform.translate(
                      offset: const Offset(0, 22),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(
                              _tiltAnimation.value * 30,
                              _tiltAnimation.value.abs() * 20,
                            ),
                            child: Container(
                              width: 60,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.0),
                                    blurRadius: 100,
                                    spreadRadius: 0,
                                    offset: Offset(
                                      _tiltAnimation.value * 20,
                                      _tiltAnimation.value.abs() * 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(_tiltAnimation.value),
                            child: Container(
                              width: 60,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      width: 27,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 7),
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
