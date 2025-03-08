import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:horz/pages/jobs/jobdeatils.dart';
import 'package:horz/pages/jobs/jobmodel.dart';

class SavedJobsPage extends StatefulWidget {
  const SavedJobsPage({Key? key}) : super(key: key);

  @override
  _SavedJobsPageState createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  List<Job> savedJobs = [];
  bool isLoading = true;
  late SharedPreferences prefs;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    try {
      prefs = await SharedPreferences.getInstance();
      List<String> savedJobIds = prefs.getStringList("saved_jobs") ?? [];

      if (savedJobIds.isEmpty) {
        setState(() {
          savedJobs = [];
          isLoading = false;
        });
        return;
      }

      final response =
          await supabase.from('jobs').select().filter('id', 'in', savedJobIds);

      if (response != null && response is List) {
        List<Job> fetchedJobs =
            response.map((job) => Job.fromJson(job)).toList();
        setState(() {
          savedJobs = fetchedJobs;
        });
      }
    } catch (e) {
      debugPrint("Error loading saved jobs: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeSavedJob(String jobId) async {
    List<String> savedJobIds = prefs.getStringList("saved_jobs") ?? [];
    savedJobIds.remove(jobId);
    await prefs.setStringList("saved_jobs", savedJobIds);

    setState(() {
      savedJobs.removeWhere((job) => job.id == jobId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Job removed from saved."),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Jobs"),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0.5,
      ),
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedJobs.isEmpty
              ? Center(
                  child: Text(
                    "No saved jobs yet.",
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: savedJobs.length,
                  itemBuilder: (context, index) {
                    Job job = savedJobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          border: Border.all(
                            color: isDarkMode ? Colors.white30 : Colors.black26,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          title: Text(
                            job.company,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          subtitle: Text(
                            job.jobType,
                            style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.7)),
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: job.logoUrl.isNotEmpty
                                ? Image.network(
                                    job.logoUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.work,
                                            color: textColor,
                                            size: 40),
                                  )
                                : Icon(Icons.work, color: textColor, size: 40),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSavedJob(job.id),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) {
                                return _buildJobDetailsBottomSheet(
                                    job, isDarkMode);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildJobDetailsBottomSheet(Job job, bool isDarkMode) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDarkMode ? Colors.white30 : Colors.black26,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: JobDetailPage(job: job),
              ),
            ],
          ),
        );
      },
    );
  }
}
