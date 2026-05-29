import 'package:flutter/material.dart';

class AppTheme {
  // Knowledge Points amber
  static const kpBg = Color(0xFFFAEEDA);
  static const kpText = Color(0xFF633806);

  // Avatar palette (background color hex strings mapped to Color)
  static Color hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  static Color avatarTextColor(String bgHex) {
    final colors = {
      '#E6F1FB': const Color(0xFF0C447C),
      '#E1F5EE': const Color(0xFF085041),
      '#FBEAF0': const Color(0xFF72243E),
      '#EAF3DE': const Color(0xFF27500A),
      '#EEEDFE': const Color(0xFF3C3489),
      '#FAECE7': const Color(0xFF712B13),
      '#FAEEDA': const Color(0xFF633806),
    };
    return colors[bgHex] ?? Colors.black87;
  }

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFFF8F9FA),
      surfaceTintColor: Colors.transparent,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  );

  // Status colors
  static Color statusBg(String status) {
    switch (status) {
      case 'open':
      case 'draft':
        return const Color(0xFFE6F1FB);
      case 'pending':
      case 'assigned':
        return const Color(0xFFFAEEDA);
      case 'confirmed':
        return const Color(0xFFE1F5EE);
      case 'completed':
        return const Color(0xFFEAF3DE);
      case 'cancelled':
        return const Color(0xFFFFEBEB);
      default:
        return const Color(0xFFF1EFE8);
    }
  }

  static Color statusText(String status) {
    switch (status) {
      case 'open':
      case 'draft':
        return const Color(0xFF0C447C);
      case 'pending':
      case 'assigned':
        return const Color(0xFF633806);
      case 'confirmed':
        return const Color(0xFF085041);
      case 'completed':
        return const Color(0xFF27500A);
      case 'cancelled':
        return const Color(0xFF791F1F);
      default:
        return const Color(0xFF444441);
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Buka';
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
