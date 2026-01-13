import 'package:equatable/equatable.dart';
import '../entities/entities.dart';

class MyUser extends Equatable {
  final String userId;
  final String email;
  final String name;
  final bool hasActiveCart;
  final double reputationScore;
  final int ratingCount;
  final int reportCount;
  final String role;

  const MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
    this.reputationScore = 100.0,
    this.ratingCount = 0,
    this.reportCount = 0,
    this.role = 'user', 
  });

  bool get isAdmin => role == 'admin';
  bool get isRestricted => reportCount >= 3 || reputationScore < 50.0;

  static const empty = MyUser(
    userId: '',
    email: '',
    name: '',
    hasActiveCart: false,
    reputationScore: 100.0,
    ratingCount: 0,
    reportCount: 0,
    role: 'user', 
  );

  MyUser copyWith({
    String? userId,
    String? email,
    String? name,
    bool? hasActiveCart,
    double? reputationScore,
    int? ratingCount,
    int? reportCount,
    String? role, 
  }) {
    return MyUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      hasActiveCart: hasActiveCart ?? this.hasActiveCart,
      reputationScore: reputationScore ?? this.reputationScore,
      ratingCount: ratingCount ?? this.ratingCount,
      reportCount: reportCount ?? this.reportCount,
      role: role ?? this.role, 
    );
  }

  MyUserEntity toEntity() {
    return MyUserEntity(
      userId: userId,
      email: email,
      name: name,
      hasActiveCart: hasActiveCart,
      reputationScore: reputationScore,
      ratingCount: ratingCount,
      reportCount: reportCount,
      role: role, 
    );
  }

  static MyUser fromEntity(MyUserEntity entity) {
    return MyUser(
      userId: entity.userId,
      email: entity.email,
      name: entity.name,
      hasActiveCart: entity.hasActiveCart,
      reputationScore: entity.reputationScore,
      ratingCount: entity.ratingCount,
      reportCount: entity.reportCount,
      role: entity.role, 
    );
  }

  @override
  List<Object?> get props => [userId, email, name, hasActiveCart, reputationScore, ratingCount, reportCount, role];
}