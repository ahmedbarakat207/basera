import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:basera/core/services/firebase_backend_service.dart';
import 'package:basera/core/services/basera_database.dart';
import 'package:basera/core/services/sync_service.dart';
import 'package:basera/core/utils/groq_client.dart';
import 'child_event.dart';
import 'child_state.dart';

class ChildBloc extends Bloc<ChildEvent, ChildState> {
  final FirebaseBackendService _backendService = FirebaseBackendService.instance;

  ChildBloc() : super(ChildHistoryInitial()) {
    on<LoadChildHistory>(_onLoadHistory);
    on<VisitUrl>(_onVisitUrl);
    on<ClearChildHistory>(_onClearHistory);
  }

  Future<void> _onLoadHistory(LoadChildHistory event, Emitter<ChildState> emit) async {
    emit(ChildHistoryLoading());
    try {
      final urls = await BaseraDatabase.instance.getVisitedUrls();
      emit(ChildHistoryLoaded(urls: urls));
    } catch (e) {
      emit(ChildHistoryError(message: 'Failed to load local history: ${e.toString()}'));
    }
  }

  Future<void> _onVisitUrl(VisitUrl event, Emitter<ChildState> emit) async {
    try {
      await _backendService.syncUrlVisit(event.url);
      
      // Auto-trigger sync check in case internet restored
      SyncService.instance.syncPendingData();
      
      final urls = await BaseraDatabase.instance.getVisitedUrls();

      // Trigger automatic AI analysis at visit time to keep reports updated
      try {
        final childUid = _backendService.currentUser?.uid ?? 'mock-child-id';
        final report = await GroqClient().analyzeUrls(urls, childId: childUid);
        
        await _backendService.syncSafetyReport(childUid, report);
        await BaseraDatabase.instance.saveSafetyReport(childUid, report);
      } catch (e) {
        debugPrint('Auto-AI analysis failed: $e');
      }

      emit(ChildHistoryLoaded(urls: urls));
    } catch (e) {
      emit(ChildHistoryError(message: 'Failed to record URL visit: ${e.toString()}'));
    }
  }

  Future<void> _onClearHistory(ClearChildHistory event, Emitter<ChildState> emit) async {
    emit(ChildHistoryLoading());
    try {
      await BaseraDatabase.instance.clearHistory();
      emit(const ChildHistoryLoaded(urls: []));
    } catch (e) {
      emit(ChildHistoryError(message: 'Failed to clear local history: ${e.toString()}'));
    }
  }
}
