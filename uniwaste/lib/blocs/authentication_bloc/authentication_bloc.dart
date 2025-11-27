import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:user_repository/user_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final UserRepository userRepository;
  late final StreamSubscription<MyUser?> _userSubscription;

  AuthenticationBloc({required this.userRepository})
      : super(const AuthenticationState.unknown()) {
    
    // 1. Subscribe to user changes from Firebase
    _userSubscription = userRepository.user.listen(
      (user) => add(AuthenticationUserChanged(user)),
    );

    // 2. Handle the event when user changes (Automatic)
    on<AuthenticationUserChanged>((event, emit) {
      if (event.user != MyUser.empty) {
        emit(AuthenticationState.authenticated(event.user!));
      } else {
        emit(const AuthenticationState.unauthenticated());
      }
    });

    // 3. FIX: Handle the Logout Event (Manual)
    on<AuthenticationLogoutRequested>((event, emit) {
      userRepository.logOut();
    });
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}