import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_icons/line_icons.dart';

class CommunityDetailPage extends StatefulWidget {
  final Map<String, dynamic> community;
  CommunityDetailPage({required this.community});

  @override
  _CommunityDetailPageState createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  late SharedPreferences prefs;
  late List<Map<String, dynamic>> posts;
  Map<int, String> userReactions = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    // Create a deep mutable copy of the posts list
    posts = List<Map<String, dynamic>>.from(widget.community['posts']
        .map((post) => Map<String, dynamic>.from(post)));
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  void _toggleReaction(int index, String reactionType) {
    setState(() {
      if (userReactions[index] == reactionType) {
        reactionType == 'like'
            ? posts[index]['likes']--
            : posts[index]['dislikes']--;
        userReactions.remove(index);
      } else {
        if (reactionType == 'like') {
          if (userReactions[index] == 'dislike') posts[index]['dislikes']--;
          posts[index]['likes']++;
        } else {
          if (userReactions[index] == 'like') posts[index]['likes']--;
          posts[index]['dislikes']++;
        }
        userReactions[index] = reactionType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color cardColor = isDark ? Colors.black : Colors.white;
    Color borderColor = isDark ? Colors.white24 : Colors.black26;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.community['banner_url'],
                      fit: BoxFit.cover),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              NetworkImage(widget.community['logo_url']),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.community['name'],
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              "${widget.community['members_count']} members",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage(post['user']['profile_pic']),
                          ),
                          SizedBox(width: 10),
                          Text(
                            post['user']['name'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        post['title'],
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      SizedBox(height: 6),
                      Text(
                        post['body'],
                        style: TextStyle(
                            fontSize: 14, color: textColor.withOpacity(0.8)),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(LineIcons.thumbsUp,
                                color: userReactions[index] == 'like'
                                    ? Colors.green
                                    : Colors.grey),
                            onPressed: () => _toggleReaction(index, 'like'),
                          ),
                          Text("${post['likes']}",
                              style: TextStyle(color: textColor)),
                          IconButton(
                            icon: Icon(LineIcons.thumbsDown,
                                color: userReactions[index] == 'dislike'
                                    ? Colors.red
                                    : Colors.grey),
                            onPressed: () => _toggleReaction(index, 'dislike'),
                          ),
                          Text("${post['dislikes']}",
                              style: TextStyle(color: textColor)),
                          Spacer(),
                          IconButton(
                            icon: Icon(LineIcons.comments, color: textColor),
                            onPressed: () => _showComments(index),
                          ),
                          Text("${post['comments'].length}",
                              style: TextStyle(color: textColor)),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        ],
      ),
    );
  }

  void _showComments(int index) {
    final post = posts[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Comments",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              Expanded(
                child: ListView(
                  children: post['comments'].map<Widget>((comment) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(comment['user']['profile_pic']),
                      ),
                      title: Text(
                        comment['user']['name'],
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        comment['comment'],
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  icon: Icon(Icons.add_comment),
                  label: Text("Add Comment"),
                  onPressed: () => _showCommentDialog(index),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentDialog(int index) {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          title: Text(
            "Add Comment",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: "Write your comment...",
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (commentController.text.trim().isNotEmpty) {
                  setState(() {
                    posts[index]['comments'].add({
                      'user': {
                        'name': 'You', // Replace with actual user data
                        'profile_pic':
                            'https://via.placeholder.com/150' // Placeholder image
                      },
                      'comment': commentController.text.trim(),
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Post"),
            ),
          ],
        );
      },
    );
  }
}
