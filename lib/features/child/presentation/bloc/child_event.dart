import 'package:equatable/equatable.dart';

abstract class ChildEvent extends Equatable {
  const ChildEvent();

  @override
  List<Object?> get props => [];
}

class LoadChildHistory extends ChildEvent {}

class VisitUrl extends ChildEvent {
  final String url;

  const VisitUrl({required this.url});

  @override
  List<Object?> get props => [url];
}

class ClearChildHistory extends ChildEvent {}
