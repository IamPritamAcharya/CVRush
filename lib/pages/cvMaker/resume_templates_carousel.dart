import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:horz/pages/cvMaker/ResumeDetailPage.dart';

class ResumeTemplatesCarousel extends StatelessWidget {
  static const double mobileHeight = 180;
  static const double webHeight = 440;

  final List<Map<String, dynamic>> templates = [
    {
      "title": "Striver",
      "image": "https://i.ytimg.com/vi/heg7PiSOT50/maxresdefault.jpg",
      "videoUrl": "https://www.youtube.com/watch?v=heg7PiSOT50",
      "description": "# Modern Resume\nA sleek and professional template...",
      "likes": 20,
      "dislikes": 3
    },
    {
      "title": "Creative CV",
      "image": "https://i.ytimg.com/vi/6KlPe035d4o/hq720.jpg",
      "videoUrl": "https://www.youtube.com/watch?v=6KlPe035d4o",
      "description": "# Creative CV\nA stylish and creative approach...",
      "likes": 15,
      "dislikes": 2
    },
    {
      "title": "Minimalist Design",
      "image": "https://i.ytimg.com/vi/WZ6ZhiCg2_Q/maxresdefault.jpg",
      "videoUrl": "https://www.youtube.com/watch?v=WZ6ZhiCg2_Q",
      "description": "# Minimalist Design\nA clean and simple layout...",
      "likes": 25,
      "dislikes": 5
    },
    {
      "title": "Resume Template",
      "image": "https://i.ytimg.com/vi/APF0w9PSDr8/maxresdefault.jpg",
      "videoUrl": "https://youtu.be/APF0w9PSDr8?si=5dtpXXDnuOke8PoP",
      "description":
          "*Learn How to Make a Professional Resume in Minutes!* Are you struggling to create a resume that stands out?",
      "likes": 20,
      "dislikes": 3
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        bool isWeb = screenWidth > 600;

        return Center(
          child: CarouselSlider(
            options: CarouselOptions(
              height: isWeb ? webHeight : mobileHeight,
              autoPlay: true,
              enlargeCenterPage: true,
              autoPlayInterval: Duration(seconds: 5),
              viewportFraction: isWeb ? 0.7 : 0.9,
              enlargeStrategy: CenterPageEnlargeStrategy.scale,
            ),
            items: templates.map((item) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResumeDetailPage(
                        title: item["title"]!,
                        videoUrl: item["videoUrl"]!,
                        description: item["description"]!,
                        likes: item["likes"]!,
                        dislikes: item["dislikes"]!,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            item["image"]!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Text(
                            item["title"]!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWeb ? 20 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
