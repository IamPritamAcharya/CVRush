import 'dart:math';
import 'package:flutter/material.dart';
import 'package:horz/pages/jobs/jobdeatils.dart';
import 'package:horz/pages/jobs/jobmodel.dart';
import 'package:line_icons/line_icons.dart';

class JobCard extends StatefulWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  _JobCardState createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  late PageController _pageController;
  int _currentPage = 0;
  late Color randomColor;

  @override
  void initState() {
    super.initState();
    // Define a list of colors to choose from.
    final randomColors = [
      const Color(0xFFEDE7F6),
      const Color(0xFFC5CAE9),
      const Color(0xFFBBDEFB),
      const Color(0xFFFFCDD2),
      const Color(0xFFDCE775),
      const Color(0xFFF8BBD0),
      const Color(0xFFB2EBF2),
      const Color(0xFFFFE0B2),
      const Color(0xFFFFF9C4),
      const Color(0xFFD1C4E9),
      const Color(0xFFDCEDC8),
      const Color(0xFFFFF3E0),
      const Color(0xFFF5F5F5),
      const Color(0xFFE1F5FE),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFECB3),
      const Color(0xFFB3E5FC),
      const Color(0xFFCFD8DC),
    ];

    // Assign a random color from the list.
    final random = Random();
    randomColor = randomColors[random.nextInt(randomColors.length)];

    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => JobDetailPage(job: widget.job)),
      ),
      child: Container(
        decoration: BoxDecoration(
          // Use the randomly chosen color instead of Supabase color.
          color: randomColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row - Hourly Rate & Bookmark Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.job.rate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(LineIcons.bookmark, size: 18),
                ],
              ),
            ),

            /// Swipeable Showcase Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.job.showcase.length,
                      itemBuilder: (context, index) {
                        return Center(
                          child: Text(
                            widget.job.showcase[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),

                  /// Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.job.showcase.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: _currentPage == index ? 6 : 5,
                          height: _currentPage == index ? 6 : 5,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? Colors.black
                                : Colors.grey.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Bottom Section - Company & Arrow Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
                border: Border.all(color: Colors.grey.shade300, width: 0.7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Company Logo & Name
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          widget.job.logoUrl,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(LineIcons.image, size: 20);
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formatCompanyName(widget.job.company, 9),
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.black),
                      ),
                    ],
                  ),

                  /// Arrow Icon to Open Job Details
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                            true, // Allows full-screen height if needed
                        backgroundColor:
                            Colors.transparent, // For rounded corners
                        builder: (context) => JobDetailPage(job: widget.job),
                      );
                    },
                    icon: const Icon(LineIcons.arrowRight, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatCompanyName(String name, int maxLength) {
    return name.length > maxLength
        ? '${name.substring(0, maxLength)}...'
        : name;
  }
}
