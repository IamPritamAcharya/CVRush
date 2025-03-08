import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        fontFamily: 'ProductSans',
        scaffoldBackgroundColor: Color(0xFFF7F8FA),
        primaryColor: Colors.black,
        cardColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ProductSans',
        scaffoldBackgroundColor: const Color(0xFF191B1A),
        primaryColor: Colors.white,
        cardColor: const Color(0xFF1A1D1E),
        shadowColor: Colors.white.withOpacity(0.2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1D1E),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF191B1A),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      );
}
