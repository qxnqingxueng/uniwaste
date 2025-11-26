import 'dart:developer';
import 'package:user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserRepo implements UserRepository {
  // Firebase implementation of UserRepository abstract class
  final FirebaseAuth
      _firebaseAuth; // Firebase Authentication instance, take FirebaseAuth as parameter
  final usersCollection = FirebaseFirestore.instance.collection(
      'users'); // reference of usersCollection within Firestore database

  FirebaseUserRepo({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

//Steam is a constant flow of data that change over time, like a continuous feed of information
  @override
  // TODO: implement user
  Stream<MyUser?> get user =>
      _firebaseAuth.authStateChanges().flatMap((firebaseUser) async* {
        //flatMap to convert Stream<User?> to Stream<MyUser?>, allowing to play with user object and change user object from firebase auth MyUser object
        if (firebaseUser == null) {
          yield MyUser.empty; //if no user logged in, return empty user object
        } else {
          //if user exists, fetch user data from Firestore
          yield* await usersCollection
              .doc(firebaseUser.uid)
              .get()
              .then((value) => MyUser.fromEntity(
                  //fetch user document from Firestore using uid, convert document data to MyUserEntity using fromDocument method, then convert MyUserEntity to MyUser using fromEntity method
                  MyUserEntity.fromDocument(value.data()!)))
              .asStream(); //asStream to convert Future<MyUser> to Stream<MyUser>
        }
      });

  //sign in existing user with email and password
  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      log(e.toString());
      rethrow; // Rethrow the caught exception to propagate it to the caller
    }
  }

  //User sign up with email and password, return MyUser object upon successful sign up
  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
    try {
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
          //firebase auth method to create user with email and password
          email: myUser.email,
          password: password);
      myUser.userId = user
          .user!.uid; //assign generated ID from firebase auth to myUser object
      return myUser; //return myUser object with assigned userId
    } catch (e) {
      log(e.toString());
      rethrow; // Rethrow the caught exception to propagate it to the caller
    }
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    // TODO: implement setUserData
    try {
      await usersCollection
          .doc(myUser
              .userId) //create document inside firestore,reference specific user document using userId
          .set(myUser
              .toEntity()
              .toDocument()); //convert MyUser to MyUserEntity (map) using toEntity method, then convert MyUserEntity to Map using toDocument method, finally set the document data in Firestore
    } catch (e) {
      log(e.toString());
      rethrow; // Rethrow the caught exception to propagate it to the caller
    }
  }
}

extension on Stream<User?> {
  Stream<MyUser> flatMap(Stream<MyUser> Function(dynamic firebaseUser) param0) {
    return this.asyncExpand((firebaseUser) {
      return param0(firebaseUser);
    });
  }
}

// library that we will export within UI within main code