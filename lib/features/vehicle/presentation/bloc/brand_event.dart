part of 'brand_bloc.dart';

sealed class BrandEvent extends Equatable {
  const BrandEvent();

  @override
  List<Object?> get props => [];
}

class BrandsFetched extends BrandEvent {
  const BrandsFetched({
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  List<Object?> get props => [categoryId, categoryName];
}

