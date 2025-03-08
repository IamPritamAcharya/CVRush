import 'package:flutter/material.dart';
import 'package:horz/pages/jobs/jobmodel.dart';

class JobHeader extends StatelessWidget {
  final Job job;
  const JobHeader({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color borderColor = isDarkMode ? Colors.white24 : Colors.black26;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color secondaryTextColor =
        isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// **📌 Company Logo (Adaptive to Dark Mode)**
          CircleAvatar(
            backgroundImage: job.logoUrl.isNotEmpty
                ? NetworkImage(job.logoUrl)
                : const AssetImage("assets/default_company.png")
                    as ImageProvider,
            radius: 35,
            backgroundColor: borderColor, // Matches theme
          ),
          const SizedBox(width: 12),

          /// **📌 Job Title & Company Name**
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.showcase.isNotEmpty ? job.showcase.first : "Job Title",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.company.isNotEmpty ? job.company : "Company Name",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
