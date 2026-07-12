import 'package:equatable/equatable.dart';
import 'package:basera/core/utils/groq_client.dart';

abstract class ParentEvent extends Equatable {
  const ParentEvent();

  @override
  List<Object?> get props => [];
}

class LoadChildrenProfiles extends ParentEvent {}

class SelectChildProfile extends ParentEvent {
  final String childUid;

  const SelectChildProfile({required this.childUid});

  @override
  List<Object?> get props => [childUid];
}

class UpdateChildUrls extends ParentEvent {
  final List<String> urls;

  const UpdateChildUrls({required this.urls});

  @override
  List<Object?> get props => [urls];
}

class UpdateChildReport extends ParentEvent {
  final SafetyReport? report;

  const UpdateChildReport({required this.report});

  @override
  List<Object?> get props => [report];
}

class RunAiAnalysis extends ParentEvent {
  final List<String> urls;

  const RunAiAnalysis({required this.urls});

  @override
  List<Object?> get props => [urls];
}

class FilterUrls extends ParentEvent {
  final String query;

  const FilterUrls({required this.query});

  @override
  List<Object?> get props => [query];
}

class ClearParentData extends ParentEvent {}
