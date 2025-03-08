import 'package:flutter/material.dart';
import 'package:horz/pages/cvMaker/resume%20_catagory3.dart';
import 'package:horz/pages/cvMaker/resume_catagory2.dart';
import 'resume_templates_carousel.dart';
import 'resume_creators_section.dart';
import 'resume_category.dart';

class ResumeSocialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 120), // Top spacing

            ResumeTemplatesCarousel(),

            const SizedBox(height: 20),

            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 50 : 16),
                child: Container(
                  width: isWeb ? 500 : double.infinity,
                  child: SearchBar(),
                ),
              ),
            ),
            const SizedBox(height: 30),

            CommunitiesSection(),
            const SizedBox(height: 30),

            ResumeCategory1(title: "Software Engineering"),
            ResumeCategory2(title: "Trending Resumes"),
            ResumeCategory3(title: "Featured Resumes"),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// 🔹 Responsive Search Bar Widget
class SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search for resumes...",
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
