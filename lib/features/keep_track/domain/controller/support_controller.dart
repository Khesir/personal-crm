import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crm/core/state/stream_state.dart';
import 'package:crm/core/state/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasource/support_datasource.dart';
import '../../presentation/state/support_state.dart';

const _kSeenIdsKey = 'support_seen_ids';

class SupportController extends StreamState<AsyncState<List<SupportTicket>>> {
  final SupportDatasource _datasource;
  final SharedPreferences _prefs;
  String? _statusFilter;
  Set<String> _seenIds = {};

  final ValueNotifier<bool> hasUnreadNotifier = ValueNotifier(false);

  SupportController(this._datasource, this._prefs) : super(const AsyncLoading()) {
    final raw = _prefs.getString(_kSeenIdsKey);
    if (raw != null) {
      _seenIds = (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
    }
  }

  bool isSeen(String id) => _seenIds.contains(id);

  void _recomputeBadge(List<SupportTicket> tickets) {
    hasUnreadNotifier.value = tickets.any((t) => !_seenIds.contains(t.id));
  }

  Future<void> load({String? status}) async {
    _statusFilter = status;
    emit(const AsyncLoading());
    try {
      final tickets = await _datasource.fetchAll(status: status);
      emit(AsyncData(tickets));
      _recomputeBadge(tickets);
    } catch (e) {
      emit(AsyncError('Failed to load tickets', e));
    }
  }

  Future<void> markTicketSeen(String id) async {
    if (_seenIds.contains(id)) return;
    _seenIds = {..._seenIds, id};
    await _prefs.setString(_kSeenIdsKey, jsonEncode(_seenIds.toList()));
    emit(state);
    final s = state;
    if (s is AsyncData<List<SupportTicket>>) _recomputeBadge(s.data);
  }

  Future<void> updateStatus(String id, TicketStatus status) async {
    await _datasource.updateTicket(id, status: status.value);
    await load(status: _statusFilter);
  }

  Future<void> saveNote(String id, String note) async {
    await _datasource.updateTicket(id, adminNote: note);
    await load(status: _statusFilter);
  }

  Future<void> delete(String id) async {
    await _datasource.deleteTicket(id);
    await load(status: _statusFilter);
  }

  @override
  void dispose() {
    hasUnreadNotifier.dispose();
    super.dispose();
  }
}
