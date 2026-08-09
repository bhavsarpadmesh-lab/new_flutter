import 'package:flutter/material.dart';
import '../theme/riso.dart';

/// Categories are inks. Each one maps to a riso colour that carries through
/// the tag, the ribbon and the streak count for that habit.
class CategoryIcons {
  static const List<String> all = [
    'Health',
    'Work',
    'Personal',
    'Finance',
    'Other',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.favorite_outlined;
      case 'Work':
        return Icons.work_outlined;
      case 'Personal':
        return Icons.person_outlined;
      case 'Finance':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case 'Health':
        return Riso.pink;
      case 'Work':
        return Riso.blue;
      case 'Personal':
        return Riso.orange;
      case 'Finance':
        return Riso.green;
      default:
        return Riso.ink;
    }
  }
}
