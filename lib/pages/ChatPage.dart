import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Chat Page for real-time messaging
class ChatPage extends StatefulWidget {
  final String receiverId;

  ChatPage({required this.receiverId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final userId = Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: Supabase.instance.client.from('messages').stream(
                  primaryKey: ['id']).order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                final messages = snapshot.data as List<dynamic>;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['sender_id'] == userId;
                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                              color: isSender ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: "Type a message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (text.isEmpty || currentUser == null) {
      debugPrint("User not logged in or empty message.");
      return;
    }

    final userId = currentUser.id; // Fetch userId dynamically

    // Ensure sender exists in the users table
    final senderExists = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (senderExists == null) {
      debugPrint("Sender does not exist in users table.");
      return;
    }

    // Ensure receiver exists in users table
    final receiverExists = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('id', widget.receiverId)
        .maybeSingle();

    if (receiverExists == null) {
      debugPrint("Receiver does not exist in users table.");
      return;
    }

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': userId,
        'receiver_id': widget.receiverId,
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });

      _messageController.clear();
      setState(() {}); // Refresh UI after sending message
    } catch (error) {
      debugPrint("Error sending message: $error");
    }
  }
}
