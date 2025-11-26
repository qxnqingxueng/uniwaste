class MyUserEntity {
  String userId;
  String email;
  String name;
  bool hasActiveCart; // New field to indicate if the user has an active cart

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
  });

// Convert MyUserEntity to a Map for database storage because we cannot store/send MyUser object directly in database/ Firestore
// Have to send formatted data like Json map
// Database only understand key value pair map, string, int, bool, double, list, map but dont understand custom class object
// Have to convert custom class object into map before sending to database
  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'hasActiveCart': hasActiveCart,
    };
  }

// Convert a Map from the database back into a MyUserEntity object
  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'] as String,
      email: doc['email'] as String,
      name: doc['name'] as String,
      hasActiveCart: doc['hasActiveCart'] as bool,
    );
  }
}
