import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

class DBHelper {
  static const _studentsKey = 'students';
  static const _attendanceKey = 'attendance';
  static const _studentIdKey = 'student_id_counter';
  static const _attendanceIdKey = 'attendance_id_counter';

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  static Future<void> _writeList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<int> _nextId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(key) ?? 0;
    final next = current + 1;
    await prefs.setInt(key, next);
    return next;
  }

  static Future<int> addStudent(Student student) async {
    final students = await _readList(_studentsKey);
    final id = await _nextId(_studentIdKey);
    student.id = id;
    students.add(student.toMap());
    await _writeList(_studentsKey, students);
    return id;
  }

  static Future<int> logAttendance(int studentId, String type) async {
    final attendance = await _readList(_attendanceKey);
    final id = await _nextId(_attendanceIdKey);
    attendance.add({
      'id': id,
      'studentId': studentId,
      'type': type,
      'dateTime': DateTime.now().toIso8601String(),
    });
    await _writeList(_attendanceKey, attendance);
    return id;
  }

  static Future<Student?> getStudentByQrCode(String qrCode) async {
    final students = await _readList(_studentsKey);
    final match =
        students.firstWhere((s) => s['qrCode'] == qrCode, orElse: () => {});
    if (match.isEmpty) return null;
    return Student.fromMap(match);
  }

  static Future<List<Map<String, dynamic>>> getAttendanceForStudentInRange(
    int studentId,
    String startIso,
    String endIso,
  ) async {
    final attendance = await _readList(_attendanceKey);
    final start = DateTime.tryParse(startIso);
    final end = DateTime.tryParse(endIso);
    if (start == null || end == null) return [];
    final rows = attendance.where((row) {
      if (row['studentId'] != studentId) return false;
      final dt = DateTime.tryParse(row['dateTime']?.toString() ?? '');
      if (dt == null) return false;
      return !dt.isBefore(start) && dt.isBefore(end);
    }).toList();
    rows.sort((a, b) {
      final ad = DateTime.tryParse(a['dateTime']?.toString() ?? '');
      final bd = DateTime.tryParse(b['dateTime']?.toString() ?? '');
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return rows;
  }

  static Future<List<Student>> getStudents() async {
    final students = await _readList(_studentsKey);
    return students.map((e) => Student.fromMap(e)).toList();
  }

  static Future<int> updateStudentName(int id, String name) async {
    final students = await _readList(_studentsKey);
    final idx = students.indexWhere((s) => s['id'] == id);
    if (idx == -1) return 0;
    students[idx]['name'] = name;
    await _writeList(_studentsKey, students);
    return 1;
  }

  static Future<int> deleteStudent(int id) async {
    final students = await _readList(_studentsKey);
    final before = students.length;
    students.removeWhere((s) => s['id'] == id);
    await _writeList(_studentsKey, students);
    return before - students.length;
  }

  static Future<int> deleteAttendanceForStudent(int studentId) async {
    final attendance = await _readList(_attendanceKey);
    final before = attendance.length;
    attendance.removeWhere((a) => a['studentId'] == studentId);
    await _writeList(_attendanceKey, attendance);
    return before - attendance.length;
  }

  static Future<List<Map<String, dynamic>>> getAttendance() async {
    final attendance = await _readList(_attendanceKey);
    final students = await _readList(_studentsKey);
    final studentById = {
      for (final s in students) s['id'] as int: s,
    };
    final rows = attendance.map((a) {
      final student = studentById[a['studentId']] ?? {};
      return {
        'id': a['id'],
        'studentId': a['studentId'],
        'name': student['name'],
        'qrCode': student['qrCode'],
        'type': a['type'],
        'dateTime': a['dateTime'],
      };
    }).toList();
    rows.sort((a, b) {
      final ad = DateTime.tryParse(a['dateTime']?.toString() ?? '');
      final bd = DateTime.tryParse(b['dateTime']?.toString() ?? '');
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return rows;
  }

  static Future<int> clearAttendance() async {
    await _writeList(_attendanceKey, []);
    return 1;
  }
}
