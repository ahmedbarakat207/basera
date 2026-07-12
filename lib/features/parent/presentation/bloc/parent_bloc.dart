import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:basera/core/services/firebase_backend_service.dart';
import 'package:basera/core/services/basera_database.dart';
import 'package:basera/core/utils/groq_client.dart';
import 'package:basera/core/models/safety_report.dart';
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
  }

  Future<void> _onLoadChildren(LoadChildrenProfiles event, Emitter<ParentState> emit) async {
    emit(ParentLoading());
    try {
      final children = await _backendService.fetchChildrenProfiles();
      
      if (children.isNotEmpty) {
        add(SelectChildProfile(childUid: children.first['uid'] ?? 'mock-child-id'));
        emit(ParentLoaded(
          children: children,
          allVisitedUrls: const [],
          filteredVisitedUrls: const [],
        ));
      } else {
        // Local mockup fallback
        final localUrls = await BaseraDatabase.instance.getVisitedUrls();
        final localReport = await BaseraDatabase.instance.getSafetyReport('mock-child-id');
        emit(ParentLoaded(
          children: const [
            {'uid': 'mock-child-id', 'name': 'Demo Child Account'}
          ],
          selectedChildUid: 'mock-child-id',
          allVisitedUrls: localUrls,
          filteredVisitedUrls: localUrls,
          latestReport: localReport,
        ));
      }
    } catch (e) {
      // Offline fallback load
      final localUrls = await BaseraDatabase.instance.getVisitedUrls();
      final localReport = await BaseraDatabase.instance.getSafetyReport('mock-child-id');
      emit(ParentLoaded(
        children: const [
          {'uid': 'mock-child-id', 'name': 'Demo Child Account'}
        ],
        selectedChildUid: 'mock-child-id',
        allVisitedUrls: localUrls,
        filteredVisitedUrls: localUrls,
        latestReport: localReport,
      ));
    }
  }

  Future<void> _onSelectChild(SelectChildProfile event, Emitter<ParentState> emit) async {
    final currentState = state;
    if (currentState is ParentLoaded) {
      _urlsSubscription?.cancel();
      _reportSubscription?.cancel();

      emit(currentState.copyWith(
        selectedChildUid: event.childUid,
        allVisitedUrls: const [],
        filteredVisitedUrls: const [],
        latestReport: null,
      ));

      _urlsSubscription = _backendService.streamChildUrls(event.childUid).listen((urls) {
        add(UpdateChildUrls(urls: urls));
      }, onError: (e) {
        add(const UpdateChildUrls(urls: []));
      });

      _reportSubscription = _backendService.streamChildReport(event.childUid).listen((report) {
        add(UpdateChildReport(report: report));
      }, onError: (e) {
        add(const UpdateChildReport(report: null));
      });
    }
  }

  void _onUpdateUrls(UpdateChildUrls event, Emitter<ParentState> emit) {
    final currentState = state;
    if (currentState is ParentLoaded) {
      final filtered = _filterList(event.urls, currentState.filterQuery);
      emit(currentState.copyWith(
        allVisitedUrls: event.urls,
        filteredVisitedUrls: filtered,
      ));
    }
  }

  void _onUpdateReport(UpdateChildReport event, Emitter<ParentState> emit) {
    final currentState = state;
    if (currentState is ParentLoaded) {
      emit(currentState.copyWith(latestReport: event.report));
    }
  }

  Future<void> _onRunAnalysis(RunAiAnalysis event, Emitter<ParentState> emit) async {
    final currentState = state;
    if (currentState is ParentLoaded && currentState.selectedChildUid != null) {
      emit(currentState.copyWith(isAnalyzing: true));
      try {
        final report = await _groqClient.analyzeUrls(event.urls);
        final targetUid = currentState.selectedChildUid!;
        
        await _backendService.syncSafetyReport(targetUid, report);
        await BaseraDatabase.instance.saveSafetyReport(targetUid, report);

        emit(currentState.copyWith(
          isAnalyzing: false,
          latestReport: report,
        ));
      } catch (e) {
        emit(currentState.copyWith(isAnalyzing: false));
      }
    }
  }

  void _onFilterUrls(FilterUrls event, Emitter<ParentState> emit) {
    final currentState = state;
    if (currentState is ParentLoaded) {
      final filtered = _filterList(currentState.allVisitedUrls, event.query);
      emit(currentState.copyWith(
        filterQuery: event.query,
        filteredVisitedUrls: filtered,
      ));
    }
  }

  List<String> _filterList(List<String> urls, String query) {
    if (query.isEmpty) return urls;
    final lowerQuery = query.toLowerCase();
    return urls.where((u) => u.toLowerCase().contains(lowerQuery)).toList();
  }

  Future<void> _onClearData(ClearParentData event, Emitter<ParentState> emit) async {
    await BaseraDatabase.instance.clearHistory();
    await BaseraDatabase.instance.clearAllReports();
    add(LoadChildrenProfiles());
  }

  @override
  Future<void> close() {
    _urlsSubscription?.cancel();
    _reportSubscription?.cancel();
    return super.close();
  }
}
