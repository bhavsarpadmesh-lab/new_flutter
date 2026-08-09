import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/habit_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/riso.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const HabitLedgerApp());
}

class HabitLedgerApp extends StatelessWidget {
  const HabitLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return ChangeNotifierProvider(
      create: (context) => HabitProvider()..fetchHabits(),
      child: MaterialApp(
        title: 'Habit Ledger',
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Riso.pink,
        primary: Riso.pink,
        surface: Riso.paper,
        onSurface: Riso.ink,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Riso.paper,
      splashColor: Riso.ink.withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Riso.ink,
        thickness: 1.5,
        space: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Riso.pink,
        selectionHandleColor: Riso.pink,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Riso.paper,
        dialBackgroundColor: Riso.paper3,
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Riso.ink,
        contentTextStyle: RisoType.mono(color: Riso.paper, size: 11),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
