import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:merchant_repository/merchant_repository.dart';

// ✅ These lines connect the Event and State files to this one
part 'merchant_event.dart';
part 'merchant_state.dart';

class MerchantBloc extends Bloc<MerchantEvent, MerchantState> {
  final MerchantRepository _merchantRepository;

  MerchantBloc({required MerchantRepository merchantRepository})
    : _merchantRepository = merchantRepository,
      super(MerchantLoading()) {
    on<LoadMerchants>(_onLoadMerchants);
  }

  Future<void> _onLoadMerchants(
    LoadMerchants event,
    Emitter<MerchantState> emit,
  ) async {
    // Listen to the stream from the repository
    await emit.forEach<List<Merchant>>(
      _merchantRepository.getMerchants(),
      onData: (merchants) => MerchantLoaded(merchants),
      onError: (error, stackTrace) => MerchantError(error.toString()),
    );
  }
}
