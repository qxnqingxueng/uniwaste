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
  StreamSubscription? _binSubscription; 

  NotificationBloc() : super(NotificationInitial()) {
    on<StartNotificationListener>(_onStartListening);
    on<StopNotificationListener>(_onStopListening);
  }

  Future<void> _onStartListening(
    StartNotificationListener event,
    Emitter<NotificationState> emit,
  ) async {
    await _chatSubscription?.cancel();
    await _binSubscription?.cancel();
    
    emit(NotificationListening());


    _chatSubscription = _chatService.getUserChats(event.userId).listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>;
        
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          
          final lastSenderId = data['lastSenderId'] as String?;
          final lastMessage = data['lastMessage'] as String?;
          final lastMessageTime = data['lastMessageTime'] as Timestamp?;

          if (lastSenderId != null && lastSenderId != event.userId) {
            
            if (lastMessageTime != null) {
              final now = DateTime.now();
              final msgTime = lastMessageTime.toDate();
              final difference = now.difference(msgTime).inSeconds;

              if (difference.abs() < 30) {
                 _notificationService.showNotification(
                  id: data.hashCode, 
                  title: 'New Message',
                  body: lastMessage ?? 'You received a message',
                  payload: data['chatId'], 
                );
              }
            }
          }
        }
      }
    });

      _binSubscription = FirebaseFirestore.instance
        .collection('waste_bins')
        .snapshots()
        .listen((snapshot) {
      print("📡 FIRESTORE EVENT RECEIVED: ${snapshot.docChanges.length} changes");

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final fillLevel = data['fillLevel'];
          final binName = data['name'] ?? 'Bin';

          print("🔍 Bin Modified: $binName, Level: $fillLevel"); 


          if (fillLevel == 100 || fillLevel == 100.0) {
            print("✅ TRIGGERING NOTIFICATION FOR $binName"); 
            
            _notificationService.showNotification(
              id: change.doc.id.hashCode,
              title: "Bin Full Alert",
              body: "Bin $binName is at 100% capacity",
              payload: 'waste_collection',
            );
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
    await _binSubscription?.cancel();
    emit(NotificationInitial());
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    _binSubscription?.cancel();
    return super.close();
  }
}