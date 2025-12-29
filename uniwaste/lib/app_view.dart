import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/home/home_screen.dart';
import 'package:uniwaste/screens/auth/auth_wrapper.dart';
import 'package:uniwaste/services/notification_service.dart';
import 'package:uniwaste/screens/waste-to-resources/company/waste_collection_screen.dart';
import 'package:uniwaste/services/chat_service.dart';

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  State<MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initNotificationService();
  }

  void _initNotificationService() async {
    final service = NotificationService();
    await service.init();

    // Listen for notification clicks
    service.onNotificationClick.listen((payload) {
      if (payload == 'waste_collection') {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const WasteCollectionScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'University Waste Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(210, 220, 182, 0.3),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          if (state.status == AuthenticationStatus.authenticated) {
            return ChatNotificationsWrapper(
              userId: state.user!.userId,
              child: const HomeScreen(),
            );
          } else {
            return const AuthWrapper();
          }
        },
      ),
    );
  }
}

// Listens to chat stream and shows notifications
class ChatNotificationsWrapper extends StatefulWidget {
  final Widget child;
  final String userId;

  const ChatNotificationsWrapper({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<ChatNotificationsWrapper> createState() =>
      _ChatNotificationsWrapperState();
}

class _ChatNotificationsWrapperState extends State<ChatNotificationsWrapper> {
  // Store timestamps to detect NEW messages only
  final Map<String, Timestamp> _lastMessageTimestamps = {};
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    // We use a StreamBuilder to listen to changes in the background
    return StreamBuilder<QuerySnapshot>(
      stream: ChatService().getUserChats(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _checkNewMessages(snapshot.data!.docs);
        }
        return widget.child;
      },
    );
  }

  void _checkNewMessages(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? timestamp = data['lastMessageTime'];
      final String? lastSenderId = data['lastSenderId'];
      final String chatId = doc.id;

      if (timestamp == null) continue;

      // 1. Initial Load: Just populate the cache, don't notify
      if (_isFirstLoad) {
        _lastMessageTimestamps[chatId] = timestamp;
        continue;
      }

      // 2. Check if this is a NEW message (time is greater than what we saw last)
      if (_lastMessageTimestamps.containsKey(chatId)) {
        if (timestamp.compareTo(_lastMessageTimestamps[chatId]!) > 0) {
          _triggerNotification(data, chatId, lastSenderId);
          _lastMessageTimestamps[chatId] = timestamp;
        }
      } else {
        // New chat started
        _triggerNotification(data, chatId, lastSenderId);
        _lastMessageTimestamps[chatId] = timestamp;
      }
    }

    if (_isFirstLoad) {
      _isFirstLoad = false;
    }
  }

  void _triggerNotification(
    Map<String, dynamic> data,
    String chatId,
    String? lastSenderId,
  ) {
    // Don't notify if I sent the message
    if (lastSenderId == widget.userId) return;

    final String message = data['lastMessage'] ?? 'New Message';

    // Determine sender name
    String senderName = 'Friend';
    final Map<String, dynamic> names = data['participantNames'] ?? {};
    if (lastSenderId != null && names.containsKey(lastSenderId)) {
      senderName = names[lastSenderId];
    }

    NotificationService().showNotification(
      id: chatId.hashCode,
      title: senderName,
      body: message,
      payload: 'chat_message',
    );
  }
}
