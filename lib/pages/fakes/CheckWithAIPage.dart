import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CheckWithAIPage extends StatefulWidget {
  const CheckWithAIPage({super.key});

  @override
  State<CheckWithAIPage> createState() => _CheckWithAIPageState();
}

class _CheckWithAIPageState extends State<CheckWithAIPage> {
  final TextEditingController _controller = TextEditingController();
  String _result = "Enter a message to check.";
  double _scamPercentage = 0;
  List<String> _reasons = [];
  bool _loading = false;

  final String _knownScamMessage = """
Hello Students

Corizo has collaboration with Top MNCs Companies [Wipro, IBM, Microsoft, Deloitte, Cognizant, Barclays, Infosys, Genpact, Oracle, etc.] and is organizing a Training and Internship program on multiple domains.

I invite all the students to the Internship Program by joining the below link.

Why Should You join it?
- Unlock Lucrative Job Opportunities
- Certification from Wipro
- MNC Internship Completion Certificates
- Hands-on Project Experience
- Resume Building & Mock Interviews
- Placement Assistance
""";

  Future<void> _analyzeWithAI() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) {
      setState(() {
        _result = "Please enter an internship message.";
        _scamPercentage = 0;
        _reasons = [];
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final prompt = """
Analyze the following message and determine if it resembles a known internship scam.

**Known Scam Message:**
$_knownScamMessage

**User Input:**
$userInput

### TASK:
1. Determine if the user message is similar to the known scam.
2. Provide a scam likelihood percentage (0-100).
3. List reasons why it may be a scam.

### RESPONSE FORMAT:
Return ONLY a JSON object with this format:
{
  "isScam": true/false,
  "scamLikelihood": number,
  "reasons": ["reason1", "reason2", "reason3"]
}
""";

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: '',
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final fullResponse = response.text ?? "";
      debugPrint("Full API response: $fullResponse");

      final jsonString = extractJsonFromText(fullResponse);
      if (jsonString.isEmpty) {
        throw Exception("No valid JSON found in response");
      }

      final jsonData = jsonDecode(jsonString);

      setState(() {
        _scamPercentage = (jsonData["scamLikelihood"] as num).toDouble();
        _reasons = List<String>.from(jsonData["reasons"]);

        if (_scamPercentage > 70) {
          _result = "⚠ Likely a Scam";
        } else if (_scamPercentage < 30) {
          _result = "✅ Seems Safe";
        } else {
          _result = "⚠ Uncertain – Proceed with Caution";
        }
      });
    } catch (e, stackTrace) {
      debugPrint("Error: $e\n$stackTrace");
      setState(() {
        _result = "Error analyzing message. Please try again.";
        _scamPercentage = 0;
        _reasons = [];
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String extractJsonFromText(String text) {
    final regex = RegExp(r'\{.*\}', dotAll: true);
    final match = regex.firstMatch(text);
    return match?.group(0) ?? "";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final bgColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[400];
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 3,
        titleSpacing: 16,
        iconTheme: IconThemeData(color: textColor, size: 24),
        backgroundColor: bgColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  style: TextStyle(fontSize: 16, color: textColor),
                  decoration: InputDecoration(
                    labelText: "Paste Internship Message Here",
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? Colors.blueGrey[400]!
                              : Colors.blueGrey[900]!,
                          width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                    hintText: "Enter the message to analyze...",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _analyzeWithAI,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.greenAccent,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Analyze with AI",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _result,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _result.contains("⚠")
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_scamPercentage > 0)
                        Text(
                          "Scam Likelihood: ${_scamPercentage.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (_reasons.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text("Reasons:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _reasons
                              .map((reason) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("• $reason",
                                        style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
