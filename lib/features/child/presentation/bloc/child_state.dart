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
  final bool isAnalyzing;
  final bool? isLatestVisitHarmful;

  const ChildHistoryLoaded({
    required this.urls,
    this.isAnalyzing = false,
    this.isLatestVisitHarmful,
  });

  @override
  List<Object?> get props => [urls, isAnalyzing, isLatestVisitHarmful];
}

class ChildHistoryError extends ChildState {
  final String message;

  const ChildHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
