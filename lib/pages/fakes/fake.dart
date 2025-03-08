import 'package:flutter/material.dart';
import 'package:horz/markdown_renderer.dart';
import 'package:horz/pages/fakes/CheckWithAIPage.dart';
import 'package:horz/pages/fakes/report_fake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class FakePage extends StatefulWidget {
  const FakePage({super.key});

  @override
  State<FakePage> createState() => _FakePageState();
}

class _FakePageState extends State<FakePage> {
  final TextEditingController _controller = TextEditingController();
  String _result = "";
  List<String> _experiences = [];
  int _reportCount = 0;

  Future<void> _checkInternship() async {
    final company = _controller.text.trim().toLowerCase();
    if (company.isEmpty) {
      setState(() {
        _result = "Enter an internship name.";
        _experiences = [];
        _reportCount = 0;
      });
      return;
    }

    final response = await Supabase.instance.client
        .from('fake_internships')
        .select()
        .ilike('company_name', company) // Case-insensitive lookup
        .maybeSingle();

    if (response != null) {
      setState(() {
        _reportCount = response['report_count'];
        _experiences = List<String>.from(response['experiences']);
        _result = "⚠ Reported $_reportCount times.";
      });
    } else {
      setState(() {
        _result = "✅ No reports found for this company.";
        _experiences = [];
      });
    }
  }

  final List<Map<String, String>> awarenessPosts = [
    {
      "title": "🚩 How to Identify Fake Internships",
      "content": """
- **They ask for upfront payments** 💰  
- **No company website or social media presence** ❌  
- **Unrealistic promises (Guaranteed certificates from MNCs)** 🎭  
- **Suspicious email domains (e.g., xyz@gmail.com instead of @company.com)** 📧  
- **Vague job descriptions with no real responsibilities** 🕵️‍♂️  
"""
    },
    {
      "title": "🔍 How to Verify a Company’s Legitimacy",
      "content": """
- **Check their LinkedIn page & employee profiles** 🔗  
- **Look for official domain emails (@company.com)** 📩  
- **Search for online reviews or complaints** 🔎  
- **Avoid companies that demand personal info upfront** 🚫  
- **Ask for a contract before starting the internship** 📜  
"""
    },
    {
      "title": "⚠️ Red Flags in Job Offers",
      "content": """
- **Job offer received without an interview** ❌  
- **Too good to be true salary for beginners** 💰  
- **Poorly written emails with grammar errors** 📩  
- **Vague job descriptions with no real duties** 🕵️‍♂️  
- **HR only communicates via WhatsApp/Telegram** 📱  
"""
    }
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final inputFieldColor = isDark ? Colors.grey[900] : Colors.grey[200];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final positiveColor = isDark ? Colors.greenAccent[400] : Colors.green;
    final negativeColor = isDark ? Colors.redAccent[400] : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "SCAM SHIELD",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true, // Ensures title is perfectly centered
        iconTheme: IconThemeData(color: textColor, size: 24),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      backgroundColor: backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "Enter Internship Name",
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: inputFieldColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon:
                        Icon(Icons.search, color: textColor.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: positiveColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _checkInternship,
                            child: const Text("Check"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportFakePage(),
                              ),
                            ),
                            child: const Text("Report"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // Space between rows
                    SizedBox(
                      width: double.infinity, // Full-width button
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CheckWithAIPage(), // Navigating to AI Page
                          ),
                        ),
                        child: const Text("Check with AI"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _reportCount > 0
                        ? negativeColor!.withOpacity(0.2)
                        : positiveColor!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            _reportCount > 0 ? negativeColor! : positiveColor!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _reportCount > 0
                                ? negativeColor
                                : positiveColor),
                      ),
                      if (_experiences.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text("User Experiences:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _experiences.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text("- ${_experiences[index]}",
                                  style: TextStyle(color: textColor)),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                for (var post in awarenessPosts)
                  CustomMarkdown(
                      markdownText: "### ${post['title']}\n${post['content']}"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
