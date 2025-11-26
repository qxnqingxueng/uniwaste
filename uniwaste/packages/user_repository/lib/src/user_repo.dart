//class we will called within our app
import 'models/models.dart';

abstract class UserRepository {
  Stream<MyUser?> get user; // Stream to listen for authentication state changes
  Future<MyUser> signUp(MyUser myUser, String password); // Sign up a new user
  Future<void> setUserData(MyUser user); // Set user data in the database
  Future<void> signIn(
      String email, String password); // Sign in an existing user
  Future<void> logOut(); // Log out the current user
}
