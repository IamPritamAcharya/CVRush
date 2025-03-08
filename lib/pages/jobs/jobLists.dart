import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:horz/pages/jobs/components/SavedJobsPage.dart';
import 'package:horz/pages/jobs/jobCard.dart';
import 'package:horz/pages/jobs/jobProvider.dart';
import 'package:horz/pages/jobs/jobmodel.dart';
import 'package:line_icons/line_icons.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({super.key});

  @override
  _JobListPageState createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    await jobProvider.fetchJobs();
    setState(() {}); // Refresh UI
  }

  String searchQuery = "";
  String selectedFilter = "All";
  bool showOnlyRemote = false;
  bool showOnlyStartups = false;
  double percentileRange = 100;
  String selectedLocation = "All";
  String postedTime = "Anytime";

  List<String> locations = ["All", "San Francisco, USA", "London, UK"];
  List<String> postedTimeOptions = [
    "Anytime",
    "Last 1 Day",
    "Last Week",
    "Last Month"
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    /// 🔹 Dynamically adjust grid layout
    int getCrossAxisCount() {
      if (screenWidth > 1200) return 4; // Desktop
      if (screenWidth > 800) return 3; // Tablets
      return 2; // Phones
    }

    /// 🔹 Filtered Jobs List
    List<Job> filteredJobs = jobProvider.jobs.where((job) {
      if (searchQuery.isNotEmpty &&
          !job.showcase.any((text) =>
              text.toLowerCase().contains(searchQuery.toLowerCase()))) {
        return false;
      }
      if (selectedFilter != "All" && job.jobType != selectedFilter)
        return false;
      if (showOnlyRemote && !job.remote) return false;
      if (showOnlyStartups && !job.startup) return false;
      if (job.percentile > percentileRange) return false;
      if (selectedLocation != "All" && job.location != selectedLocation)
        return false;

      final now = DateTime.now();
      final diff = now.difference(job.datePosted).inDays;
      if (postedTime == "Last 1 Day" && diff > 1) return false;
      if (postedTime == "Last Week" && diff > 7) return false;
      if (postedTime == "Last Month" && diff > 30) return false;

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.cardColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 800 ? 50 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Conditional SizedBox inside scrollable content
                if (!kIsWeb && !Platform.isWindows) const SizedBox(height: 80),
                if (kIsWeb || Platform.isWindows) const SizedBox(height: 50),

                /// 🔹 Search & Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: "Search jobs...",
                          prefixIcon: const Icon(LineIcons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      setState(() => searchQuery = ""),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // **🔹 Saved Jobs Icon Button**
                    IconButton(
                      icon: const Icon(
                          LineIcons.bookmark), // Bookmark icon for saved jobs
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SavedJobsPage()),
                        );
                      },
                    ),

                    const SizedBox(width: 10),

                    // **🔹 Filter Icon Button**
                    IconButton(
                      icon: const Icon(LineIcons.filter),
                      onPressed: _showFilterModal,
                    ),
                  ],
                ),

                /// 🔹 Controlled spacing between search bar & grid
                const SizedBox(height: 10),

                /// 🔹 Responsive Grid View (Kept Inside a Sized Box for Scrolling)
                GridView.builder(
                  padding: const EdgeInsets.only(top: 5),
                  itemCount: filteredJobs.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getCrossAxisCount(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: screenWidth > 1200 ? 1.2 : 0.85,
                  ),
                  physics:
                      const NeverScrollableScrollPhysics(), // Prevents nested scrolling issue
                  shrinkWrap: true, // Allows GridView to fit inside ScrollView
                  itemBuilder: (context, index) {
                    return JobCard(job: filteredJobs[index]);
                  },
                ),

                /// 🔹 Added bottom spacing for better layout balance
                SizedBox(height: screenWidth > 600 ? 40 : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: theme.cardColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filters", style: theme.textTheme.titleLarge),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 22, color: theme.iconTheme.color),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),

                  _sectionHeader("Job Type", theme),
                  _customDropdown(
                    context: context,
                    value: selectedFilter,
                    items: ["All", "Internship", "Full Time", "Remote"],
                    onChanged: (value) {
                      setModalState(() => selectedFilter = value!);
                      setState(() {});
                    },
                  ),

                  _sectionHeader("Preferences", theme),
                  _toggleTile("Remote Only", showOnlyRemote, (newValue) {
                    setModalState(() => showOnlyRemote = newValue);
                    setState(() {});
                  }, theme),
                  _toggleTile("Startups Only", showOnlyStartups, (newValue) {
                    setModalState(() => showOnlyStartups = newValue);
                    setState(() {});
                  }, theme),
                  const Divider(),

                  /// 🔹 Location Filter
                  _sectionHeader("Location", theme),
                  _customDropdown(
                    context: context,
                    value: selectedLocation,
                    items: locations,
                    onChanged: (value) {
                      setModalState(() => selectedLocation = value!);
                      setState(() {});
                    },
                  ),

                  /// 🔹 Date Posted Filter
                  _sectionHeader("Date Posted", theme),
                  _customDropdown(
                    context: context,
                    value: postedTime,
                    items: postedTimeOptions,
                    onChanged: (value) {
                      setModalState(() => postedTime = value!);
                      setState(() {});
                    },
                  ),
                  const Divider(),

                  /// 🔥 **Standalone Percentile Section (Now Has a Border!)**
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blueGrey[800]
                          : Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.white54 : Colors.grey[400]!,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Minimum Percentile",
                          style: theme.textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: theme.primaryColor,
                            inactiveTrackColor:
                                theme.primaryColor.withOpacity(0.3),
                            thumbColor: theme.primaryColor,
                            overlayColor: theme.primaryColor.withOpacity(0.2),
                            valueIndicatorTextStyle:
                                const TextStyle(color: Colors.white),
                          ),
                          child: Slider(
                            value: percentileRange,
                            min: 0,
                            max: 100,
                            divisions: 10,
                            label: "${percentileRange.toInt()}%",
                            onChanged: (value) {
                              setModalState(() => percentileRange = value);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              selectedFilter = "All";
                              showOnlyRemote = false;
                              showOnlyStartups = false;
                              selectedLocation = locations.first;
                              postedTime = postedTimeOptions.first;
                              percentileRange = 90;
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Reset",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.scaffoldBackgroundColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Apply Filters",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style:
            theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _customDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12), // 🔥 Outer Rounded Corners
          border: Border.all(
            color: isDarkMode ? Colors.white54 : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
          value: value,
          isExpanded: true,
          style: theme.textTheme.bodyLarge,
          dropdownStyleData: DropdownStyleData(
            width: 300,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        )),
      ),
    );
  }

  Widget _toggleTile(
      String label, bool value, Function(bool) onChanged, ThemeData theme) {
    return SwitchListTile(
      title: Text(label, style: theme.textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
      activeColor: theme.primaryColor,
      dense: true,
    );
  }
}
