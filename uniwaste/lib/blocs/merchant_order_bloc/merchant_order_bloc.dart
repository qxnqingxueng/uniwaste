import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'merchant_order_event.dart';
import 'merchant_order_state.dart';

class MerchantOrderBloc extends Bloc<MerchantOrderEvent, MerchantOrderState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MerchantOrderBloc() : super(MerchantOrdersLoading()) {
    on<LoadMerchantOrders>(_onLoadOrders);
    on<UpdateOrderStatus>(_onUpdateStatus);
  }

  Future<void> _onLoadOrders(
    LoadMerchantOrders event,
    Emitter<MerchantOrderState> emit,
  ) async {
    // Listen to the 'orders' collection in real-time
    await emit.forEach<QuerySnapshot>(
      _firestore
          .collection('orders')
          // Assuming your order data has a 'items' list and we check the first item's merchantId
          // simpler approach for MVP: Add a 'merchantId' field to the main order document
          // OR: Filter client-side if your DB structure is complex.
          // For now, let's assume you added 'merchantId' to the order document in CheckoutScreen.
          .where('merchantId', isEqualTo: event.merchantId) 
          .orderBy('orderDate', descending: true)
          .snapshots(),
      onData: (snapshot) {
        final allOrders = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Split into Active vs Past
        final active = allOrders.where((o) => ['paid', 'accepted', 'ready'].contains(o['status'])).toList();
        final past = allOrders.where((o) => ['completed', 'rejected', 'cancelled'].contains(o['status'])).toList();

        return MerchantOrdersLoaded(active, past);
      },
      onError: (e, _) => MerchantOrdersError(e.toString()),
    );
  }

  Future<void> _onUpdateStatus(
    UpdateOrderStatus event,
    Emitter<MerchantOrderState> emit,
  ) async {
    try {
      await _firestore.collection('orders').doc(event.orderId).update({
        'status': event.newStatus,
      });
    } catch (e) {
      print("Error updating status: $e");
    }
  }
}