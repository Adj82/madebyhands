import 'package:flutter_bloc/flutter_bloc.dart';

class BuyerCubit extends Cubit<int> {
  BuyerCubit() : super(0);

  void changePage(int index) => emit(index);
}
