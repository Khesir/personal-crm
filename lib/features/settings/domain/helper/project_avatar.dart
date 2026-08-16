import 'package:flutter/material.dart';

/// Derives a stable, distinct-looking color for a project from its (stable)
/// [id] — a fixed-hue-by-hashcode approach, no external color library. Used
/// as the fallback avatar background wherever a project has no icon set.
Color projectAvatarColor(String id) {
  final hue = (id.hashCode.abs() % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();
}

/// Derives 1-2 uppercase initials from a project's display [name]. Used as
/// the fallback avatar content wherever a project has no icon set.
String projectAvatarInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final word = words.first;
    return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}
