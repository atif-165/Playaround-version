import 'dart:convert';

import 'package:flutter/services.dart';

import '../../presentation/core/providers/auth_state_provider.dart';

class DashboardRepository {
  DashboardRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Map<String, dynamic>? _cache;

  Future<DashboardData> fetchDashboardData(AppUserRole role) async {
    _cache ??= await _loadData();
    final roleKey = _roleKey(role);
    final raw = _cache![roleKey] as Map<String, dynamic>? ??
        _cache![_roleKey(AppUserRole.player)] as Map<String, dynamic>;
    return DashboardData.fromJson(raw);
  }

  Future<Map<String, dynamic>> _loadData() async {
    final raw = await _bundle.loadString('mocks/dashboard.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  String _roleKey(AppUserRole role) {
    switch (role) {
      case AppUserRole.player:
        return 'player';
      case AppUserRole.coach:
        return 'coach';
      case AppUserRole.teamOwner:
        return 'team_owner';
      case AppUserRole.admin:
        return 'admin';
      case AppUserRole.mvp:
        return 'mvp';
      case AppUserRole.guest:
        return 'guest';
    }
  }
}

class DashboardData {
  DashboardData({
    required this.headline,
    required this.stats,
    required this.events,
    required this.highlights,
    required this.actions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      headline: json['headline'] as String? ?? '',
      stats: (json['stats'] as List<dynamic>? ?? [])
          .map((item) => DashboardStat.fromJson(item as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>? ?? [])
          .map((item) => DashboardEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
      highlights: (json['highlights'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String headline;
  final List<DashboardStat> stats;
  final List<DashboardEvent> events;
  final List<String> highlights;
  final List<String> actions;
}

class DashboardStat {
  DashboardStat({
    required this.label,
    required this.value,
    required this.delta,
  });

  factory DashboardStat.fromJson(Map<String, dynamic> json) {
    return DashboardStat(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      delta: (json['delta'] as num?)?.toDouble() ?? 0,
    );
  }

  final String label;
  final String value;
  final double delta;
}

class DashboardEvent {
  DashboardEvent({
    required this.title,
    required this.date,
    required this.location,
    required this.status,
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String title;
  final String date;
  final String location;
  final String status;
}
