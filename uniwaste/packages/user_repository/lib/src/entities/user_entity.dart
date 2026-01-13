class MyUserEntity {
  String userId;
  String email;
  String name;
  bool hasActiveCart;
  double reputationScore;
  int ratingCount;
  int reportCount;
  String role; 

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
    this.reputationScore = 100.0,
    this.ratingCount = 0,
    this.reportCount = 0,
    this.role = 'user', 
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'hasActiveCart': hasActiveCart,
      'reputationScore': reputationScore,
      'ratingCount': ratingCount,
      'reportCount': reportCount,
      'role': role, // ✅ Add this
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'] as String,
      email: doc['email'] as String,
      name: doc['name'] as String,
      hasActiveCart: doc['hasActiveCart'] as bool,
      reputationScore: (doc['reputationScore'] as num?)?.toDouble() ?? 100.0,
      ratingCount: (doc['ratingCount'] as num?)?.toInt() ?? 0,
      reportCount: (doc['reportCount'] as num?)?.toInt() ?? 0,
      role: doc['role'] as String? ?? 'user', 
    );
  }
}