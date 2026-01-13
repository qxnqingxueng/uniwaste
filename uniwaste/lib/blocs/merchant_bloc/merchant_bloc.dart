import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:merchant_repository/merchant_repository.dart';
part 'merchant_event.dart';
part 'merchant_state.dart';

// Bloc to manage merchant data
class MerchantBloc extends Bloc<MerchantEvent, MerchantState> {
  final MerchantRepository _merchantRepository;

  MerchantBloc({required MerchantRepository merchantRepository})
    : _merchantRepository = merchantRepository,
      super(MerchantLoading()) {
    on<LoadMerchants>(_onLoadMerchants);
  }

  // Handler for loading merchants
  Future<void> _onLoadMerchants(
    LoadMerchants event,
    Emitter<MerchantState> emit,
  ) async {
    // Listen to the stream from the repository
    await emit.forEach<List<Merchant>>(
      _merchantRepository.getMerchants(),
      // Map stream data to states
      onData: (merchants) => MerchantLoaded(merchants),
      // Map errors to error state
      onError: (error, stackTrace) => MerchantError(error.toString()),
    );
  }
}
