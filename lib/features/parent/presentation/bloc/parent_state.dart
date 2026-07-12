import 'package:equatable/equatable.dart';
import 'package:basera/core/models/safety_report.dart';

abstract class ParentState extends Equatable {
  const ParentState();

  @override
  List<Object?> get props => [];
}

class ParentInitial extends ParentState {}

class ParentLoading extends ParentState {}

class ParentProfilesLoaded extends ParentState {
  final List<Map<String, dynamic>> children;

  const ParentProfilesLoaded({required this.children});

  @override
  List<Object?> get props => [children];
}

class ParentLoaded extends ParentState {
  final List<Map<String, dynamic>> children;
  final String? selectedChildUid;
  final List<String> allVisitedUrls;
  final List<String> filteredVisitedUrls;
  final SafetyReport? latestReport;
  final String filterQuery;
  final bool isAnalyzing;

  const ParentLoaded({
    required this.children,
    this.selectedChildUid,
    required this.allVisitedUrls,
    required this.filteredVisitedUrls,
    this.latestReport,
    this.filterQuery = '',
    this.isAnalyzing = false,
  });

  ParentLoaded copyWith({
    List<Map<String, dynamic>>? children,
    String? selectedChildUid,
    List<String>? allVisitedUrls,
    List<String>? filteredVisitedUrls,
    SafetyReport? latestReport,
    String? filterQuery,
    bool? isAnalyzing,
  }) {
    return ParentLoaded(
      children: children ?? this.children,
      selectedChildUid: selectedChildUid ?? this.selectedChildUid,
      allVisitedUrls: allVisitedUrls ?? this.allVisitedUrls,
      filteredVisitedUrls: filteredVisitedUrls ?? this.filteredVisitedUrls,
      latestReport: latestReport ?? this.latestReport,
      filterQuery: filterQuery ?? this.filterQuery,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }

  @override
  List<Object?> get props => [
        children,
        selectedChildUid,
        allVisitedUrls,
        filteredVisitedUrls,
        latestReport,
        filterQuery,
        isAnalyzing,
      ];
}

class ParentError extends ParentState {
  final String message;

  const ParentError({required this.message});

  @override
  List<Object?> get props => [message];
}
