part of 'number_plate_bloc.dart';

abstract class NumberPlateEvent extends Equatable {
  const NumberPlateEvent();

  @override
  List<Object?> get props => [];
}

class NumberPlateSubmitted extends NumberPlateEvent {
  const NumberPlateSubmitted({required this.plateNumber});

  final String plateNumber;

  @override
  List<Object?> get props => [plateNumber];
}

class NumberPlateReset extends NumberPlateEvent {
  const NumberPlateReset();
}
