import 'package:flutter/material.dart';
import 'package:horz/pages/jobs/jobmodel.dart';
import 'package:line_icons/line_icons.dart';

class JobDetails extends StatelessWidget {
  final Job job;
  const JobDetails({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color borderColor = isDarkMode ? Colors.white24 : Colors.black26;
    final Color textColor = theme.textTheme.bodyMedium!.color!;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
              LineIcons.mapMarker, job.location, textColor, iconColor),
          _buildDetailRow(LineIcons.calendar, _formatDate(job.datePosted),
              textColor, iconColor),
          _buildDetailRow(
              LineIcons.briefcase, job.jobType, textColor, iconColor),
          _buildDetailRow(LineIcons.laptop, job.remote ? "Remote" : "On-site",
              textColor, iconColor),
          _buildDetailRow(
              LineIcons.moneyBill, job.stipend, textColor, iconColor),
          _buildDetailRow(
              LineIcons.dollarSign, "Rate: ${job.rate}", textColor, iconColor),
          _buildDetailRow(LineIcons.building,
              job.startup ? "Startup" : "Established", textColor, iconColor),
        ],
      ),
    );
  }

  /// **🔹 Detail Row Widget**
  Widget _buildDetailRow(
      IconData icon, String? text, Color textColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text != null && text.isNotEmpty ? text : "N/A",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// **🔹 Format Date for Better Readability**
  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";
    return "${date.day}/${date.month}/${date.year}";
  }
}
