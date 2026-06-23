import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.primary,
      ),
    );
  }
}

extension DateTimeX on DateTime {
  String get formatted => DateFormat('d MMM yyyy').format(this);
  String get shortFormatted => DateFormat('d MMM').format(this);
  String get timeFormatted => DateFormat('HH:mm').format(this);
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

extension DoubleX on double {
  String get asPercent => '${(this * 100).toStringAsFixed(1)}%';
  String get asScore => toStringAsFixed(1);
}

extension IntX on int {
  String get withCommas => NumberFormat('#,###').format(this);
}

extension StringX on String {
  String get capitalised => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => split(' ').map((w) => w.capitalised).join(' ');
}
