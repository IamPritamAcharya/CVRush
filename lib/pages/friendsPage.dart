import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final String? userId = Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Friends")),
        body: Center(child: Text("Please log in to see friends.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Friends")),
      body: Column(
        children: [
          Expanded(child: _buildConnectionsList()),
          Divider(),
          Expanded(child: _buildRequestsList()),
        ],
      ),
    );
  }

  // Fetch and display confirmed connections
  Widget _buildConnectionsList() {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('connections')
          .select(
              'receiver_id, sender_id, users:receiver_id(name, profile_picture)')
          .or('(sender_id.eq.$userId,receiver_id.eq.$userId)')
          .eq('status', 'accepted'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text("No friends yet"));
        }

        final connections = snapshot.data as List<dynamic>;

        return ListView.builder(
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            final isSender = connection['sender_id'] == userId;
            final friendId =
                isSender ? connection['receiver_id'] : connection['sender_id'];
            final friend = connection['users'];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(friend['profile_picture'] ?? ""),
              ),
              title: Text(friend['name']),
            );
          },
        );
      },
    );
  }

  // Fetch and display pending friend requests
  Widget _buildRequestsList() {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('connections')
          .select('sender_id, users:sender_id(name, profile_picture)')
          .eq('receiver_id', userId!)
          .eq('status', 'pending'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text("No pending requests"));
        }

        final requests = snapshot.data as List<dynamic>;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final sender = requests[index]['users'];
            final senderId = requests[index]['sender_id'];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(sender['profile_picture'] ?? ""),
              ),
              title: Text(sender['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _updateRequestStatus(senderId, 'accepted'),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _updateRequestStatus(senderId, 'rejected'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Accept or Reject Connection Requests
  Future<void> _updateRequestStatus(String? senderId, String status) async {
    if (userId == null || senderId == null) return; // Ensure both are non-null

    await Supabase.instance.client
        .from('connections')
        .update({'status': status}).match({
      'sender_id': senderId,
      'receiver_id': userId!
    }); // Use non-null values

    setState(() {}); // Refresh UI after updating request status
  }
}
