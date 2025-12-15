import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // for base64Decode
import 'dart:typed_data'; // for Uint8List / MemoryImage
import 'friend_profile_screen.dart';
import 'package:uniwaste/services/chat_service.dart';
import 'package:uniwaste/screens/social/chat_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  static const Color _accent = Color(0xFFA1BC98);
  static const Color _bgTop = Color(0xFFF1F3E0);

  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<_Friend> _friendRequests = [];
  List<_Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // ---------------------------------------------------------------------------
  // LOAD FRIENDS + REQUESTS
  // ---------------------------------------------------------------------------
  Future<void> _loadFriends() async {
    if (!mounted) return;

    // show loading spinner while we fetch
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _friendRequests = [];
        _friends = [];
      });
      return;
    }

    try {
      final meRef = _firestore.collection('users').doc(user.uid);
      final meSnap = await meRef.get();

      final data = meSnap.data() ?? {};

      final incomingIds = List<String>.from(
        data['incomingRequests'] ?? const [],
      );
      final friendIds = List<String>.from(data['friends'] ?? const []);

      Future<List<_Friend>> fetchUsers(List<String> ids) async {
        if (ids.isEmpty) return [];
        final futures =
            ids
                .map((id) => _firestore.collection('users').doc(id).get())
                .toList();
        final snaps = await Future.wait(futures);

        return snaps.where((s) => s.exists).map((s) {
          final d = s.data() as Map<String, dynamic>;
          final email = (d['email'] ?? '') as String;
          final name =
              (d['name'] ?? (email.isNotEmpty ? email : 'Unknown')) as String;

          String? avatarBase64 = d['photoBase64'] as String?;
          MemoryImage? avatarImage;
          if (avatarBase64 != null && avatarBase64.isNotEmpty) {
            try {
              final bytes = base64Decode(avatarBase64);
              avatarImage = MemoryImage(bytes); // 👈 create provider once
            } catch (e) {
              debugPrint('Error decoding avatar for ${s.id}: $e');
            }
          }

          return _Friend(
            uid: s.id,
            name: name,
            email: email,
            avatarBase64: avatarBase64,
            avatarImage: avatarImage, // 👈 pass in
          );
        }).toList();
      }

      final requests = await fetchUsers(incomingIds);
      final friends = await fetchUsers(friendIds);

      // 👇 Pre-cache all friend avatars before we turn loading off
      await _precacheAvatars([...requests, ...friends]);

      if (!mounted) return;
      setState(() {
        _friendRequests = requests;
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
      if (mounted) {
        _showSnack('Failed to load friends.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 🔥 hide loader when done
        });
      }
    }
  }

  Future<void> _precacheAvatars(List<_Friend> users) async {
    for (final f in users) {
      final img = f.avatarImage;
      if (img == null) continue;

      try {
        await precacheImage(img, context);
      } catch (e) {
        debugPrint('Error precaching avatar for ${f.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // FRIEND ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> _sendFriendRequest(_Friend target) async {
    final me = _auth.currentUser;
    if (me == null) return;

    try {
      final meRef = _firestore.collection('users').doc(me.uid);
      final otherRef = _firestore.collection('users').doc(target.uid);

      final batch = _firestore.batch();
      batch.update(meRef, {
        'outgoingRequests': FieldValue.arrayUnion([target.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(otherRef, {
        'incomingRequests': FieldValue.arrayUnion([me.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _showSnack('Friend request sent to ${target.name}.');
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      _showSnack('Failed to send friend request.');
    }
  }

  Future<void> _acceptRequest(_Friend f) async {
    final me = _auth.currentUser;
    if (me == null) return;

    try {
      final meRef = _firestore.collection('users').doc(me.uid);
      final otherRef = _firestore.collection('users').doc(f.uid);

      final batch = _firestore.batch();
      batch.update(meRef, {
        'incomingRequests': FieldValue.arrayRemove([f.uid]),
        'friends': FieldValue.arrayUnion([f.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(otherRef, {
        'outgoingRequests': FieldValue.arrayRemove([me.uid]),
        'friends': FieldValue.arrayUnion([me.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _friendRequests.removeWhere((x) => x.uid == f.uid);
        _friends.add(f);
      });

      _showSnack('You are now friends with ${f.name}.');
    } catch (e) {
      debugPrint('Error accepting request: $e');
      _showSnack('Failed to accept request.');
    }
  }

  Future<void> _ignoreRequest(_Friend f) async {
    final me = _auth.currentUser;
    if (me == null) return;

    try {
      final meRef = _firestore.collection('users').doc(me.uid);
      final otherRef = _firestore.collection('users').doc(f.uid);

      final batch = _firestore.batch();
      batch.update(meRef, {
        'incomingRequests': FieldValue.arrayRemove([f.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(otherRef, {
        'outgoingRequests': FieldValue.arrayRemove([me.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _friendRequests.removeWhere((x) => x.uid == f.uid);
      });

      _showSnack('Request ignored.');
    } catch (e) {
      debugPrint('Error ignoring request: $e');
      _showSnack('Failed to ignore request.');
    }
  }

  // NEW: remove friend from both sides
  Future<void> _removeFriend(_Friend f) async {
    final me = _auth.currentUser;
    if (me == null) return;

    try {
      final meRef = _firestore.collection('users').doc(me.uid);
      final otherRef = _firestore.collection('users').doc(f.uid);

      final batch = _firestore.batch();
      batch.update(meRef, {
        'friends': FieldValue.arrayRemove([f.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(otherRef, {
        'friends': FieldValue.arrayRemove([me.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _friends.removeWhere((x) => x.uid == f.uid);
      });

      _showSnack('Removed ${f.name} from your friends.');
    } catch (e) {
      debugPrint('Error removing friend: $e');
      _showSnack('Failed to remove friend.');
    }
  }

  // show bottom sheet with "Remove friend" & "View Profile"
  void _showFriendOptions(_Friend friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Wrap(
            children: [
              // Chat with friend
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chat with friend'),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();

                  // Get current user from AuthenticationBloc
                  final authState = context.read<AuthenticationBloc>().state;
                  final currentUser = authState.user!;

                  final String currentUserId = currentUser.userId;
                  final String currentUserName =
                      currentUser.name; // or displayName, adjust field
                  final String otherUserId = friend.uid;

                  final chatId = await _chatService.getOrCreateChat(
                    userAId: currentUserId,
                    userBId: otherUserId,
                    currentUserName: currentUserName,
                    otherUserName: friend.name,
                  );

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatDetailScreen(
                            chatId: chatId,
                            currentUserId: currentUserId,
                            otherUserId: otherUserId,
                            otherUserName: friend.name,
                            itemName:
                                'Friend chat', // or data from Firestore if you want
                          ),
                    ),
                  );
                },
              ),

              // 👉 View profile
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FriendProfileScreen(
                            name: friend.name,
                            email: friend.email,
                            avatarBase64: friend.avatarBase64,
                          ),
                    ),
                  );
                },
              ),

              // 👉 Remove friend
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('Remove friend'),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: const Text('Remove friend?'),
                        content: Text(
                          'Are you sure you want to remove ${friend.name} from your friends?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await _removeFriend(friend);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ADD FRIEND DIALOG
  // ---------------------------------------------------------------------------

  void _openAddFriendDialog() {
    final emailController = TextEditingController();
    _Friend? foundUser;
    String? errorText;
    bool searching = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleSearch() async {
              final me = _auth.currentUser;
              if (me == null) return;

              final input = emailController.text.trim();
              final email = input.toLowerCase();

              if (email.isEmpty || !email.contains('@')) {
                setStateDialog(() {
                  errorText = 'Please enter a valid email.';
                  foundUser = null;
                });
                return;
              }

              setStateDialog(() {
                searching = true;
                errorText = null;
                foundUser = null;
              });

              try {
                final q =
                    await _firestore
                        .collection('users')
                        .where('email', isEqualTo: email)
                        .limit(1)
                        .get();

                if (q.docs.isEmpty) {
                  setStateDialog(() {
                    errorText = 'No user found with this email.';
                  });
                } else {
                  final doc = q.docs.first;
                  final me = _auth.currentUser;
                  if (me != null && doc.id == me.uid) {
                    setStateDialog(() {
                      errorText = 'You cannot add yourself.';
                    });
                  } else {
                    final d = doc.data();
                    final name =
                        (d['name'] ?? d['email'] ?? 'Unknown') as String;
                    final String? avatarBase64 = d['photoBase64'] as String?;
                    MemoryImage? avatarImage;
                    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
                      try {
                        final bytes = base64Decode(avatarBase64);
                        avatarImage = MemoryImage(bytes);
                      } catch (e) {
                        debugPrint('Error decoding avatar in dialog: $e');
                      }
                    }

                    final friend = _Friend(
                      uid: doc.id,
                      name: name,
                      email: (d['email'] ?? '') as String,
                      avatarBase64: avatarBase64,
                      avatarImage: avatarImage, // 👈 pass it here
                    );

                    final alreadyFriend = _friends.any(
                      (x) => x.uid == friend.uid,
                    );
                    final alreadyRequested =
                        _friendRequests.any((x) => x.uid == friend.uid) ||
                        (d['incomingRequests'] is List &&
                            (d['incomingRequests'] as List).contains(me?.uid));

                    if (alreadyFriend) {
                      errorText = 'You are already friends.';
                      foundUser = null;
                    } else if (alreadyRequested) {
                      errorText = 'You already have a pending request.';
                      foundUser = null;
                    } else {
                      foundUser = friend;
                    }

                    setStateDialog(() {});
                  }
                }
              } catch (e) {
                debugPrint('Search error: $e');
                setStateDialog(() {
                  errorText = 'Search failed. Please try again.';
                });
              } finally {
                setStateDialog(() {
                  searching = false;
                });
              }
            }

            Future<void> handleSendRequest() async {
              if (foundUser == null) return;
              await _sendFriendRequest(foundUser!);
              if (mounted) {
                Navigator.of(dialogContext).pop();
                _loadFriends();
              }
            }

            return AlertDialog(
              backgroundColor: _bgTop,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 12),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              title: const Text(
                'Add friend',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Friend's email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        errorText: errorText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: searching ? null : handleSearch,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _accent),
                            foregroundColor: _accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              searching
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black87,
                                      ),
                                    ),
                                  )
                                  : const Text('Search'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (foundUser != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            _buildAvatar(foundUser!, radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    foundUser!.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    foundUser!.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: handleSendRequest,
                              child: const Text('Send request'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasRequests = _friendRequests.isNotEmpty;
    final hasFriends = _friends.isNotEmpty;
    final hasAnything = hasRequests || hasFriends;

    return Scaffold(
      backgroundColor: _bgTop, // 🔥 same colour as body
      appBar: AppBar(
        backgroundColor: _bgTop,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'My Friends',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        color: _bgTop, // solid background, no gradient
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddFriendsButton(),
                      const SizedBox(height: 24),

                      if (!hasAnything) _buildEmptyState(),

                      if (hasRequests) ...[
                        const Text(
                          'Requests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children:
                              _friendRequests
                                  .map((f) => _buildRequestCard(f))
                                  .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (hasFriends) ...[
                        const Text(
                          'Your friends',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children:
                              _friends.map((f) => _buildFriendRow(f)).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildAddFriendsButton() {
    return GestureDetector(
      onTap: _openAddFriendDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _accent.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined, size: 20, color: _accent),
            SizedBox(width: 6),
            Text(
              'Add friends',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 40, bottom: 12),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No friends yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              "Tap “Add friends” to invite your coursemates.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(_Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(friend, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(friend),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _ignoreRequest(friend),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('Ignore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRow(_Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.6),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _buildAvatar(friend, radius: 27),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 22),
            onPressed: () => _showFriendOptions(friend),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_Friend friend, {double radius = 20}) {
    // 1. If we already have a cached image provider, use it
    if (friend.avatarImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _accent.withOpacity(0.2),
        backgroundImage: friend.avatarImage!,
      );
    }

    // 2. (Optional) Fallback: if only base64 is present but no image –
    //    this can happen for some temporary objects like search result.
    final String? base64 = friend.avatarBase64;
    if (base64 != null && base64.isNotEmpty) {
      try {
        final bytes = base64Decode(base64);
        return CircleAvatar(
          radius: radius,
          backgroundColor: _accent.withOpacity(0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // ignore and fall back to initial
      }
    }

    // 3. Final fallback: initial letter
    final String initial =
        friend.name.trim().isNotEmpty
            ? friend.name.trim()[0].toUpperCase()
            : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: _accent.withOpacity(0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius - 4,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF5C6C4A),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Friend {
  final String uid;
  final String name;
  final String email;
  final String? avatarBase64;
  final MemoryImage? avatarImage;

  _Friend({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarBase64,
    this.avatarImage,
  });
}
