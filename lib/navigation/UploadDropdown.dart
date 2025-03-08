import 'dart:ui'; // For blur effect
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:horz/theme/themeProvider.dart';

class UploadDropdown extends StatelessWidget {
  final VoidCallback onUploadResume;

  const UploadDropdown({super.key, required this.onUploadResume});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    return PopupMenuButton<int>(
      onSelected: (value) {
        if (value == 1) {
          onUploadResume();
        }
      },
      icon: Icon(
        LineIcons.plusCircle,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      offset: const Offset(0, 45),
      color: isDarkMode
          ? Colors.black.withOpacity(0.85)
          : Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 10,
      itemBuilder: (context) => [
        _buildMenuItem(
          LineIcons.file,
          "Upload Resume",
          Colors.lightBlueAccent,
          isDarkMode ? Colors.white : Colors.black87,
          true,
        ),
      ],
    );
  }

  PopupMenuItem<int> _buildMenuItem(
    IconData icon,
    String text,
    Color iconColor,
    Color textColor,
    bool isEnabled,
  ) {
    return PopupMenuItem<int>(
      value: isEnabled ? 1 : null,
      enabled: isEnabled,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
