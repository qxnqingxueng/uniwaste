import 'dart:async';
import 'dart:developer';
import 'package:user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final usersCollection = FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<MyUser?> get user {
    // 1. Create a controller to manage the output stream manually
    final controller = StreamController<MyUser?>();
    
    // Keep track of the Firestore subscription so we can cancel it when the user changes
    StreamSubscription<DocumentSnapshot>? firestoreSubscription;

    // 2. Listen to Firebase Auth changes (Login / Logout)
    final authSubscription = _firebaseAuth.authStateChanges().listen((firebaseUser) {
      
      // Cancel the previous Firestore listener immediately (Prevent overlapping/deadlock)
      firestoreSubscription?.cancel();
      firestoreSubscription = null;

      if (firebaseUser == null) {
        // User Logged Out: Emit empty user
        controller.add(MyUser.empty);
      } else {
        // User Logged In: Listen to their Firestore document
        firestoreSubscription = usersCollection
            .doc(firebaseUser.uid)
            .snapshots()
            .handleError((e) {
              // Handle potential permission errors during logout gracefully
              log('Firestore stream error: $e');
            })
            .listen((snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                try {
                  controller.add(
                    MyUser.fromEntity(
                      MyUserEntity.fromDocument(snapshot.data()!)
                    )
                  );
                } catch (e) {
                  log('Error parsing user data: $e');
                  controller.add(MyUser.empty);
                }
              } else {
                controller.add(MyUser.empty);
              }
            });
      }
    });

    // 3. Cleanup: Cancel all subscriptions when the stream is no longer needed
    controller.onCancel = () {
      firestoreSubscription?.cancel();
      authSubscription.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
    try {
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
          email: myUser.email, password: password);

      myUser = myUser.copyWith(userId: user.user!.uid);

      return myUser;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    try {
      await usersCollection
          .doc(myUser.userId)
          .set(myUser.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}