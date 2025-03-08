import 'package:flutter/material.dart';
import 'package:horz/markdown_renderer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:share_plus/share_plus.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResumeDetailPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String description;
  final int likes;
  final int dislikes;

  const ResumeDetailPage({
    Key? key,
    required this.title,
    required this.videoUrl,
    required this.description,
    required this.likes,
    required this.dislikes,
  }) : super(key: key);

  @override
  _ResumeDetailPageState createState() => _ResumeDetailPageState();
}

class _ResumeDetailPageState extends State<ResumeDetailPage> {
  late YoutubePlayerController _controller;
  late String? _videoId;
  int _likes = 0;
  int _dislikes = 0;
  bool? _userLiked;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadPreferences();
  }

  void _initializeVideo() {
    _videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoId ?? '',
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _likes = prefs.getInt('${widget.title}_likes') ?? widget.likes;
      _dislikes = prefs.getInt('${widget.title}_dislikes') ?? widget.dislikes;
      _userLiked = prefs.getBool('${widget.title}_userLiked');
    });
  }

  Future<void> _toggleLike(bool isLike) async {
    setState(() {
      if (_userLiked == isLike) {
        _userLiked = null;
        isLike ? _likes-- : _dislikes--;
      } else {
        if (_userLiked == null) {
          isLike ? _likes++ : _dislikes++;
        } else {
          isLike ? _likes++ : _dislikes++;
          isLike ? _dislikes-- : _likes--;
        }
        _userLiked = isLike;
      }
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('${widget.title}_likes', _likes);
    prefs.setInt('${widget.title}_dislikes', _dislikes);
    prefs.setBool('${widget.title}_userLiked', _userLiked ?? false);
  }

  void _shareVideo() {
    if (_videoId != null && _videoId!.isNotEmpty) {
      Share.share("Check out this resume video: ${widget.videoUrl}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid video URL, cannot share!")),
      );
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isWeb = MediaQuery.of(context).size.width > 800; // Detect Web/Desktop

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey[900]!]
                : [Colors.blueGrey[50]!, Colors.grey[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: isWeb
                ? _buildWebLayout(isDarkMode)
                : _buildMobileLayout(isDarkMode),
          ),
        ),
      ),
    );
  }

  /// **Mobile Layout** (Stacked: Video -> Buttons -> Description)
  Widget _buildMobileLayout(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// **Video Player**
        if (_videoId != null && _videoId!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayerScaffold(
              controller: _controller,
              aspectRatio: 16 / 9,
              builder: (context, player) => player,
            ),
          )
        else
          _buildInvalidVideoBox(),

        const SizedBox(height: 15),

        /// **Like, Dislike, Share Buttons**
        _buildLikeDislikeRow(),

        const SizedBox(height: 15),

        /// **Title + Description Box**
        _buildDescriptionBox(isDarkMode),
      ],
    );
  }

  /// **Web Layout** (Video + Buttons on Left, Title + Description on Right)
  Widget _buildWebLayout(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// **Left Side (Video + Buttons)**
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (_videoId != null && _videoId!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: YoutubePlayerScaffold(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    builder: (context, player) => player,
                  ),
                )
              else
                _buildInvalidVideoBox(),
              const SizedBox(height: 15),
              _buildLikeDislikeRow(),
            ],
          ),
        ),

        const SizedBox(width: 20),

        /// **Right Side (Title + Description)**
        Expanded(
          flex: 3,
          child: _buildDescriptionBox(isDarkMode),
        ),
      ],
    );
  }

  /// **Like, Dislike, Share Buttons + Resources Button**
  Widget _buildLikeDislikeRow() {
    return Column(
      children: [
        /// **Like, Dislike, Share Row**
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    LineIcons.thumbsUp,
                    color: _userLiked == true ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _toggleLike(true),
                ),
                Text("$_likes", style: _counterTextStyle()),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    LineIcons.thumbsDown,
                    color: _userLiked == false ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleLike(false),
                ),
                Text("$_dislikes", style: _counterTextStyle()),
              ],
            ),
            IconButton(
              icon: const Icon(LineIcons.share, size: 24),
              onPressed: _shareVideo,
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// **Resources Button**
        /// **Resources Button (Modern & Clean)**
        SizedBox(
          width: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: _openResources, // Open Google Drive URL
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00C853),
                    Color(0xFF00E676)
                  ], // Green gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Resources",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// **Function to Open Google Drive URL**
  void _openResources() async {
    const String gDriveUrl =
        "https://drive.google.com/your-resources-link"; // Replace with actual URL
    if (await canLaunch(gDriveUrl)) {
      await launch(gDriveUrl);
    } else {
      throw "Could not launch $gDriveUrl";
    }
  }

  /// **Description Box with Title**
  Widget _buildDescriptionBox(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: _titleTextStyle(isDarkMode)),
          const Divider(thickness: 1),
          CustomMarkdown(
              markdownText: widget.description, width: double.infinity),
        ],
      ),
    );
  }

  /// **Invalid Video Placeholder**
  Widget _buildInvalidVideoBox() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text("Invalid Video URL",
            style: TextStyle(fontSize: 18, color: Colors.black54)),
      ),
    );
  }

  TextStyle _titleTextStyle(bool isDarkMode) => TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black87);
  TextStyle _counterTextStyle() =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
}
