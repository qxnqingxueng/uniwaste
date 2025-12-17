import 'package:equatable/equatable.dart';

abstract class MerchantOrderEvent extends Equatable {
  const MerchantOrderEvent();
  @override
  List<Object> get props => [];
}

// Event: Start listening to orders for this merchant
class LoadMerchantOrders extends MerchantOrderEvent {
  final String merchantId;
  const LoadMerchantOrders(this.merchantId);

  @override
  List<Object> get props => [merchantId];
}

// Event: Merchant clicks "Accept" or "Reject"
class UpdateOrderStatus extends MerchantOrderEvent {
  final String orderId;
  final String newStatus; // e.g., 'accepted', 'ready', 'completed'

  const UpdateOrderStatus(this.orderId, this.newStatus);

  @override
  List<Object> get props => [orderId, newStatus];
}