import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

import '../database/db_helper.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/menu_button.dart';
import '../utils/file_saver.dart';

class GenerateQR extends StatefulWidget {
  const GenerateQR({super.key});

  @override
  State<GenerateQR> createState() => _GenerateQRState();
}

class _GenerateQRState extends State<GenerateQR> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final GlobalKey _qrKey = GlobalKey();
  String? _qrData;
  String? _qrNameFull;
  String? _qrFirstName;

  Map<String, String>? _parseFullName(String input) {
    final parts = input.split(',').map((p) => p.trim()).toList();
    if (parts.length < 3) return null;
    return {
      'last': parts[0],
      'first': parts[1],
      'middle': parts[2],
    };
  }

  Future<void> _generateQR() async {
    if (_nameController.text.isEmpty) return;

    final parsed = _parseFullName(_nameController.text);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Use format: Lastname, Firstname, Middle Initial",
          ),
        ),
      );
      return;
    }

    // Create unique QR code using random string
    String qrCode = "${_nameController.text}_${Random().nextInt(10000)}";

    Student student = Student(name: _nameController.text, qrCode: qrCode);
    await DBHelper.addStudent(student);
    if (!mounted) return;

    setState(() {
      _qrData = qrCode;
      _qrNameFull = _nameController.text;
      _qrFirstName = parsed['first'];
    });

    _nameController.clear();
    _nameFocus.requestFocus();

    await _showQrPopup();
  }

  String _safeFileName(String input) {
    final sanitized = input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return sanitized.isEmpty ? 'student' : sanitized;
  }

  Future<Uint8List?> _captureQrPng() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<String?> _saveQrAsJpeg() async {
    if (_qrData == null || _qrNameFull == null) return null;
    final pngBytes = await _captureQrPng();
    if (pngBytes == null) return null;
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return null;
    final jpgBytes = img.encodeJpg(decoded, quality: 90);
    final name = _safeFileName(_qrNameFull!);
    final fileName = "qr_$name.jpg";
    saveBytes(
      bytes: Uint8List.fromList(jpgBytes),
      fileName: fileName,
      mimeType: 'image/jpeg',
    );

    return fileName;
  }

  Future<void> _copyQrCode() async {
    if (_qrData == null) return;
    await Clipboard.setData(ClipboardData(text: _qrData!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR code copied.")),
    );
  }

  Future<void> _showQrPopup() async {
    if (_qrData == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF0E1426) : Colors.white,
          titleTextStyle: TextStyle(
            color: isDark ? const Color(0xFFEAF7FF) : const Color(0xFF107C42),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: isDark ? const Color(0xFFC8E6F5) : const Color(0xFF3C3C3C),
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(child: Text("QR Generated")),
          content: RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _qrFirstName ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  QrImageView(data: _qrData!, size: 200),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  Expanded(
                    child: MenuButton(
                      height: 44,
                      label: "Save JPG",
                      onPressed: () async {
                        final path = await _saveQrAsJpeg();
                        if (!context.mounted) return;
                        if (path == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to save QR image."),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Downloaded $path")),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MenuButton(
                      height: 44,
                      label: "Copy Code",
                      onPressed: _copyQrCode,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      hintText: "Lastname, Firstname, Middle Initial",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MenuButton(
                    width: 200,
                    height: 56,
                    label: "Generate QR",
                    onPressed: _generateQR,
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
