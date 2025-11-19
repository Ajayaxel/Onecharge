part of 'number_plate_bloc.dart';

enum NumberPlateStatus { initial, loading, success, failure }

class NumberPlateState extends Equatable {
  const NumberPlateState({
    this.status = NumberPlateStatus.initial,
    this.message,
    this.data,
    this.statusCode,
  });

  static const Object _noChange = Object();

  final NumberPlateStatus status;
  final String? message;
  final NumberPlateData? data;
  final int? statusCode;

  bool get isLoading => status == NumberPlateStatus.loading;
  bool get isSuccess => status == NumberPlateStatus.success;
  bool get isFailure => status == NumberPlateStatus.failure;

  NumberPlateState copyWith({
    NumberPlateStatus? status,
    Object? message = _noChange,
    Object? data = _noChange,
    Object? statusCode = _noChange,
  }) {
    return NumberPlateState(
      status: status ?? this.status,
      message: message == _noChange ? this.message : message as String?,
      data: data == _noChange ? this.data : data as NumberPlateData?,
      statusCode: statusCode == _noChange
          ? this.statusCode
          : statusCode as int?,
    );
  }

  @override
  List<Object?> get props => [status, message, data, statusCode];
}
