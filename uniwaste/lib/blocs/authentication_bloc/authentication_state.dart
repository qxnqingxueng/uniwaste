part of 'authentication_bloc.dart';

enum AuthenticationStatus { authenticated, unauthenticated, unknown }

class AuthenticationState extends Equatable {
  final AuthenticationStatus status;
  final MyUser? user; // This MyUser now comes from the import below

  const AuthenticationState._({
    this.status = AuthenticationStatus.unknown,
    this.user,
  });

  // Constructor for Unknown state
  const AuthenticationState.unknown() : this._();

  // Constructor for Authenticated state
  const AuthenticationState.authenticated(MyUser user)
      : this._(status: AuthenticationStatus.authenticated, user: user);

  // Constructor for Unauthenticated state
  const AuthenticationState.unauthenticated()
      : this._(status: AuthenticationStatus.unauthenticated);

  @override
  List<Object?> get props => [status, user];
}
