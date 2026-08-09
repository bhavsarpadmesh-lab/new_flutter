import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Risograph ink system for Habit Ledger.
///
/// The premise: habit tracking is repetition building density, and riso
/// printing works the same way — each pass lays down more ink. Categories are
/// inks, not decorations. Colour is earned; an empty streak stays grey.
class Riso {
  Riso._();

  // Stock
  static const paper = Color(0xFFD9D5C8);
  static const paper2 = Color(0xFFCEC9B9);
  static const paper3 = Color(0xFFC2BCA9);

  // Inks
  static const ink = Color(0xFF16150F);
  static const pink = Color(0xFFFF3D9A);
  static const blue = Color(0xFF0A6EBD);
  static const orange = Color(0xFFFF6B2C);
  static const green = Color(0xFF00A05A);

  // Text tiers
  static const muted = Color(0xFF6E6959);
  static const bodyInk = Color(0xFF4A4638);

  static const gutter = 20.0;
}

/// Three type roles, no ambiguity about which is which:
/// display for anything that matters, body for reading, mono for data.
class RisoType {
  RisoType._();

  static TextStyle display({
    double size = 20,
    FontWeight weight = FontWeight.w800,
    Color color = Riso.ink,
    double letterSpacing = -0.6,
    double? height,
  }) {
    return GoogleFonts.getFont(
      'Bricolage Grotesque',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = Riso.bodyInk,
    double? height,
  }) {
    return GoogleFonts.getFont(
      'Archivo',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w400,
    Color color = Riso.muted,
    double letterSpacing = 1.6,
  }) {
    return GoogleFonts.getFont(
      'DM Mono',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
