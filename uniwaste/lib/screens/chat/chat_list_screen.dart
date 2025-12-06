import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/chat/chat_detail_screen.dart';
import 'package:uniwaste/services/chat_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);
    if (user == null) return const Center(child: Text("Sign in to view chats"));

    final ChatService chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getUserChats(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No chats yet. Claim food to start!"));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // 1. Identify Other User ID & Name
              final Map<String, dynamic> names = data['participantNames'] ?? {};
              String otherName = "User";
              String otherUserId = "";

              names.forEach((key, val) {
                if (key != user.userId) {
                  otherName = val;
                  otherUserId = key;
                }
              });

              return ListTile(
                leading: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    Uint8List? imageBytes;
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      if (userData['photoBase64'] != null && userData['photoBase64'].isNotEmpty) {
                        try {
                          imageBytes = base64Decode(userData['photoBase64']);
                        } catch (e) {
                          // Handle decode error silently
                        }
                      }
                    }

                    return CircleAvatar(
                      backgroundColor: const Color.fromRGBO(210, 220, 182, 1),
                      backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                      child: imageBytes == null
                          ? Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : "?")
                          : null,
                    );
                  },
                ),
                title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  data['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatId: docs[index].id,
                        currentUserId: user.userId,
                        otherUserId: otherUserId, // Passing the ID now
                        otherUserName: otherName,
                        itemName: data['itemName'] ?? 'Item',
                      ),
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