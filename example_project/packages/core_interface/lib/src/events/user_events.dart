import '../models/user.dart';

/// 用户事件基类
abstract class UserEvent {
  final DateTime timestamp;
  final String eventId;
  
  UserEvent()
      : timestamp = DateTime.now(),
        eventId = DateTime.now().millisecondsSinceEpoch.toString();
}

/// 用户登录事件
class UserLoggedInEvent extends UserEvent {
  final User user;
  
  UserLoggedInEvent(this.user);
  
  @override
  String toString() => 'UserLoggedInEvent(user: ${user.id}, timestamp: $timestamp)';
}

/// 用户登出事件
class UserLoggedOutEvent extends UserEvent {
  final User user;
  
  UserLoggedOutEvent(this.user);
  
  @override
  String toString() => 'UserLoggedOutEvent(user: ${user.id}, timestamp: $timestamp)';
}

/// 用户信息更新事件
class UserUpdatedEvent extends UserEvent {
  final User oldUser;
  final User newUser;
  
  UserUpdatedEvent(this.oldUser, this.newUser);
  
  @override
  String toString() => 'UserUpdatedEvent(userId: ${newUser.id}, timestamp: $timestamp)';
}

/// 用户删除事件
class UserDeletedEvent extends UserEvent {
  final String userId;
  
  UserDeletedEvent(this.userId);
  
  @override
  String toString() => 'UserDeletedEvent(userId: $userId, timestamp: $timestamp)';
}
