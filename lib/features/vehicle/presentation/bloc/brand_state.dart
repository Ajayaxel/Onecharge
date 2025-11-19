part of 'brand_bloc.dart';

sealed class BrandState extends Equatable {
  const BrandState();

  @override
  List<Object?> get props => [];
}

final class BrandInitial extends BrandState {
  const BrandInitial();
}

final class BrandLoading extends BrandState {
  const BrandLoading();
}

final class BrandLoaded extends BrandState {
  const BrandLoaded(this.brands);

  final List<Brand> brands;

  @override
  List<Object?> get props => [brands];
}

final class BrandEmpty extends BrandState {
  const BrandEmpty();
}

final class BrandError extends BrandState {
  const BrandError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

