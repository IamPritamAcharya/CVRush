import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color activeColor = isDark ? Colors.tealAccent : Colors.black;
    final Color inactiveColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final Color backgroundColor =
        isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6);
    final Color borderColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: borderColor, width: 0.5),
              color: backgroundColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: GNav(
              rippleColor: Colors.black12,
              hoverColor: Colors.black12,
              haptic: true,
              tabBorderRadius: 20,
              duration: const Duration(milliseconds: 200),
              gap: 6,
              color: inactiveColor,
              activeColor: activeColor,
              iconSize: 22,
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activeColor,
              ),
              tabBackgroundColor: activeColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              selectedIndex: selectedIndex,
              onTabChange: onTabChange,
              tabs: [
                GButton(
                  icon: LineIcons.file,
                  text: 'Swipe',
                  border: selectedIndex == 0
                      ? Border.all(color: activeColor, width: 1.2)
                      : null,
                ),
                GButton(
                  icon: LineIcons.edit,
                  text: 'Community',
                  border: selectedIndex == 1
                      ? Border.all(color: activeColor, width: 1.2)
                      : null,
                ),
                GButton(
                  icon: LineIcons.folderOpen,
                  text: 'Jobs',
                  border: selectedIndex == 2
                      ? Border.all(color: activeColor, width: 1.2)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
