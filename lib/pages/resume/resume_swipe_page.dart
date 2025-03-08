import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:horz/pages/resume/FullScreenImagePage.dart';
import 'package:line_icons/line_icons.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'CommentsPage.dart';
import '../UserDetailsPage.dart';

final supabase = Supabase.instance.client;

class ResumeSwipePage extends StatefulWidget {
  @override
  _ResumeSwipePageState createState() => _ResumeSwipePageState();
}

class _ResumeSwipePageState extends State<ResumeSwipePage> {
  List<Map<String, dynamic>> resumes = [];
  String? userId = supabase.auth.currentUser?.id;
  Map<String, double> userRatings = {}; // Stores user-selected ratings

  @override
  void initState() {
    super.initState();
    fetchResumes();

    fetchUserRatings();
  }

  Future<void> fetchResumes() async {
    try {
      final response = await supabase
          .from('resumes')
          .select('*, users(id, name, profile_picture, is_public)')
          .order('uploaded_at', ascending: false);

      if (response.isNotEmpty) response.shuffle(Random());

      setState(() {
        resumes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching resumes: $e");
    }
  }

  Future<void> fetchUserRatings() async {
    if (userId == null) return;
    try {
      final ratingsResponse = await supabase
          .from('ratings')
          .select('resume_id, rating')
          .eq('user_id', userId!);

      Map<String, double> ratingsMap = {};
      for (var rating in ratingsResponse) {
        ratingsMap[rating['resume_id']] = (rating['rating'] as num).toDouble();
      }
      setState(() {
        userRatings = ratingsMap;
      });
    } catch (e) {
      debugPrint("Error fetching ratings: $e");
    }
  }

  Future<void> rateResume(String resumeId, double rating) async {
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please sign in to rate.")));
      return;
    }

    setState(() {
      userRatings[resumeId] = rating;
    });

    try {
      final userResponse = await supabase
          .from('users')
          .select('is_public, is_recruiter')
          .eq('id', userId!)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint("Error: User not found.");
        return;
      }

      final bool isPublic = userResponse['is_public'] ?? false;
      final bool isRecruiter = userResponse['is_recruiter'] ?? false;
      double weight = isRecruiter ? 2.0 : (isPublic ? 1.5 : 1.0);

      final existingRatingResponse = await supabase
          .from('ratings')
          .select('id, rating, weight')
          .eq('user_id', userId!)
          .eq('resume_id', resumeId)
          .maybeSingle();

      double previousRating = 0.0;
      double previousWeight = 0.0;
      bool isUpdating = existingRatingResponse != null;

      if (isUpdating) {
        previousRating = (existingRatingResponse['rating'] ?? 0.0).toDouble();
        previousWeight = (existingRatingResponse['weight'] ?? 1.0).toDouble();
      }

      final resumeResponse = await supabase
          .from('resumes')
          .select('rating_avg, total_ratings, total_weighted_score')
          .eq('id', resumeId)
          .maybeSingle();

      if (resumeResponse == null) {
        debugPrint("Error: Resume not found.");
        return;
      }

      double currentWeightedScore =
          (resumeResponse['total_weighted_score'] ?? 0.0).toDouble();
      int currentCount = (resumeResponse['total_ratings'] ?? 0);

      if (isUpdating) {
        currentWeightedScore -= (previousRating * previousWeight);
      } else {
        currentCount += 1;
      }

      currentWeightedScore += (rating * weight);

      double newRatingAvg = currentWeightedScore / currentCount;

      if (isUpdating) {
        await supabase.from('ratings').update({
          'rating': rating,
          'weight': weight,
        }).match({'id': existingRatingResponse['id']});
      } else {
        await supabase.from('ratings').insert({
          'user_id': userId,
          'resume_id': resumeId,
          'rating': rating,
          'weight': weight,
        });
      }

      await supabase.from('resumes').update({
        'rating_avg': newRatingAvg,
        'total_ratings': currentCount,
        'total_weighted_score': currentWeightedScore,
      }).match({'id': resumeId});

      setState(() {
        for (var resume in resumes) {
          if (resume['id'] == resumeId) {
            resume['rating_avg'] = newRatingAvg;
            resume['total_ratings'] = currentCount;
            resume['total_weighted_score'] = currentWeightedScore;
            break;
          }
        }
      });
    } catch (e) {
      debugPrint("Error rating resume: $e");
    }
  }

  Future<void> uploadResume(File file) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      final fileName =
          "${userId}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}";
      final filePath = 'resumes/$fileName';
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      await supabase.storage.from('resumes').upload(
            filePath,
            file,
            fileOptions: FileOptions(contentType: mimeType),
          );

      final fileUrl = supabase.storage.from('resumes').getPublicUrl(filePath);
      if (fileUrl.isEmpty) throw Exception("File upload failed, URL is empty");

      final userExists =
          await supabase.from('users').select().eq('id', userId).maybeSingle();
      if (userExists == null) throw Exception("User not found in users table");

      final response = await supabase.from('resumes').insert({
        'user_id': userId,
        'resume_file': fileName,
        'file_url': fileUrl,
        'uploaded_at': DateTime.now().toUtc().toIso8601String(),
        'visibility': true,
        'rating_avg': 0,
        'total_ratings': 0,
        'total_weighted_score': 0,
      });

      if (response == null) {
        throw Exception("Database Insert Error: Unknown error");
      }

      debugPrint("Resume uploaded successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resume uploaded successfully!")),
      );

      fetchResumes();
    } catch (e) {
      debugPrint("Error uploading resume: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double cardWidth = (kIsWeb || Platform.isWindows)
        ? screenHeight / 1.8
        : screenHeight / 1.45;
    final double cardHeight = screenHeight * 0.92;
    final theme = Theme.of(context);

    final List<List<Color>> pastelGradients = [
      [const Color.fromARGB(255, 167, 212, 253), const Color(0xFFFFAB91)],
      [const Color.fromARGB(255, 250, 20, 143), const Color(0xFFDCE775)],
      [
        const Color.fromARGB(255, 181, 189, 73),
        const Color.fromARGB(255, 22, 237, 141)
      ],
      [const Color(0xFFB3E5FC), const Color(0xFFCE93D8)],
      [const Color.fromARGB(255, 252, 85, 85), const Color(0xFFCE93D8)],
      [
        const Color.fromARGB(255, 14, 186, 234),
        const Color.fromARGB(255, 0, 122, 183)
      ],
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: resumes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: (kIsWeb || Platform.isWindows) ? 80 : 110,
                  bottom: (kIsWeb || Platform.isWindows) ? 30 : 110,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CardSwiper(
                        cardsCount: resumes.length,
                        numberOfCardsDisplayed: 2,
                        padding: EdgeInsets.zero,
                        cardBuilder: (context, index, _, __) {
                          final resume = resumes[index];
                          final user = resume['users'];
                          final String resumeId = resume['id'];
                          final bool isPublic = user['is_public'];
                          final String displayName =
                              isPublic ? user['name'] : "Anonymous";
                          final String? profilePic =
                              isPublic ? user['profile_picture'] : null;
                          final String imageUrl =
                              resume['file_url'] ?? resume['resume_file'] ?? "";
                          final List<Color> gradientColors =
                              pastelGradients[index % pastelGradients.length];

                          return Center(
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildUserInfo(
                                            context,
                                            user,
                                            isPublic,
                                            displayName,
                                            profilePic,
                                            resumeId,
                                            imageUrl,
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                              child:
                                                  _buildResumeImage(imageUrl)),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.center,
                                            child: _buildBottomActions(context,
                                                resumeId, imageUrl, resume),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 🔹 Resume Image with Improved Shimmer Effect & Caching
  Widget _buildResumeImage(String imageUrl) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.white,
                      child: Container(
                        color: Colors.grey.shade200,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageErrorPlaceholder();
                  },
                )
              : _buildImageErrorPlaceholder(),
        ),
      ),
    );
  }

  /// 🔹 Error Placeholder for Image Loading Issues
  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LineIcons.exclamationTriangle,
              size: 32, color: Colors.red),
          const SizedBox(height: 5),
          Text("Image Not Available",
              style: TextStyle(color: Colors.red.shade600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
      BuildContext context,
      Map<String, dynamic> user,
      bool isPublic,
      String displayName,
      String? profilePic,
      String resumeId,
      String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        onTap: isPublic
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailsPage(userId: user['id']),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10), // Subtle glass effect
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            children: [
              // Profile Picture with Border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 1),
                ),
                child: CircleAvatar(
                  radius: 18, // Keeping previous size
                  backgroundColor: Colors.white.withOpacity(0.12),
                  backgroundImage:
                      profilePic != null ? NetworkImage(profilePic) : null,
                  child: profilePic == null
                      ? Icon(LineIcons.user,
                          size: 16, color: Colors.white.withOpacity(0.9))
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Username
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14, // Keeping previous size
                    fontWeight: FontWeight.w500, // Slightly lighter
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              _buildIconButton(context, Icons.comment_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CommentsPage(resumeId: resumeId)),
                );
              }),
              _buildIconButton(context, Icons.share_rounded, () {
                Share.share(imageUrl);
              }),
              _buildIconButton(context, Icons.fullscreen_rounded, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImagePage(imageUrl: imageUrl)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, String resumeId,
      String imageUrl, Map<String, dynamic> resume) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.8), width: 1.2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    (resume['rating_avg'] ?? 0).toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildRatingBar(resumeId),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRatingBar(String resumeId) {
    double selectedRating = userRatings[resumeId] ?? 0;
    const double heartSize = 30;

    return LayoutBuilder(builder: (context, constraints) {
      double maxWidth = constraints.maxWidth;
      double totalHeartsWidth = heartSize * 5;
      double availableSpacing = maxWidth - totalHeartsWidth;
      double spacing = (availableSpacing / 4).clamp(3, 10);

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          int ratingValue = index + 1;
          bool isSelected = ratingValue <= selectedRating;

          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              rateResume(resumeId, ratingValue.toDouble());
            },
            child: Padding(
              padding: EdgeInsets.only(right: index < 4 ? spacing : 0),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: isSelected ? 1 : 0.88,
                  end: isSelected ? 1.1 : 1,
                ),
                duration: const Duration(milliseconds: 280),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: isSelected ? heartSize * 1.05 : heartSize,
                          height: isSelected ? heartSize * 1.05 : heartSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.2),
                              width: 0.3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: isSelected
                                          ? [
                                              Colors.white.withOpacity(0.2),
                                              Colors.transparent
                                            ]
                                          : [
                                              Colors.white.withOpacity(0.05),
                                              Colors.transparent
                                            ],
                                      stops: [0.3, 1.0],
                                      center: Alignment.center,
                                    ),
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: isSelected
                                        ? [
                                            Colors.white.withOpacity(0.9),
                                            Colors.white.withOpacity(0.5)
                                          ]
                                        : [
                                            Colors.white.withOpacity(0.5),
                                            Colors.white.withOpacity(0.2)
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.srcATop,
                                child: Icon(
                                  isSelected
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  key: ValueKey(isSelected),
                                  color: Colors.white,
                                  size: heartSize * 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15), // Glass effect
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
        ),
        child:
            Icon(icon, size: 15, color: Colors.white), // Correct dynamic icon
      ),
    );
  }
}
