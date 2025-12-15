part of 'merchant_bloc.dart';

abstract class MerchantEvent extends Equatable {
  const MerchantEvent();

  @override
  List<Object> get props => [];
}

class LoadMerchants extends MerchantEvent {}
