// lib/statistics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Définition de l'énumération pour les menus
enum StatisticsMenu { general, week }

// Classe pour représenter les réglages des statistiques
class StatisticsSettings {
  final StatisticsMenu selectedMenu;
  final bool showTotalSessions;
  final bool showTotalWeight;
  final bool showWeeklySessions;
  final bool showWeeklyWeight;
  final bool showWeeklyTime;
  final bool showWeeklyChart;
  final List<String> generalOrder;
  final List<String> weekOrder;

  StatisticsSettings({
    required this.selectedMenu,
    required this.showTotalSessions,
    required this.showTotalWeight,
    required this.showWeeklySessions,
    required this.showWeeklyWeight,
    required this.showWeeklyTime,
    required this.showWeeklyChart,
    required this.generalOrder,
    required this.weekOrder,
  });

  StatisticsSettings copyWith({
    StatisticsMenu? selectedMenu,
    bool? showTotalSessions,
    bool? showTotalWeight,
    bool? showWeeklySessions,
    bool? showWeeklyWeight,
    bool? showWeeklyTime,
    bool? showWeeklyChart,
    List<String>? generalOrder,
    List<String>? weekOrder,
  }) {
    return StatisticsSettings(
      selectedMenu: selectedMenu ?? this.selectedMenu,
      showTotalSessions: showTotalSessions ?? this.showTotalSessions,
      showTotalWeight: showTotalWeight ?? this.showTotalWeight,
      showWeeklySessions: showWeeklySessions ?? this.showWeeklySessions,
      showWeeklyWeight: showWeeklyWeight ?? this.showWeeklyWeight,
      showWeeklyTime: showWeeklyTime ?? this.showWeeklyTime,
      showWeeklyChart: showWeeklyChart ?? this.showWeeklyChart,
      generalOrder: generalOrder ?? this.generalOrder,
      weekOrder: weekOrder ?? this.weekOrder,
    );
  }
}

// Provider pour les réglages des statistiques
final statisticsSettingsProvider =
    StateNotifierProvider<StatisticsSettingsNotifier, StatisticsSettings>(
        (ref) {
  return StatisticsSettingsNotifier();
});

// StateNotifier qui gère les réglages des statistiques
class StatisticsSettingsNotifier extends StateNotifier<StatisticsSettings> {
  StatisticsSettingsNotifier()
      : super(StatisticsSettings(
          selectedMenu: StatisticsMenu.general,
          showTotalSessions: true,
          showTotalWeight: true,
          showWeeklySessions: true,
          showWeeklyWeight: true,
          showWeeklyTime: true,
          showWeeklyChart: true,
          generalOrder: ['general_sessions', 'general_weight'],
          weekOrder: [
            'weekly_sessions',
            'weekly_weight',
            'weekly_time',
            'weekly_chart'
          ],
        )) {
    _loadSettings();
  }

  // Charger les réglages depuis SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedMenuStr = prefs.getString('selected_menu');
    final selectedMenu = selectedMenuStr == 'week'
        ? StatisticsMenu.week
        : StatisticsMenu.general;
    final showTotalSessions = prefs.getBool('show_total_sessions') ?? true;
    final showTotalWeight = prefs.getBool('show_total_weight') ?? true;
    final showWeeklySessions = prefs.getBool('show_weekly_sessions') ?? true;
    final showWeeklyWeight = prefs.getBool('show_weekly_weight') ?? true;
    final showWeeklyTime = prefs.getBool('show_weekly_time') ?? true;
    final showWeeklyChart = prefs.getBool('show_weekly_chart') ?? true;
    final generalOrder = prefs.getStringList('general_order') ??
        ['general_sessions', 'general_weight'];
    final weekOrder = prefs.getStringList('week_order') ??
        ['weekly_sessions', 'weekly_weight', 'weekly_time', 'weekly_chart'];

    state = state.copyWith(
      selectedMenu: selectedMenu,
      showTotalSessions: showTotalSessions,
      showTotalWeight: showTotalWeight,
      showWeeklySessions: showWeeklySessions,
      showWeeklyWeight: showWeeklyWeight,
      showWeeklyTime: showWeeklyTime,
      showWeeklyChart: showWeeklyChart,
      generalOrder: generalOrder,
      weekOrder: weekOrder,
    );
  }

  // Sauvegarder les réglages dans SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_menu',
        state.selectedMenu == StatisticsMenu.general ? 'general' : 'week');
    await prefs.setBool('show_total_sessions', state.showTotalSessions);
    await prefs.setBool('show_total_weight', state.showTotalWeight);
    await prefs.setBool('show_weekly_sessions', state.showWeeklySessions);
    await prefs.setBool('show_weekly_weight', state.showWeeklyWeight);
    await prefs.setBool('show_weekly_time', state.showWeeklyTime);
    await prefs.setBool('show_weekly_chart', state.showWeeklyChart);
    await prefs.setStringList('general_order', state.generalOrder);
    await prefs.setStringList('week_order', state.weekOrder);
  }

  // Méthodes pour mettre à jour les réglages
  Future<void> setSelectedMenu(StatisticsMenu menu) async {
    state = state.copyWith(selectedMenu: menu);
    await _saveSettings();
  }

  Future<void> toggleShowTotalSessions(bool value) async {
    state = state.copyWith(showTotalSessions: value);
    await _saveSettings();
  }

  Future<void> toggleShowTotalWeight(bool value) async {
    state = state.copyWith(showTotalWeight: value);
    await _saveSettings();
  }

  Future<void> toggleShowWeeklySessions(bool value) async {
    state = state.copyWith(showWeeklySessions: value);
    await _saveSettings();
  }

  Future<void> toggleShowWeeklyWeight(bool value) async {
    state = state.copyWith(showWeeklyWeight: value);
    await _saveSettings();
  }

  Future<void> toggleShowWeeklyTime(bool value) async {
    state = state.copyWith(showWeeklyTime: value);
    await _saveSettings();
  }

  Future<void> toggleShowWeeklyChart(bool value) async {
    state = state.copyWith(showWeeklyChart: value);
    await _saveSettings();
  }

  Future<void> setGeneralOrder(List<String> order) async {
    state = state.copyWith(generalOrder: order);
    await _saveSettings();
  }

  Future<void> setWeekOrder(List<String> order) async {
    state = state.copyWith(weekOrder: order);
    await _saveSettings();
  }
}
