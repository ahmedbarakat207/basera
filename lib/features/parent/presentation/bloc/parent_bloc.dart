import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:basera/core/services/firebase_backend_service.dart';
import 'package:basera/core/services/basera_database.dart';
import 'package:basera/core/utils/groq_client.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'parent_event.dart';
import 'parent_state.dart';

class ParentBloc extends Bloc<ParentEvent, ParentState> {
  final FirebaseBackendService _backendService = FirebaseBackendService.instance;
  final GroqClient _groqClient = GroqClient();

  StreamSubscription? _urlsSubscription;
  StreamSubscription? _reportSubscription;

  ParentBloc() : super(ParentInitial()) {
    on<LoadChildrenProfiles>(_onLoadChildren);
    on<SelectChildProfile>(_onSelectChild);
    on<UpdateChildUrls>(_onUpdateUrls);
    on<UpdateChildReport>(_onUpdateReport);
    on<RunAiAnalysis>(_onRunAnalysis);
    on<FilterUrls>(_onFilterUrls);
    on<ClearParentData>(_onClearData);
    on<LinkChildAccount>(_onLinkChild);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD CHILDREN (scoped to this parent's linked_children[])
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadChildren(
    LoadChildrenProfiles event,
    Emitter<ParentState> emit,
  ) async {
    emit(ParentLoading());
    try {
      await _backendService.updateFcmToken();
      final children = await _backendService.fetchChildren();

      if (children.isNotEmpty) {
        final firstUid = children.first['uid'] as String? ?? 'mock-child-id';
        emit(ParentLoaded(
          children: children,
          allVisitedUrls: const [],
          filteredVisitedUrls: const [],
        ));
        // Auto-select first child and start streaming
        add(SelectChildProfile(childUid: firstUid));
      } else {
        // No linked children yet — show empty state
        emit(ParentLoaded(
          children: const [],
          allVisitedUrls: const [],
          filteredVisitedUrls: const [],
        ));
      }
    } catch (e) {
      // Offline fallback — read from local SQLite
      final localUrls = await BaseraDatabase.instance.getVisitedUrls();
      final localReport = await BaseraDatabase.instance.getSafetyReport('mock-child-id');
      emit(ParentLoaded(
        children: const [
          {'uid': 'mock-child-id', 'name': 'Demo Child (Offline)'}
        ],
        selectedChildUid: 'mock-child-id',
        allVisitedUrls: localUrls,
        filteredVisitedUrls: localUrls,
        latestReport: localReport,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECT CHILD — start Firestore real-time streams
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onSelectChild(
    SelectChildProfile event,
    Emitter<ParentState> emit,
  ) async {
    final currentState = state;
    if (currentState is ParentLoaded) {
      // Cancel previous subscriptions
      _urlsSubscription?.cancel();
      _reportSubscription?.cancel();

      emit(currentState.copyWith(
        selectedChildUid: event.childUid,
        allVisitedUrls: const [],
        filteredVisitedUrls: const [],
        clearReport: true,
      ));

      // Subscribe to child's URL list in real-time
      _urlsSubscription = _backendService
          .streamChildUrls(event.childUid)
          .listen(
            (urls) => add(UpdateChildUrls(urls: urls)),
            onError: (_) => add(const UpdateChildUrls(urls: [])),
          );

      // Subscribe to child's safety report in real-time
      _reportSubscription = _backendService
          .streamChildReport(event.childUid)
          .listen(
            (report) => add(UpdateChildReport(report: report)),
            onError: (_) => add(const UpdateChildReport(report: null)),
          );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STREAM UPDATES
  // ─────────────────────────────────────────────────────────────────────────

  void _onUpdateUrls(UpdateChildUrls event, Emitter<ParentState> emit) {
    final s = state;
    if (s is ParentLoaded) {
      final filtered = _filterList(event.urls, s.filterQuery);
      emit(s.copyWith(
        allVisitedUrls: event.urls,
        filteredVisitedUrls: filtered,
      ));
    }
  }

  void _onUpdateReport(UpdateChildReport event, Emitter<ParentState> emit) {
    final s = state;
    if (s is ParentLoaded) {
      if (event.report != null) {
        emit(s.copyWith(latestReport: event.report));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI ANALYSIS — uses STREAMED URLs from Firestore (not a stale local list)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onRunAnalysis(
    RunAiAnalysis event,
    Emitter<ParentState> emit,
  ) async {
    final s = state;
    if (s is! ParentLoaded || s.selectedChildUid == null) return;

    // Always analyze the live URLs currently displayed (streamed from Firestore)
    final urlsToAnalyze = s.allVisitedUrls;
    if (urlsToAnalyze.isEmpty) return;

    emit(s.copyWith(isAnalyzing: true));
    try {
      final childUid = s.selectedChildUid!;
      final report = await _groqClient.analyzeUrls(
        urlsToAnalyze,
        childId: childUid,
      );

      // Save report to child's Firestore doc → parent stream picks it up automatically
      await _backendService.syncSafetyReport(childUid, report);
      await BaseraDatabase.instance.saveSafetyReport(childUid, report);

      emit(s.copyWith(isAnalyzing: false, latestReport: report));
    } catch (e) {
      emit(s.copyWith(isAnalyzing: false));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LINK CHILD ACCOUNT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLinkChild(
    LinkChildAccount event,
    Emitter<ParentState> emit,
  ) async {
    final s = state;
    if (s is! ParentLoaded) return;

    emit(s.copyWith(isLinking: true, clearLinkError: true));
    try {
      final childData = await _backendService.linkChildAccount(
        childEmail: event.childEmail,
        childPassword: event.childPassword,
      );

      // Add newly linked child to the list if not already present
      final updatedChildren = List<Map<String, dynamic>>.from(s.children);
      final alreadyExists = updatedChildren.any(
        (c) => c['uid'] == childData['uid'],
      );
      if (!alreadyExists) updatedChildren.add(childData);

      final newState = s.copyWith(
        isLinking: false,
        children: updatedChildren,
        clearLinkError: true,
      );
      emit(newState);

      // Auto-select the newly linked child
      add(SelectChildProfile(childUid: childData['uid'] as String));
    } catch (e) {
      emit(s.copyWith(
        isLinking: false,
        linkError: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FILTER & CLEAR
  // ─────────────────────────────────────────────────────────────────────────

  void _onFilterUrls(FilterUrls event, Emitter<ParentState> emit) {
    final s = state;
    if (s is ParentLoaded) {
      emit(s.copyWith(
        filterQuery: event.query,
        filteredVisitedUrls: _filterList(s.allVisitedUrls, event.query),
      ));
    }
  }

  Future<void> _onClearData(
    ClearParentData event,
    Emitter<ParentState> emit,
  ) async {
    await BaseraDatabase.instance.clearHistory();
    await BaseraDatabase.instance.clearAllReports();
    await ChildHistoryService.instance.clearHistory();
    add(LoadChildrenProfiles());
  }

  List<String> _filterList(List<String> urls, String query) {
    if (query.isEmpty) return urls;
    return urls.where((u) => u.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<void> close() {
    _urlsSubscription?.cancel();
    _reportSubscription?.cancel();
    return super.close();
  }
}
