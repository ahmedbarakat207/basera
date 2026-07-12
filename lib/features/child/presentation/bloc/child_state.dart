import 'package:equatable/equatable.dart';

abstract class ChildState extends Equatable {
  const ChildState();

  @override
  List<Object?> get props => [];
}

class ChildHistoryInitial extends ChildState {}

class ChildHistoryLoading extends ChildState {}

class ChildHistoryLoaded extends ChildState {
  final List<String> urls;

  const ChildHistoryLoaded({required this.urls});

  @override
  List<Object?> get props => [urls];
}

class ChildHistoryError extends ChildState {
  final String message;

  const ChildHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
