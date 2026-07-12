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
  final bool isLinking;
  final String? linkError;

  const ParentLoaded({
    required this.children,
    this.selectedChildUid,
    required this.allVisitedUrls,
    required this.filteredVisitedUrls,
    this.latestReport,
    this.filterQuery = '',
    this.isAnalyzing = false,
    this.isLinking = false,
    this.linkError,
  });

  ParentLoaded copyWith({
    List<Map<String, dynamic>>? children,
    String? selectedChildUid,
    List<String>? allVisitedUrls,
    List<String>? filteredVisitedUrls,
    SafetyReport? latestReport,
    bool clearReport = false,
    String? filterQuery,
    bool? isAnalyzing,
    bool? isLinking,
    String? linkError,
    bool clearLinkError = false,
  }) {
    return ParentLoaded(
      children: children ?? this.children,
      selectedChildUid: selectedChildUid ?? this.selectedChildUid,
      allVisitedUrls: allVisitedUrls ?? this.allVisitedUrls,
      filteredVisitedUrls: filteredVisitedUrls ?? this.filteredVisitedUrls,
      latestReport: clearReport ? null : (latestReport ?? this.latestReport),
      filterQuery: filterQuery ?? this.filterQuery,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isLinking: isLinking ?? this.isLinking,
      linkError: clearLinkError ? null : (linkError ?? this.linkError),
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
        isLinking,
        linkError,
      ];
}

class ParentError extends ParentState {
  final String message;

  const ParentError({required this.message});

  @override
  List<Object?> get props => [message];
}
