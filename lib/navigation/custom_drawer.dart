import 'package:flutter/material.dart';
import 'package:horz/navigation/atsPage.dart';
import 'package:horz/navigation/premiumPage.dart';
import 'package:horz/pages/fakes/fake.dart';
import 'package:horz/pages/jobs/jobLists.dart';
import 'package:horz/pages/resume/resume_swipe_page.dart';
import 'package:horz/signIn.dart';
import 'package:provider/provider.dart';
import 'package:horz/theme/themeProvider.dart';
import 'package:line_icons/line_icons.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final bool isWebOrDesktop =
        Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS ||
            (Theme.of(context).platform == TargetPlatform.fuchsia &&
                MediaQuery.of(context).size.width > 600);

    final Color gradientStart = Colors.lightBlueAccent;
    final Color gradientEnd = Colors.blue;
    final Color drawerBg = isDarkMode ? const Color(0xFF1A1D1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color dividerColor = isDarkMode ? Colors.white10 : Colors.black12;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.04;

    final List<Map<String, dynamic>> menuItems = [
      {"icon": LineIcons.home, "title": "Home", "page": ResumeSwipePage()},
      {
        "icon": LineIcons.alternateSignIn,
        "title": "Sign In",
        "page": SignInPage()
      },
      {"divider": true},
      {
        "icon": LineIcons.chessKnight,
        "title": "ATS Score",
        "page": AtsPage(),
      },
      {
        "icon": LineIcons.userShield,
        "title": "Scam Shield",
        "page": FakePage()
      },
      {"divider": true},
      {"icon": LineIcons.moneyBill, "title": "Premium", "page": PremiumPage()},
      {"icon": LineIcons.cog, "title": "Settings", "page": ResumeSwipePage()},
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: Drawer(
        // Only apply a fixed width on web/desktop.
        width: isWebOrDesktop ? 400 : null,
        child: Container(
          color: drawerBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header with Gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  60,
                  horizontalPadding,
                  20,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(LineIcons.user,
                          color: Colors.white, size: 32),
                    ),
                    SizedBox(width: horizontalPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Pritam Acharya",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "pritamach@gmail.com",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Menu List
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: menuItems.length,
                  separatorBuilder: (_, index) {
                    return menuItems[index]["divider"] == true
                        ? Divider(color: dividerColor, thickness: 0.5)
                        : const SizedBox(height: 0);
                  },
                  itemBuilder: (context, index) {
                    if (menuItems[index]["divider"] == true) {
                      return const SizedBox.shrink();
                    }
                    return _AnimatedMenuItem(
                      delay: Duration(milliseconds: 70 * index),
                      child: _buildMenuItem(
                        context,
                        icon: menuItems[index]["icon"],
                        title: menuItems[index]["title"],
                        page: menuItems[index]["page"],
                        textColor: textColor,
                      ),
                    );
                  },
                ),
              ),
              // Dark Mode Switch
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isDarkMode ? 0 : 2,
                  color: isDarkMode ? const Color(0xFF252829) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dark Mode",
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: (value) =>
                              themeProvider.toggleTheme(value),
                          activeColor: Colors.white,
                          inactiveThumbColor: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Version & Logout
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // Handle logout action
                      },
                      icon: Icon(
                        LineIcons.alternateSignOut,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required Widget page,
      required Color textColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: Icon(icon, color: textColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}

class _AnimatedMenuItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedMenuItem({
    required this.child,
    required this.delay,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<_AnimatedMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(_fadeAnimation);

    // Delayed animation start
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
