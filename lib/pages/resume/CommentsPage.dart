import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../UserDetailsPage.dart';

final supabase = Supabase.instance.client;

class CommentsPage extends StatefulWidget {
  final String resumeId;

  CommentsPage({required this.resumeId});

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  List<Map<String, dynamic>> comments = [];
  final TextEditingController commentController = TextEditingController();
  String? userId = supabase.auth.currentUser?.id;
  Map<String, bool> expandedReplies = {}; // Tracks which replies are expanded

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      final response = await supabase
          .from('comments')
          .select('*, users(id, name, profile_picture, is_public)')
          .eq('resume_id', widget.resumeId)
          .order('created_at', ascending: true);

      setState(() {
        comments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    }
  }

  Future<void> postComment(String text, {String? parentId}) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please sign in to comment.")),
      );
      return;
    }

    try {
      await supabase.from('comments').insert({
        'user_id': userId,
        'resume_id': widget.resumeId,
        'comment': text,
        'created_at': DateTime.now().toIso8601String(),
        'parent_comment_id': parentId,
      });

      commentController.clear();
      fetchComments();
    } catch (e) {
      debugPrint("Error posting comment: $e");
    }
  }

  // Get top-level comments (without a parent)
  List<Map<String, dynamic>> get topLevelComments {
    return comments.where((c) => c['parent_comment_id'] == null).toList();
  }

  // Get replies for a given comment
  List<Map<String, dynamic>> getReplies(String parentId) {
    List<Map<String, dynamic>> replies =
        comments.where((c) => c['parent_comment_id'] == parentId).toList();
    replies.sort((a, b) => DateTime.parse(a['created_at'])
        .compareTo(DateTime.parse(b['created_at'])));
    return replies;
  }

  Widget buildCommentWidget(Map<String, dynamic> comment,
      {bool isReply = false, int depth = 0}) {
    final user = comment['users'];
    final String displayName = (user != null && user['is_public'] == true)
        ? user['name']
        : "Anonymous";
    final String? profilePic = (user != null && user['is_public'] == true)
        ? user['profile_picture']
        : null;
    final String text = comment['comment'] ?? "";
    final String timestamp = DateFormat('dd MMM, hh:mm a')
        .format(DateTime.parse(comment['created_at']));
    final String commentId = comment['id'];

    return Container(
      margin: EdgeInsets.only(
          left: depth * 16.0, top: 6, bottom: 6), // Indentation for replies
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture with Navigation
          GestureDetector(
            onTap: () {
              if (user != null && user['is_public'] == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailsPage(userId: user['id']),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 18,
              backgroundImage:
                  profilePic != null ? NetworkImage(profilePic) : null,
              child: profilePic == null ? Icon(Icons.person, size: 18) : null,
            ),
          ),
          SizedBox(width: 8),
          // Comment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and Timestamp
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(timestamp,
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                // Comment Text
                Text(text, style: TextStyle(fontSize: 14)),
                // Reply Button
                TextButton(
                  onPressed: () => _showReplyDialog(commentId),
                  child: Text("Reply",
                      style: TextStyle(fontSize: 12, color: Colors.blue)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCommentItem(Map<String, dynamic> comment, {int depth = 0}) {
    List<Map<String, dynamic>> replies = getReplies(comment['id']);
    bool isExpanded = expandedReplies[comment['id']] ?? false;
    int repliesToShow =
        isExpanded ? replies.length : (replies.length > 3 ? 3 : replies.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCommentWidget(comment, isReply: depth > 0, depth: depth),
        if (replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < repliesToShow; i++)
                  buildCommentItem(replies[i], depth: depth + 1),
                if (replies.length > 3 && !isExpanded)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        expandedReplies[comment['id']] = true;
                      });
                    },
                    child: Text("View ${replies.length - 3} more replies",
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                if (isExpanded && replies.length > 3)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        expandedReplies[comment['id']] = false;
                      });
                    },
                    child: Text("Hide replies", style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _showReplyDialog(String parentCommentId) {
    TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reply to Comment"),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(hintText: "Write a reply..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              postComment(replyController.text, parentId: parentCommentId);
              Navigator.pop(context);
            },
            child: Text("Reply"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: topLevelComments.length,
              itemBuilder: (context, index) {
                return buildCommentItem(topLevelComments[index]);
              },
            ),
          ),
          // Comment Input Field
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: commentController,
                        decoration:
                            InputDecoration(hintText: "Write a comment..."))),
                IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => postComment(commentController.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
