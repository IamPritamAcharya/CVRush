import 'dart:ui';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:horz/pages/messageList.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:horz/theme/themeProvider.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'UploadDropdown.dart';

final supabase = Supabase.instance.client;

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onDrawerOpen;
  final ValueChanged<int>? onPageChange;

  const CustomAppBar(
      {super.key, required this.onDrawerOpen, this.onPageChange});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}

class _CustomAppBarState extends State<CustomAppBar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final bool isWebOrDesktop = kIsWeb || Platform.isWindows;

    return SafeArea(
      child: Center(
        child: Container(
          width: isWebOrDesktop ? 1080 : double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(45),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _buildAppBarContainer(context, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildAppBarContainer(BuildContext context, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(45),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45),
          border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
              width: 0.6),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black12.withOpacity(0.85)
                  : Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(45),
            ),
            child: _buildAppBarContent(context, isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarContent(BuildContext context, bool isDarkMode) {
    final bool isWebOrDesktop = kIsWeb || Platform.isWindows;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(LineIcons.bars,
              color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        Text(
          "CVRush",
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        if (isWebOrDesktop)
          _buildWebNavBar(context, isDarkMode)
        else
          _buildMobileIcons(context, isDarkMode),
      ],
    );
  }

  int _selectedIndex = 0; // Track the active page index

  Widget _buildWebNavBar(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        _buildNavLink(context, "Home", 0, isDarkMode),
        _buildNavLink(context, "Jobs", 3, isDarkMode),
        _buildNavLink(context, "CV Maker", 1, isDarkMode),
        _buildNavLink(context, "Sign In", 2, isDarkMode),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "Upload") uploadResume(context);
          },
          icon: Icon(
            LineIcons.horizontalEllipsis,
            color: isDarkMode ? Colors.white38 : Colors.black87,
          ),
          offset: const Offset(0, 45),
          color: isDarkMode
              ? Colors.black.withOpacity(0.85)
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 10,
          itemBuilder: (context) => [
            _buildMenuItem(
              LineIcons.fileUpload,
              "Upload Resume",
              Colors.lightBlueAccent,
              isDarkMode ? Colors.white : Colors.black87,
              "Upload",
            ),
            _buildMenuItem(
              LineIcons.facebookMessenger,
              "Messages",
              Colors.orangeAccent,
              isDarkMode ? Colors.white : Colors.black87,
              "Messages",
            ),
            _buildMenuItem(
              LineIcons.bell,
              "Notifications",
              Colors.redAccent,
              isDarkMode ? Colors.white : Colors.black87,
              "Notifications",
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    IconData icon,
    String text,
    Color iconColor,
    Color textColor,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileIcons(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        IconButton(
          icon: Icon(LineIcons.facebookMessenger,
              color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MessagesListPage()),
            );
          },
        ),
        UploadDropdown(onUploadResume: () => uploadResume(context)),
        IconButton(
          icon: Icon(LineIcons.bell,
              color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNavLink(
      BuildContext context, String text, int pageIndex, bool isDarkMode) {
    bool isHovered = _hoveredIndex == pageIndex;
    bool isActive = _selectedIndex == pageIndex;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = pageIndex),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = pageIndex);
          widget.onPageChange?.call(pageIndex);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isDarkMode
                      ? (isHovered || isActive ? Colors.white : Colors.white60)
                      : (isHovered || isActive ? Colors.black : Colors.black54),
                  letterSpacing: 0.2,
                ),
                child: Text(text),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: isActive ? 20 : (isHovered ? 18 : 0),
                height: 2,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isHovered || isActive
                      ? [
                          BoxShadow(
                            color: isDarkMode ? Colors.white24 : Colors.black26,
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          )
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> uploadResume(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null) {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception("User not authenticated");

        final fileName =
            "${userId}_${DateTime.now().millisecondsSinceEpoch}.${result.files.single.extension}";
        final filePath = 'resumes/$fileName';
        final mimeType = lookupMimeType(result.files.single.name) ??
            'application/octet-stream';

        // Upload file to Supabase Storage
        if (kIsWeb) {
          Uint8List fileBytes = result.files.single.bytes!;
          await supabase.storage.from('resumes').uploadBinary(
              filePath, fileBytes,
              fileOptions: FileOptions(contentType: mimeType));
        } else {
          File file = File(result.files.single.path!);
          await supabase.storage.from('resumes').upload(filePath, file,
              fileOptions: FileOptions(contentType: mimeType));
        }

        // Get the public URL of the uploaded file
        final fileUrl = supabase.storage.from('resumes').getPublicUrl(filePath);
        if (fileUrl.isEmpty)
          throw Exception("File upload failed, URL is empty");

        // Insert metadata into the resumes table
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

        // Debugging the response
        debugPrint("Insert response: $response");

        // Check for errors in response
        if (response == null) {
          throw Exception("Database Insert Error: Unknown error");
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Resume uploaded successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error uploading resume: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }
}
