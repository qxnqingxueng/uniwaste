import 'package:equatable/equatable.dart';

// States for Merchant Order Bloc
abstract class MerchantOrderState extends Equatable {
  const MerchantOrderState();
  @override
  List<Object> get props => [];
}

// Loading state
class MerchantOrdersLoading extends MerchantOrderState {}

// Loaded state with active and past orders
class MerchantOrdersLoaded extends MerchantOrderState {
  final List<Map<String, dynamic>> activeOrders; // Orders to be cooked
  final List<Map<String, dynamic>> pastOrders; // History

  const MerchantOrdersLoaded(this.activeOrders, this.pastOrders);

  @override
  List<Object> get props => [activeOrders, pastOrders];
}

// Error state
class MerchantOrdersError extends MerchantOrderState {
  final String message;
  const MerchantOrdersError(this.message);

  @override
  List<Object> get props => [message];
}
