import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF0C0C0E);
  static const titlebarBackground = Color(0xFF1A1A1D);
  static const surface = Color(0xFF0E0E10);
  static const surfaceElevated = Color(0xFF161619);
  static const surfaceRaised = Color(0xFF1C1C20);
  static const kanbanColumnBackground = Color(0x05FFFFFF);

  // Borders
  static const border = Color(0x12FFFFFF);
  static const borderStrong = Color(0x21FFFFFF);

  // Text scale
  static const textPrimary = Color(0xFFEDEDEE);
  static const textSecondary = Color(0xFF9A9AA2);
  static const textTertiary = Color(0xFF65656D);
  static const textFaint = Color(0xFF46464D);
  static const textMuted = textTertiary;

  // Accent
  static const accent = Color(0xFF8B7FF5);
  static const accentLight = Color(0xFFA99DFF);
  static const accentBg = Color(0x298B7FF5);
  static const accentLine = Color(0x4D8B7FF5);

  // Status (Kanban columns)
  static const statusBacklog = Color(0xFF8A8A93);
  static const statusReady = Color(0xFF5B8DEF);
  static const statusInProgress = Color(0xFFE0A23C);
  static const statusQa = Color(0xFFF0816A);
  static const statusDone = Color(0xFF3FB98F);

  // Severity (Bug Reports)
  static const severityInfo = Color(0xFF5B8DEF);
  static const severityWarning = Color(0xFFE0A23C);
  static const severityError = Color(0xFFF0816A);
  static const severityCritical = Color(0xFFE5484D);

  // General-purpose semantic colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Legacy: retained until the keep_track feature's announcement-related
  // code is moved into the projects feature (slice 007/012).
  static const accentKeepTrack = Color(0xFF14B8A6);
}
