import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations._(this._strings);

  static Map<String, dynamic> _cache = {};

  final Map<String, dynamic> _strings;

  static Future<void> load() async {
    final raw = await rootBundle.loadString('lib/core/i18n/en_us.json');
    _cache = jsonDecode(raw) as Map<String, dynamic>;
  }

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations._(_cache);
  }

  String translate(String key) {
    final segments = key.split('.');
    dynamic current = _strings;
    for (final segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return key;
      }
    }
    if (current is String) {
      return current;
    }
    return key;
  }
}
