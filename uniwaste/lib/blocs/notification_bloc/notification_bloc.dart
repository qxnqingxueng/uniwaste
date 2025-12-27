import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/services/chat_service.dart';
import 'package:uniwaste/services/notification_service.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _chatSubscription;

  NotificationBloc() : super(NotificationInitial()) {
    on<StartNotificationListener>(_onStartListening);
    on<StopNotificationListener>(_onStopListening);
  }

  Future<void> _onStartListening(
    StartNotificationListener event,
    Emitter<NotificationState> emit,
  ) async {
    // 1. Cancel any existing subscription to avoid duplicates
    await _chatSubscription?.cancel();
    emit(NotificationListening());

    // 2. Listen to the chat stream for the current user
    _chatSubscription = _chatService.getUserChats(event.userId).listen((snapshot) {
      // 3. Loop through changes (this handles ONLY changes, not the whole list)
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>;
        
        // We only care if the chat was 'modified' (new message in existing chat)
        // or 'added' (brand new chat).
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          
          final lastSenderId = data['lastSenderId'] as String?;
          final lastMessage = data['lastMessage'] as String?;
          final lastMessageTime = data['lastMessageTime'] as Timestamp?;

          // 4. FILTER: Don't notify if I sent the message
          if (lastSenderId != null && lastSenderId != event.userId) {
            
            // 5. TIMESTAMP CHECK: Ensure we don't notify for old messages on app startup
            // (Only notify if the message is less than 30 seconds old)
            if (lastMessageTime != null) {
              final now = DateTime.now();
              final msgTime = lastMessageTime.toDate();
              final difference = now.difference(msgTime).inSeconds;

              if (difference.abs() < 30) {
                 _notificationService.showNotification(
                  id: data.hashCode, // Unique ID for notification
                  title: 'New Message',
                  body: lastMessage ?? 'You received a message',
                  payload: data['chatId'], // Pass chatId to open it later
                );
              }
            }
          }
        }
      }
    });
  }

  Future<void> _onStopListening(
    StopNotificationListener event,
    Emitter<NotificationState> emit,
  ) async {
    await _chatSubscription?.cancel();
    emit(NotificationInitial());
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}