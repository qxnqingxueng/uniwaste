part of 'notification_bloc.dart';

abstract class NotificationEvent {}

class StartNotificationListener extends NotificationEvent {
  final String userId;
  StartNotificationListener(this.userId);
}

class StopNotificationListener extends NotificationEvent {}