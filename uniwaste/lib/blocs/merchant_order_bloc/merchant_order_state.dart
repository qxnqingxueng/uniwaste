import 'package:equatable/equatable.dart';

abstract class MerchantOrderState extends Equatable {
  const MerchantOrderState();
  @override
  List<Object> get props => [];
}

class MerchantOrdersLoading extends MerchantOrderState {}

class MerchantOrdersLoaded extends MerchantOrderState {
  final List<Map<String, dynamic>> activeOrders; // Orders to be cooked
  final List<Map<String, dynamic>> pastOrders;   // History

  const MerchantOrdersLoaded(this.activeOrders, this.pastOrders);

  @override
  List<Object> get props => [activeOrders, pastOrders];
}

class MerchantOrdersError extends MerchantOrderState {
  final String message;
  const MerchantOrdersError(this.message);

  @override
  List<Object> get props => [message];
}