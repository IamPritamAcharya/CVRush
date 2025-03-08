import 'package:flutter/material.dart';
import 'package:horz/pages/cvMaker/webview.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumeCategory1 extends StatelessWidget {
  final String title;
  ResumeCategory1({required this.title});

  final List<Map<String, String>> categoryItems = [
    {
      "title": "Microsoft",
      "image":
          "https://www.freecodecamp.org/news/content/images/2020/03/1_software_resume_tk-1.jpg",
      "url":
          "https://www.overleaf.com/latex/templates/deedy-resume-reversed/hqnwfgjbbddt"
    },
    {
      "title": "Google",
      "image":
          "https://miro.medium.com/v2/resize:fit:1400/1*f9gDJe0--0G6hSAYIwKQ5w.png",
      "url":
          "https://www.overleaf.com/latex/templates/rendercv-engineeringresumes-theme/shwqvsxdgkjy"
    },
    {
      "title": "Explore Intern",
      "image": "https://gdoc.io/uploads/resume6-376x520.webp",
      "url":
          "https://www.overleaf.com/latex/templates/rendercv-engineeringresumes-theme/shwqvsxdgkjy"
    },
    {
      "title": "Data Science",
      "image":
          "https://resumeworded.com/assets/images/resume-guides/data-scientist.png",
      "url":
          "https://www.overleaf.com/latex/templates/rendercv-engineeringresumes-theme/shwqvsxdgkjy"
    },
  ];

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categoryItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewPage(
                      url: categoryItems[index]["url"]!,
                      title: categoryItems[index]["title"]!,
                    ),
                  ),
                ),
                child: ResumeCard(
                  title: categoryItems[index]["title"]!,
                  image: categoryItems[index]["image"]!,
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class ResumeCard extends StatelessWidget {
  final String title;
  final String image;

  const ResumeCard({required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              image,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 220,
                color: Colors.grey[400],
                child: const Icon(Icons.broken_image,
                    size: 40, color: Colors.white),
              ),
            ),
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
