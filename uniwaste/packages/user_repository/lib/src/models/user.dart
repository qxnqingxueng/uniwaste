import '../entities/entities.dart';

class MyUser {
  String userId;
  String email;
  String name;
  bool hasActiveCart; // New field to indicate if the user has an active cart

  MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
  });

  static final empty = MyUser(
    userId: '',
    email: '',
    name: '',
    hasActiveCart: false,
  );

// Convert MyUser to MyUserEntity for database operations, gotta separate app class from database class
  MyUserEntity toEntity() {
    //MyUserEntity is only dealing with sending class to database,
    //MyUser object transforming into MyUserEntity object into Json map going to database
    return MyUserEntity(
      userId: userId,
      email: email,
      name: name,
      hasActiveCart: hasActiveCart,
    );
  }

  static MyUser fromEntity(MyUserEntity entity) {
    //Having an entry from json map from database, transforming Json map within MyUserEntity object, MyUserEntity object transform itself into MyUser object
    return MyUser(
      userId: entity.userId,
      email: entity.email,
      name: entity.name,
      hasActiveCart: entity.hasActiveCart,
    );
  }

  //2 entities method are created to take my user object and transform it

  @override
  String toString() {
    return 'MyUser{$userId, $email, $name, $hasActiveCart}';
  }
}
