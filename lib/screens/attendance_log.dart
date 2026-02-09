import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel;
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/menu_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../utils/file_saver.dart';

class AttendanceLog extends StatefulWidget {
  const AttendanceLog({super.key});

  @override
  State<AttendanceLog> createState() => _AttendanceLogState();
}

class _AttendanceLogState extends State<AttendanceLog> {
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    final data = await DBHelper.getAttendance();
    setState(() => _logs = data);
  }

  Future<void> _confirmClearLogs() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldClear = await showDialog<bool>(
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
          title: const Text("Clear Logs"),
          content: const Text("Are you sure you want to clear all logs?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;
    await DBHelper.clearAttendance();
    _loadLogs();
  }

  List<Map<String, dynamic>> _buildDailyRows() {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final log in _logs) {
      final studentId = log['studentId']?.toString() ?? '';
      final name = log['name']?.toString() ?? '';
      final dateTime = DateTime.tryParse(log['dateTime']?.toString() ?? '');
      if (studentId.isEmpty || dateTime == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
      final key = "$studentId|$dateKey";

      grouped.putIfAbsent(key, () {
        return {
          'name': name,
          'date': DateTime(dateTime.year, dateTime.month, dateTime.day),
          'amIn': null,
          'amOut': null,
          'pmIn': null,
          'pmOut': null,
        };
      });

      final type = log['type']?.toString() ?? '';
      if (type == 'AM In') {
        final existing = grouped[key]!['amIn'] as DateTime?;
        if (existing == null || dateTime.isBefore(existing)) {
          grouped[key]!['amIn'] = dateTime;
        }
      } else if (type == 'AM Out') {
        final existing = grouped[key]!['amOut'] as DateTime?;
        if (existing == null || dateTime.isAfter(existing)) {
          grouped[key]!['amOut'] = dateTime;
        }
      } else if (type == 'PM In') {
        final existing = grouped[key]!['pmIn'] as DateTime?;
        if (existing == null || dateTime.isBefore(existing)) {
          grouped[key]!['pmIn'] = dateTime;
        }
      } else if (type == 'PM Out') {
        final existing = grouped[key]!['pmOut'] as DateTime?;
        if (existing == null || dateTime.isAfter(existing)) {
          grouped[key]!['pmOut'] = dateTime;
        }
      }
    }

    final rows = grouped.values.toList();
    rows.sort((a, b) {
      final ad = a['date'] as DateTime?;
      final bd = b['date'] as DateTime?;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return rows;
  }

  void _exportExcel() async {
    var workbook = excel.Excel.createExcel();
    var sheet = workbook['Attendance'];
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }
    sheet.setColumnWidth(0, 20.8);
    sheet.setColumnWidth(1, 10.8);
    sheet.setColumnWidth(2, 10.7);
    sheet.setColumnWidth(3, 10.7);
    sheet.setColumnWidth(4, 10.6);
    sheet.setColumnWidth(5, 16.8);

    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel.TextCellValue("NAME"),
    );
    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
      excel.TextCellValue("MORNING"),
    );
    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
      excel.TextCellValue("AFTERNOON"),
    );
    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
      excel.TextCellValue("DATE"),
    );

    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      excel.TextCellValue("TIME IN"),
    );
    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1),
      excel.TextCellValue("TIME OUT"),
    );
    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
      excel.TextCellValue("TIME IN"),
    );
    sheet.updateCell(
      excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1),
      excel.TextCellValue("TIME OUT"),
    );

    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
    );
    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
      excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
    );
    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
      excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
    );
    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
      excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1),
    );

    final rows = _buildDailyRows();
    int rowIndex = 2;
    for (var row in rows) {
      final name = row['name']?.toString() ?? '';
      final amIn = row['amIn'] as DateTime?;
      final amOut = row['amOut'] as DateTime?;
      final pmIn = row['pmIn'] as DateTime?;
      final pmOut = row['pmOut'] as DateTime?;
      final date = row['date'] as DateTime?;
      sheet.updateCell(
        excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        excel.TextCellValue(name),
      );
      sheet.updateCell(
        excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        excel.TextCellValue(amIn == null ? "" : DateFormat('hh:mm a').format(amIn)),
      );
      sheet.updateCell(
        excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        excel.TextCellValue(amOut == null ? "" : DateFormat('hh:mm a').format(amOut)),
      );
      sheet.updateCell(
        excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        excel.TextCellValue(pmIn == null ? "" : DateFormat('hh:mm a').format(pmIn)),
      );
      sheet.updateCell(
        excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        excel.TextCellValue(pmOut == null ? "" : DateFormat('hh:mm a').format(pmOut)),
      );
      sheet.updateCell(
        excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
        excel.TextCellValue(date == null ? "" : DateFormat('MMMM d, yyyy').format(date)),
      );
      rowIndex += 1;
    }

    final fileName =
        "Attendance (${DateFormat('MMMM d, yyyy hh-mm-ss a').format(DateTime.now())}).xlsx";
    final bytes = Uint8List.fromList(workbook.encode()!);
    saveBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Downloaded $fileName")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HugeBackButton(),
        title: const Text("Attendance Log"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: IconButton(
              onPressed: _confirmClearLogs,
              icon: const HugeIcon(
                icon: HugeIconsStrokeRounded.delete02,
                color: Color(0xFFEAF7FF),
                size: 22,
              ),
              tooltip: "Clear logs",
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: appBackgroundDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E3A60)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _HeaderCell(text: "NAME", flex: 3),
                          _HeaderCell(text: "MORNING", flex: 2),
                          _HeaderCell(text: "AFTERNOON", flex: 2),
                          _HeaderCell(text: "DATE", flex: 2),
                        ],
                      ),
                      const Divider(height: 1, color: Color(0xFF1E3A60)),
                      Row(
                        children: const [
                          _HeaderCell(text: "", flex: 3),
                          _HeaderCell(text: "TIME IN", flex: 1),
                          _HeaderCell(text: "TIME OUT", flex: 1),
                          _HeaderCell(text: "TIME IN", flex: 1),
                          _HeaderCell(text: "TIME OUT", flex: 1),
                          _HeaderCell(text: "", flex: 2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _buildDailyRows().length,
                  itemBuilder: (context, index) {
                    final row = _buildDailyRows()[index];
                    final name = row['name']?.toString() ?? '';
                    final amIn = row['amIn'] as DateTime?;
                    final amOut = row['amOut'] as DateTime?;
                    final pmIn = row['pmIn'] as DateTime?;
                    final pmOut = row['pmOut'] as DateTime?;
                    final date = row['date'] as DateTime?;
                    final amInLabel = amIn == null
                        ? '—'
                        : DateFormat('hh:mm a').format(amIn);
                    final amOutLabel = amOut == null
                        ? '—'
                        : DateFormat('hh:mm a').format(amOut);
                    final pmInLabel = pmIn == null
                        ? '—'
                        : DateFormat('hh:mm a').format(pmIn);
                    final pmOutLabel = pmOut == null
                        ? '—'
                        : DateFormat('hh:mm a').format(pmOut);
                    final dateLabel = date == null
                        ? ''
                        : DateFormat('MMMM d, yyyy').format(date);
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          _ValueCell(text: amInLabel, flex: 1),
                          _ValueCell(text: amOutLabel, flex: 1),
                          _ValueCell(text: pmInLabel, flex: 1),
                          _ValueCell(text: pmOutLabel, flex: 1),
                          _ValueCell(text: dateLabel, flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: MenuButton(
                  width: 220,
                  height: 56,
                  label: "Export to Excel",
                  onPressed: _exportExcel,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text, required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEAF7FF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.text, required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFC8E6F5)),
      ),
    );
  }
}
