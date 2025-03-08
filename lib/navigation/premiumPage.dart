import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Membership Plans",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Your Plan",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Free Plan
            _buildTierCard(
              title: "Free Plan",
              features: [
                {"text": "Basic ATS Score", "available": true},
                {"text": "Job Board Access", "available": true},
                {
                  "text": "Candidate Search (limited access)",
                  "available": true
                },
                {"text": "Advanced AI Resume Review", "available": false},
                {"text": "Priority Support", "available": false},
              ],
              borderColor: Colors.white,
              icon: LineIcons.lockOpen,
            ),
            const SizedBox(height: 20),

            // Premium Plan
            _buildPremiumCard(),

            const SizedBox(height: 40),

            // Upgrade Button
            _buildUpgradeButton(),
          ],
        ),
      ),
    );
  }

  // Free Tier Card
  Widget _buildTierCard({
    required String title,
    required List<Map<String, dynamic>> features,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Column(
            children: features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          feature["available"]
                              ? LineIcons.checkCircle
                              : LineIcons.timesCircle,
                          color: feature["available"]
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature["text"],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Premium Tier - Gold Glow
  Widget _buildPremiumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LineIcons.crown, color: Colors.amber, size: 32),
          const SizedBox(height: 12),
          const Text(
            "Premium Plan",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              {"text": "Unlimited Resume Uploads", "available": true},
              {"text": "AI Resume Review", "available": true},
              {"text": "Priority Job Listings", "available": true},
              {"text": "Exclusive Community Access", "available": true},
              {"text": "24/7 Priority Support", "available": true},
              {"text": "Unlimited Resume Checks", "available": true},
            ]
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(LineIcons.checkCircle,
                            color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          feature["text"].toString(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Upgrade Button
  Widget _buildUpgradeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Upgrade to Premium",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
