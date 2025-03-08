import 'package:flutter/material.dart';
import 'package:horz/pages/ChatPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text("Messages")),
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('messages')
            .select(
                'sender_id, receiver_id, sender:users!messages_sender_id_fkey(name, profile_picture), receiver:users!messages_receiver_id_fkey(name, profile_picture)')
            .or('sender_id.eq.$userId,receiver_id.eq.$userId')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(child: Text("No messages yet"));
          }

          final messages = snapshot.data as List<dynamic>;

          // Collect unique users from messages
          final Set<String> chatUserIds = {};
          final List<dynamic> chatUsers = [];

          for (var message in messages) {
            final bool isSender = message['sender_id'] == userId;
            final String chatUserId =
                isSender ? message['receiver_id'] : message['sender_id'];

            if (!chatUserIds.contains(chatUserId)) {
              chatUserIds.add(chatUserId);
              chatUsers.add({
                'id': chatUserId,
                'name': isSender
                    ? message['receiver']['name']
                    : message['sender']['name'],
                'profile_picture': isSender
                    ? message['receiver']['profile_picture']
                    : message['sender']['profile_picture'],
              });
            }
          }

          return ListView.builder(
            itemCount: chatUsers.length,
            itemBuilder: (context, index) {
              final chatUser = chatUsers[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: chatUser['profile_picture'] != null
                      ? NetworkImage(chatUser['profile_picture'])
                      : null,
                  child: chatUser['profile_picture'] == null
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(chatUser['name']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatPage(receiverId: chatUser['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
