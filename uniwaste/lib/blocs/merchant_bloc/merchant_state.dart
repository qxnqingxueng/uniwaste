part of 'merchant_bloc.dart';

abstract class MerchantState extends Equatable {
  const MerchantState();

  @override
  List<Object> get props => [];
}

class MerchantLoading extends MerchantState {}

class MerchantLoaded extends MerchantState {
  final List<Merchant> merchants;

  const MerchantLoaded(this.merchants);

  @override
  List<Object> get props => [merchants];
}

class MerchantError extends MerchantState {
  final String message;

  const MerchantError(this.message);

  @override
  List<Object> get props => [message];
}
