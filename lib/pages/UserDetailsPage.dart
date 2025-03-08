import 'package:flutter/material.dart';
import 'package:horz/pages/ChatPage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId; // The ID of the user whose details are being viewed

  UserDetailsPage({required this.userId});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  // The currently logged-in user's id
  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
  bool isConnected = false;
  bool requestSent = false;
  List<double> cvScores = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkConnectionStatus();
  }

  Future<void> _fetchUserData() async {
    try {
      // Query users with the related resume_profile data
      final response = await Supabase.instance.client
          .from('users')
          .select('*, resume_profile(cv_scores, percentile, resume)')
          .eq('id', widget.userId)
          .single();

      // Handle resume_profile which may come as a list or map.
      final resumeProfileRaw = response['resume_profile'];
      final Map<String, dynamic> resumeData = (resumeProfileRaw is List &&
              resumeProfileRaw.isNotEmpty)
          ? resumeProfileRaw[0] as Map<String, dynamic>
          : (resumeProfileRaw is Map<String, dynamic> ? resumeProfileRaw : {});

      // Parse cv_scores, filtering out any null values.
      final scores = (resumeData['cv_scores'] as List<dynamic>?)
              ?.where((e) => e != null)
              .map((e) {
            if (e is num) return e.toDouble();
            return double.tryParse(e.toString()) ?? 0.0;
          }).toList() ??
          [];
      setState(() {
        cvScores = scores;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final existingConnection = await Supabase.instance.client
          .from('connections')
          .select()
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('receiver_id', widget.userId)
          .maybeSingle();

      if (existingConnection != null) {
        setState(() {
          isConnected = existingConnection['status'] == 'accepted';
          requestSent = existingConnection['status'] == 'pending';
        });
      }
    } catch (e) {
      debugPrint("Error checking connection status: $e");
    }
  }

  Future<void> _sendConnectionRequest() async {
    if (currentUserId == null) return;
    try {
      await Supabase.instance.client.from('connections').insert({
        'sender_id': currentUserId,
        'receiver_id': widget.userId,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });
      setState(() {
        requestSent = true;
      });
    } catch (e) {
      debugPrint("Error sending connection request: $e");
    }
  }

  Widget _buildBox({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light mode background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Details")),
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('users')
            .select('*, resume_profile(cv_scores, percentile, resume)')
            .eq('id', widget.userId)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return Center(child: Text("Error loading user details"));
          }

          final user = snapshot.data as Map<String, dynamic>;

          // Safe extraction of related fields
          final achievements = user['achievements'] is List
              ? user['achievements'] as List<dynamic>
              : [];
          final skills =
              user['skills'] is List ? user['skills'] as List<dynamic> : [];
          final experience = user['experience'] is Map<String, dynamic>
              ? user['experience'] as Map<String, dynamic>
              : {};
          final projects =
              user['projects'] is List ? user['projects'] as List<dynamic> : [];

          // Handle resume_profile data safely
          final resumeProfileRaw = user['resume_profile'];
          final Map<String, dynamic> resumeData =
              (resumeProfileRaw is List && resumeProfileRaw.isNotEmpty)
                  ? resumeProfileRaw[0] as Map<String, dynamic>
                  : (resumeProfileRaw is Map<String, dynamic>
                      ? resumeProfileRaw
                      : {});

          return Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Row (Image and Name)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage:
                                  (user['profile_picture'] != null &&
                                          user['profile_picture']
                                              .toString()
                                              .isNotEmpty)
                                      ? NetworkImage(user['profile_picture'])
                                      : null,
                              child: (user['profile_picture'] == null ||
                                      user['profile_picture']
                                          .toString()
                                          .isEmpty)
                                  ? Icon(Icons.person,
                                      size: 40, color: Colors.grey.shade700)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                user['name']?.toString().trim().isNotEmpty ==
                                        true
                                    ? user['name']
                                    : "No Name",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatPage(receiverId: widget.userId),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Message"),
                            ),
                            ElevatedButton(
                              onPressed:
                                  requestSent ? null : _sendConnectionRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isConnected ? Colors.green : Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                isConnected
                                    ? "Connected"
                                    : requestSent
                                        ? "Request Sent"
                                        : "Connect",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),

                  if (achievements.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 600), // Wider box
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          margin: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .cardColor, // Adapts to light/dark theme
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor, // Themed border
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Achievements",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),

                              // Centered Badge Display
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: achievements
                                      .where((url) =>
                                          url != null &&
                                          url.toString().isNotEmpty)
                                      .map<Widget>((url) => ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              url.toString(),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceVariant,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child:
                                                      const CircularProgressIndicator(
                                                          strokeWidth: 1.5),
                                                );
                                              },
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                width: 50,
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceVariant,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.broken_image,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    size: 20),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // CV Score, Percentile & Resume Row
                  if (cvScores.isNotEmpty || resumeData['resume'] != null)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          margin: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardColor, // Adapts to theme
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor, // Themed border
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CV Score & Resume",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),

                              // CV Score & Percentile
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CV Score: ${cvScores.isNotEmpty ? cvScores.last : 'N/A'}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      Text(
                                        "Percentile: ${resumeData['percentile'] != null ? double.tryParse(resumeData['percentile'].toString()) ?? 'N/A' : 'N/A'}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ],
                                  ),

                                  // Resume Preview (Image with Fullscreen View)
                                  if (resumeData['resume'] != null &&
                                      resumeData['resume']
                                          .toString()
                                          .isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: InteractiveViewer(
                                              panEnabled: true,
                                              minScale: 0.5,
                                              maxScale: 3.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  resumeData['resume']
                                                      .toString(),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    width: 300,
                                                    height: 400,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceVariant,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        size: 50),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          resumeData['resume'].toString(),
                                          width: 60,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 60,
                                            height: 80,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.insert_drive_file,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                size: 24),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () {
                                        if (resumeData['resume'] != null &&
                                            resumeData['resume']
                                                .toString()
                                                .isNotEmpty) {
                                          // Open the resume link (e.g., using url_launcher)
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                      child: Text("View Resume"),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // CV Score Graph
                  if (cvScores.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 600), // Wider box
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          margin: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .cardColor, // Themed background
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor, // Themed thin border
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CV Score Progress",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, _) => Text(
                                            value.toInt().toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, _) => Text(
                                            (value.toInt() + 1).toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          cvScores.length,
                                          (index) => FlSpot(index.toDouble(),
                                              cvScores[index]),
                                        ),
                                        isCurved: true,
                                        barWidth: 3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.3),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Skills, Experience, Projects Box
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: 600), // Ensuring proper width
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .cardColor, // Adaptive background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).dividerColor, // Subtle border
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Title
                            Text(
                              "Skills, Experience & Projects",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Skills
                            if (skills.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "Skills: ${skills.join(", ")}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),

                            // Experience
                            if (experience.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    experience.entries.map<Widget>((entry) {
                                  if (entry.value is Map<String, dynamic>) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.work_outline,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "${entry.key}: ${entry.value['role']} (${entry.value['years']} years)",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }).toList(),
                              ),

                            // Projects
                            if (projects.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: projects.map<Widget>((project) {
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                          width: 1),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      title: Text(
                                        project['title'] ?? 'Untitled Project',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      subtitle: Text(
                                        project['description'] ??
                                            'No description available',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      trailing: (project['url'] != null &&
                                              project['url']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? IconButton(
                                              icon: Icon(Icons.link,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                              onPressed: () {
                                                // Open project link
                                              },
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
