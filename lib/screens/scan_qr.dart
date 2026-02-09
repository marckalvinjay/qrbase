import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/menu_button.dart';

class ScanQR extends StatefulWidget {
  const ScanQR({super.key});

  @override
  State<ScanQR> createState() => _ScanQRState();
}

class _ScanQRState extends State<ScanQR> {
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _controller = MobileScannerController();
  String _message = "Enter a student QR code";
  bool _isTimeIn = true;
  bool _useCamera = kIsWeb;
  bool _hasScanned = false;
  String? _cameraError;
  bool _startingCamera = false;

  @override
  void initState() {
    super.initState();
    if (_useCamera) {
      _requestCamera();
    }
  }

  String _firstNameFromFull(String fullName) {
    final parts = fullName.split(',').map((p) => p.trim()).toList();
    if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
    return fullName;
  }

  Future<void> _showResultDialog(String title, String message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1426) : Colors.white,
          titleTextStyle: TextStyle(
            color: isDark ? const Color(0xFFEAF7FF) : const Color(0xFF107C42),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: isDark ? const Color(0xFFC8E6F5) : const Color(0xFF3C3C3C),
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(child: Text(title)),
          content: Text(message, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processQR(String code) async {
    final student = await DBHelper.getStudentByQrCode(code);

    if (student == null || student.id == null) {
      setState(() => _message = "Student not found");
      await _showResultDialog("Not Found", "Student not found.");
      return;
    }

    final firstName = _firstNameFromFull(student.name);

    final now = DateTime.now();
    final period = now.hour < 12 ? "AM" : "PM";
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final logs = await DBHelper.getAttendanceForStudentInRange(
      student.id!,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    final hasTimeIn = logs.any((l) => l['type'] == '$period In');
    final hasTimeOut = logs.any((l) => l['type'] == '$period Out');

    if (_isTimeIn && hasTimeIn) {
      setState(() => _message = "Already logged ($period Time In)");
      await _showResultDialog(
        "Already Logged",
        "Already logged for today: $firstName",
      );
      return;
    }

    if (!_isTimeIn && hasTimeOut) {
      setState(() => _message = "Already logged ($period Time Out)");
      await _showResultDialog(
        "Already Logged",
        "Already logged for today: $firstName",
      );
      return;
    }

    final type = _isTimeIn ? "$period In" : "$period Out";
    await DBHelper.logAttendance(student.id!, type);
    setState(
      () => _message = "Logged $firstName ($type)",
    );
    await _showResultDialog(
      "Success!",
      "Time Logged: $firstName",
    );
  }

  Future<void> _handleCameraDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;
    _hasScanned = true;
    await _controller.stop();
    await _processQR(code);
    if (!mounted) return;
    _hasScanned = false;
    await _controller.start();
  }

  Future<void> _requestCamera() async {
    if (_startingCamera) return;
    _startingCamera = true;
    try {
      await _controller.start();
      if (!mounted) return;
      setState(() => _cameraError = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = e.toString());
    } finally {
      _startingCamera = false;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodLabel = DateTime.now().hour < 12 ? "Morning" : "Afternoon";
    return Scaffold(
      appBar: AppBar(
        leading: const HugeBackButton(),
        title: const SizedBox.shrink(),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: appBackgroundDecoration(context),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Log Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_useCamera) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 320,
                        height: 240,
                        child: Stack(
                          children: [
                            MobileScanner(
                              controller: _controller,
                              onDetect: _handleCameraDetect,
                              errorBuilder: (context, error) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      error.errorDetails?.message ??
                                          'Camera error.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(160),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_cameraError != null) ...[
                      Text(
                        _cameraError!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _requestCamera,
                        child: const Text("Try enable camera"),
                      ),
                    ],
                    TextButton(
                      onPressed: () {
                        setState(() => _useCamera = false);
                        _controller.stop();
                      },
                      child: const Text("Use manual entry"),
                    ),
                  ] else ...[
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: "QR Code",
                        hintText: "Paste the student QR code",
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (kIsWeb)
                      TextButton(
                        onPressed: () {
                          setState(() => _useCamera = true);
                          _requestCamera();
                        },
                        child: const Text("Use camera scanner"),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TogglePill(
                        label: "Time In",
                        icon: HugeIconsStrokeRounded.login01,
                        selected: _isTimeIn,
                        onTap: () => setState(() => _isTimeIn = true),
                      ),
                      const SizedBox(width: 10),
                      _TogglePill(
                        label: "Time Out",
                        icon: HugeIconsStrokeRounded.logout01,
                        selected: !_isTimeIn,
                        onTap: () => setState(() => _isTimeIn = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEAF7FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MenuButton(
                    width: 200,
                    height: 52,
                    label: "Log Attendance",
                    onPressed: () {
                      if (_useCamera) return;
                      final code = _codeController.text.trim();
                      if (code.isEmpty) return;
                      _processQR(code);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEAF7FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(90)),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
