part of 'model_bloc.dart';

sealed class ModelState extends Equatable {
  const ModelState();

  @override
  List<Object?> get props => [];
}

final class ModelInitial extends ModelState {
  const ModelInitial();
}

final class ModelLoading extends ModelState {
  const ModelLoading();
}

final class ModelLoaded extends ModelState {
  const ModelLoaded(this.models);

  final List<SubModel> models;

  @override
  List<Object?> get props => [models];
}

final class ModelEmpty extends ModelState {
  const ModelEmpty();
}

final class ModelError extends ModelState {
  const ModelError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

