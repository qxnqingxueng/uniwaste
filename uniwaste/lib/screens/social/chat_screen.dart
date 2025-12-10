import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/social/chat_detail_screen.dart';
import 'package:uniwaste/services/chat_service.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  /// 1. Fetch profiles AND pre-cache images so they render instantly
  Future<Map<String, dynamic>> _preloadAllProfiles(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
  ) async {
    final Set<String> userIdsToFetch = {};
    final Map<String, dynamic> profileData = {}; // Stores {uid: {name, imageProvider}}

    // A. Identify all unique User IDs
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Map<String, dynamic> names = data['participantNames'] ?? {};

      names.forEach((key, val) {
        if (key != currentUserId) {
          userIdsToFetch.add(key);
        }
      });
    }

    // B. Fetch documents in parallel
    await Future.wait(userIdsToFetch.map((id) async {
      try {
        final snap =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          final String? base64Photo = data['photoBase64'];
          
          MemoryImage? imageProvider;

          // C. Decode and Pre-cache Image
          if (base64Photo != null && base64Photo.isNotEmpty) {
            try {
              final Uint8List bytes = base64Decode(base64Photo);
              imageProvider = MemoryImage(bytes);
              
              // CRITICAL: Wait for the image to be fully ready for display
              // ignore: use_build_context_synchronously
              if (context.mounted) {
                await precacheImage(imageProvider, context);
              }
            } catch (e) {
              debugPrint("Error decoding image for $id: $e");
            }
          }

          // Store the ready-to-use provider
          profileData[id] = {
            'data': data,
            'imageProvider': imageProvider,
          };
        }
      } catch (e) {
        debugPrint("Error fetching profile for $id: $e");
      }
    }));

    return profileData;
  }

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
        builder: (context, streamSnapshot) {
          // 1. Wait for Chat List Stream
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = streamSnapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
                child: Text("No chats yet. Claim food to start!"));
          }

          // 2. Wait for Profiles & Images (Pre-caching)
          return FutureBuilder<Map<String, dynamic>>(
            // Pass context so we can pre-cache
            future: _preloadAllProfiles(context, docs, user.userId),
            builder: (context, profilesSnapshot) {
              
              // SHOW SPINNER until images are decoded and ready
              if (profilesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final profiles = profilesSnapshot.data ?? {};

              // 3. Render List (Images will appear instantly now)
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final Map<String, dynamic> names =
                      data['participantNames'] ?? {};

                  // Identify other user
                  String otherName = "User";
                  String otherUserId = "";
                  names.forEach((key, val) {
                    if (key != user.userId) {
                      otherName = val;
                      otherUserId = key;
                    }
                  });

                  // Retrieve pre-loaded data
                  final userProfile = profiles[otherUserId];
                  final MemoryImage? imageProvider = userProfile?['imageProvider'];
                  
                  // Use the name from profile if available (fresher), else chat name
                  if (userProfile != null && userProfile['data']['name'] != null) {
                     otherName = userProfile['data']['name'];
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color.fromRGBO(210, 220, 182, 1),
                      backgroundImage: imageProvider, // pre-cached provider
                      child: imageProvider == null
                          ? Text(
                              otherName.isNotEmpty
                                  ? otherName[0].toUpperCase()
                                  : "?",
                            )
                          : null,
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 👉 Tap: open chat as before
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatId: docs[index].id,
                            currentUserId: user.userId,
                            otherUserId: otherUserId,
                            otherUserName: otherName,
                            itemName: data['itemName'] ?? 'Item',
                          ),
                        ),
                      );
                    },

                    // 👉 LONG PRESS: delete conversation
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Delete conversation?'),
                            content: Text(
                              'This will permanently delete your chat with $otherName for both of you.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        try {
                          await chatService.deleteChat(docs[index].id);

                          // Optional feedback
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Conversation with $otherName deleted'),
                              ),
                            );
                          }
                          // StreamBuilder will auto-refresh and remove the row
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Failed to delete conversation'),
                              ),
                            );
                          }
                        }
                      }
                    },
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