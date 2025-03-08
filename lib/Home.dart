import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:horz/navigation/androidNavBar.dart';
import 'package:horz/navigation/custom_appbar.dart';
import 'package:horz/navigation/custom_drawer.dart';
import 'package:horz/pages/friendsPage.dart';
import 'package:horz/pages/jobs/jobLists.dart';
import 'package:horz/pages/resume/resume_swipe_page.dart';
import 'package:horz/signIn.dart';
import 'pages/cvMaker/resume_social_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isScrollingDown = false;

  final List<Widget> _pages = [
    ResumeSwipePage(),
    ResumeSocialPage(),
    JobListPage(),
    SignInPage(),
  ];

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onScroll(bool scrollingDown) {
    setState(() {
      _isScrollingDown = scrollingDown;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> scrollAwarePages = _pages.map((page) {
      return NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            _onScroll(true);
          } else if (notification.direction == ScrollDirection.forward) {
            _onScroll(false);
          }
          return false;
        },
        child: page,
      );
    }).toList();

    return Scaffold(
      drawer: CustomDrawer(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: scrollAwarePages,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isScrollingDown ? -(kToolbarHeight + 60) : 0,
            left: 0,
            right: 0,
            child: CustomAppBar(
              onDrawerOpen: () => Scaffold.of(context).openDrawer(),
              onPageChange: _onTabChange, // Update content via callback
            ),
          ),
          if (!kIsWeb &&
              !Platform.isWindows) // Bottom NavBar for non-Web/Windows
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _isScrollingDown ? -100 : 10,
              left: 0,
              right: 0,
              child: CustomNavBar(
                selectedIndex: _selectedIndex,
                onTabChange: _onTabChange,
              ),
            ),
        ],
      ),
    );
  }
}
