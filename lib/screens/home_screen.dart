import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'attendance_log.dart';
import 'generate_qr.dart';
import 'scan_qr.dart';
import 'students_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/scan_frame.dart';
import '../widgets/menu_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<double> _menuFade;
  late final Animation<double> _menuScale;
  bool _menuOpen = false;
  bool _menuVisible = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _menuFade = CurvedAnimation(parent: _menuController, curve: Curves.easeOut);
    _menuScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_menuOpen) {
      _menuController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _menuOpen = false;
          _menuVisible = false;
        });
      });
    } else {
      setState(() {
        _menuOpen = true;
        _menuVisible = true;
      });
      _menuController.forward();
    }
  }

  Widget _menuButton({
    required String label,
    required List<List<dynamic>> icon,
    required VoidCallback onPressed,
  }) {
    return MenuButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: appBackgroundDecoration(context),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () async {
                        final controller = ThemeControllerProvider.of(context);
                        await controller.toggle();
                      },
                      icon: HugeIcon(
                        icon: ThemeControllerProvider.of(context).isDark
                            ? HugeIconsStrokeRounded.sun01
                            : HugeIconsStrokeRounded.moon01,
                        color: ThemeControllerProvider.of(context).isDark
                            ? const Color(0xFFEAF7FF)
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: _toggleMenu,
                      icon: HugeIcon(
                        icon: HugeIconsStrokeRounded.settings01,
                        color: const Color(0xFFEAF7FF),
                        size: 26,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const ScanFrame(size: 240),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        MenuButton(
                          width: 260,
                          height: 56,
                          label: "Scan QR for Time In / Time Out",
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScanQR()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_menuVisible)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withAlpha(140)),
                ),
              ),
            ),
          if (_menuVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withAlpha(0)),
              ),
            ),
          if (_menuVisible)
            Positioned.fill(
              child: Center(
                child: FadeTransition(
                  opacity: _menuFade,
                  child: ScaleTransition(
                    scale: _menuScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _menuButton(
                          label: "Generate Student QR",
                          icon: HugeIconsStrokeRounded.qrCode,
                          onPressed: () {
                            _toggleMenu();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GenerateQR()),
                            );
                          },
                        ),
                        _menuButton(
                          label: "View Attendance Log",
                          icon: HugeIconsStrokeRounded.checkList,
                          onPressed: () {
                            _toggleMenu();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AttendanceLog()),
                            );
                          },
                        ),
                        _menuButton(
                          label: "Students",
                          icon: HugeIconsStrokeRounded.userGroup,
                          onPressed: () {
                            _toggleMenu();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StudentsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
