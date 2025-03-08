import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobActionButtons extends StatefulWidget {
  final String jobId;
  const JobActionButtons({Key? key, required this.jobId}) : super(key: key);

  @override
  _JobActionButtonsState createState() => _JobActionButtonsState();
}

class _JobActionButtonsState extends State<JobActionButtons>
    with SingleTickerProviderStateMixin {
  bool isSaved = false;
  bool isApplying = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  /// **🔹 Load Saved Job State from SharedPreferences**
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedJobs = prefs.getStringList("saved_jobs") ?? [];

    setState(() {
      isSaved = savedJobs.contains(widget.jobId);
    });
  }

  /// **🔹 Toggle Job Save/Unsave**
  Future<void> _toggleSaveJob() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedJobs = prefs.getStringList("saved_jobs") ?? [];

    setState(() {
      if (isSaved) {
        savedJobs.remove(widget.jobId); // Remove from saved
      } else {
        savedJobs.add(widget.jobId); // Add to saved
      }
      isSaved = !isSaved; // Toggle state
      prefs.setStringList("saved_jobs", savedJobs);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? "Job saved!" : "Job removed from saved."),
        duration: const Duration(seconds: 2),
        backgroundColor: isSaved ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// **🔹 Show Apply Confirmation Dialog**
  void _showApplyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Confirm Application",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to apply for this position with your current resume?",
            style:
                TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style:
                    TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyForJob();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text("Proceed"),
            ),
          ],
        );
      },
    );
  }

  /// **🔹 Handle Job Application with Animation**
  void _applyForJob() {
    setState(() => isApplying = true);
    _controller.forward();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return ScaleTransition(
              scale: _scaleAnimation,
              child: AlertDialog(
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[700], size: 60),
                    const SizedBox(height: 12),
                    Text(
                      "Applied Successfully!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
            setState(() => isApplying = false);
            _controller.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showApplyDialog,
            icon: Icon(
              LineIcons.paperPlane,
              color: isApplying
                  ? Colors.green[700]
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            label: const Text("Apply Now"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _toggleSaveJob,
          icon: Icon(
            isSaved ? LineIcons.bookmark : LineIcons.bookmarkAlt,
            color: isSaved ? Colors.yellow[700] : textColor,
            size: 30,
          ),
        ),
      ],
    );
  }
}
