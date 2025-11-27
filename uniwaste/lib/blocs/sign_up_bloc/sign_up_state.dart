part of 'sign_up_bloc.dart';

abstract class SignUpState extends Equatable {
  const SignUpState();
  
  @override
  List<Object> get props => [];
}

class SignUpInitial extends SignUpState {}

class SignUpProcess extends SignUpState {}

class SignUpSuccess extends SignUpState {}

class SignUpFailure extends SignUpState {
  final String? message;

  const SignUpFailure({this.message});

  @override
  List<Object> get props => [message ?? 'An unknown error occurred'];
}