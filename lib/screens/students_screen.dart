import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../database/db_helper.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/menu_button.dart';
import '../utils/file_saver.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen>
    with SingleTickerProviderStateMixin {
  final Map<int, GlobalKey> _qrKeys = {};
  List<Student> _students = [];
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;
  late final AnimationController _searchControllerAnim;
  late final Animation<Offset> _searchSlide;

  @override
  void initState() {
    super.initState();
    _searchControllerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _searchSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _searchControllerAnim,
      curve: Curves.easeOut,
    ));
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final data = await DBHelper.getStudents();
    data.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      _students = data;
    });
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      _searchControllerAnim.forward();
    } else {
      _searchControllerAnim.reverse();
      _searchController.clear();
    }
  }

  void _handleBack() {
    if (_searchOpen) {
      _toggleSearch();
      return;
    }
    Navigator.of(context).maybePop();
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
  }

  String _firstNameFromFull(String fullName) {
    final parts = fullName.split(',').map((p) => p.trim()).toList();
    if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
    return fullName;
  }

  String _safeFileName(String input) {
    final sanitized = input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return sanitized.isEmpty ? 'student' : sanitized;
  }

  Future<Uint8List?> _captureQrPng(int id) async {
    final boundary =
        _qrKeys[id]?.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<String?> _saveQrAsJpeg(Student student) async {
    final pngBytes = await _captureQrPng(student.id!);
    if (pngBytes == null) return null;
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return null;
    final jpgBytes = img.encodeJpg(decoded, quality: 90);
    final name = _safeFileName(student.name);
    final fileName = "qr_$name.jpg";
    saveBytes(
      bytes: Uint8List.fromList(jpgBytes),
      fileName: fileName,
      mimeType: 'image/jpeg',
    );
    return fileName;
  }

  Future<void> _copyQrCode(Student student) async {
    await Clipboard.setData(ClipboardData(text: student.qrCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR code copied.")),
    );
  }

  Map<String, String>? _parseFullName(String input) {
    final parts = input.split(',').map((p) => p.trim()).toList();
    if (parts.length < 3) return null;
    return {
      'last': parts[0],
      'first': parts[1],
      'middle': parts[2],
    };
  }

  Future<void> _editStudent(Student student) async {
    final controller = TextEditingController(text: student.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final updatedName = await showDialog<String>(
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
          title: const Text("Edit Name"),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? const Color(0xFFEAF7FF) : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: "Full Name",
              hintText: "Lastname, Firstname, Middle Initial",
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF9ADFE0) : Colors.black54,
              ),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF7FB8C9) : Colors.black45,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (updatedName == null || updatedName.isEmpty) return;
    if (_parseFullName(updatedName) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Use format: Lastname, Firstname, Middle Initial"),
        ),
      );
      return;
    }

    await DBHelper.updateStudentName(student.id!, updatedName);
    if (!mounted) return;
    await _loadStudents();
  }

  Future<void> _deleteStudent(Student student) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldDelete = await showDialog<bool>(
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
          title: const Text("Delete Student"),
          content: Text(
            "Delete ${student.name}? This will remove the student and their logs.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    await DBHelper.deleteAttendanceForStudent(student.id!);
    await DBHelper.deleteStudent(student.id!);
    await _loadStudents();
  }

  void _showQrSheet(Student student) {
    final id = student.id!;
    _qrKeys.putIfAbsent(id, () => GlobalKey());
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0B1E4B)
          : const Color(0xFFE6E6E6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _qrKeys[id],
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _firstNameFromFull(student.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      QrImageView(data: student.qrCode, size: 200),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MenuButton(
                    width: 140,
                    height: 50,
                    label: "Save JPG",
                    onPressed: () async {
                      final path = await _saveQrAsJpeg(student);
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
                  const SizedBox(width: 12),
                  MenuButton(
                    width: 140,
                    height: 50,
                    label: "Copy Code",
                    onPressed: () => _copyQrCode(student),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchControllerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _toggleSearch,
          icon: const HugeIcon(
            icon: HugeIconsStrokeRounded.search01,
            color: Color(0xFFEAF7FF),
            size: 22,
          ),
        ),
        title: Stack(
          alignment: Alignment.centerRight,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Students"),
            ),
            if (_searchOpen)
              SlideTransition(
                position: _searchSlide,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HugeBackButton(onPressed: _handleBack),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: appBackgroundDecoration(context),
        child: SafeArea(
          child: _filteredStudents.isEmpty
              ? const Center(child: Text("No students yet.")) 
              : ListView.separated(
                  itemCount: _filteredStudents.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: Color(0xFF1E3A60),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    return ListTile(
                      title: Text(
                        student.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            tooltip: "View QR",
                            icon: const HugeIcon(
                              icon: HugeIconsStrokeRounded.qrCode,
                              color: Color(0xFFEAF7FF),
                              size: 22,
                            ),
                            onPressed: () => _showQrSheet(student),
                          ),
                          IconButton(
                            tooltip: "Edit Name",
                            icon: const HugeIcon(
                              icon: HugeIconsStrokeRounded.edit02,
                              color: Color(0xFFEAF7FF),
                              size: 22,
                            ),
                            onPressed: () => _editStudent(student),
                          ),
                          IconButton(
                            tooltip: "Delete",
                            icon: const HugeIcon(
                              icon: HugeIconsStrokeRounded.delete02,
                              color: Color(0xFFEAF7FF),
                              size: 22,
                            ),
                            onPressed: () => _deleteStudent(student),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
