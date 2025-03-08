import 'package:flutter/material.dart';
import 'package:horz/pages/jobs/jobmodel.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'components/job_action_buttons.dart';
import 'components/job_description.dart';
import 'components/job_details_card.dart';
import 'components/job_header.dart';
import 'components/job_selection_graph.dart';

class JobDetailPage extends StatefulWidget {
  final Job job;
  const JobDetailPage({Key? key, required this.job}) : super(key: key);

  @override
  _JobDetailPageState createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  SharedPreferences? prefs;
  List<String> savedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      savedJobs = prefs?.getStringList('savedJobs') ?? [];
    });
  }

  Future<void> _toggleSaveJob() async {
    if (prefs == null) return;
    setState(() {
      if (savedJobs.contains(widget.job.id)) {
        savedJobs.remove(widget.job.id);
      } else {
        savedJobs.add(widget.job.id);
      }
      prefs?.setStringList('savedJobs', savedJobs);
    });
  }

  bool isSaved() => savedJobs.contains(widget.job.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, // 85% of screen height
      minChildSize: 0.5, // Can collapse to 50%
      maxChildSize: 0.95, // Expand to 95% height
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                JobHeader(job: widget.job),
                const SizedBox(height: 16),
                JobActionButtons(jobId: widget.job.id),
                const SizedBox(height: 16),
                JobDetails(job: widget.job),
                const SizedBox(height: 20),
                JobSelectionGraph(job: widget.job),
                const SizedBox(height: 20),
                JobDescription(description: widget.job.description),
              ],
            ),
          ),
        );
      },
    );
  }
}
