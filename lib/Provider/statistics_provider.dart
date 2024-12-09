// Importation des packages nécessaires
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Gestion de l'état avec Riverpod
import 'package:shared_preferences/shared_preferences.dart'; // Stockage local des préférences utilisateur

// Définition d'une énumération pour choisir entre les menus des statistiques
enum StatisticsMenu {
  general,
  week
} // "general" pour les statistiques globales et "week" pour les statistiques hebdomadaires

// Classe qui représente les réglages des statistiques
class StatisticsSettings {
  final StatisticsMenu
      selectedMenu; // Menu sélectionné par l'utilisateur (general ou week)
  final bool showTotalSessions; // Afficher ou masquer le total des sessions
  final bool showTotalWeight; // Afficher ou masquer le poids total soulevé
  final bool
      showWeeklySessions; // Afficher ou masquer le nombre de sessions hebdomadaires
  final bool
      showWeeklyWeight; // Afficher ou masquer le poids hebdomadaire soulevé
  final bool showWeeklyTime; // Afficher ou masquer le temps hebdomadaire passé
  final bool showWeeklyChart; // Afficher ou masquer le graphique hebdomadaire
  final List<String>
      generalOrder; // Ordre des éléments pour les statistiques globales
  final List<String>
      weekOrder; // Ordre des éléments pour les statistiques hebdomadaires

  // Constructeur de la classe
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

  // Méthode pour copier un objet existant tout en modifiant certains champs
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
      selectedMenu: selectedMenu ??
          this.selectedMenu, // Si non fourni, garder la valeur actuelle
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

// Fournisseur Riverpod pour gérer l'état des réglages des statistiques
final statisticsSettingsProvider =
    StateNotifierProvider<StatisticsSettingsNotifier, StatisticsSettings>(
        (ref) {
  return StatisticsSettingsNotifier(); // Instancie le gestionnaire des réglages
});

// Gestionnaire d'état pour les réglages des statistiques
class StatisticsSettingsNotifier extends StateNotifier<StatisticsSettings> {
  // Constructeur : initialise les valeurs par défaut
  StatisticsSettingsNotifier()
      : super(StatisticsSettings(
          selectedMenu: StatisticsMenu.general, // Menu par défaut : "general"
          showTotalSessions: true, // Afficher les sessions totales
          showTotalWeight: true, // Afficher le poids total soulevé
          showWeeklySessions: true, // Afficher les sessions hebdomadaires
          showWeeklyWeight: true, // Afficher le poids hebdomadaire
          showWeeklyTime: true, // Afficher le temps hebdomadaire
          showWeeklyChart: true, // Afficher le graphique hebdomadaire
          generalOrder: [
            'general_sessions',
            'general_weight'
          ], // Ordre par défaut pour "general"
          weekOrder: [
            'weekly_sessions',
            'weekly_weight',
            'weekly_time',
            'weekly_chart'
          ], // Ordre par défaut pour "week"
        )) {
    _loadSettings(); // Charger les réglages sauvegardés au démarrage
  }

  // Charger les réglages depuis SharedPreferences
  Future<void> _loadSettings() async {
    final prefs =
        await SharedPreferences.getInstance(); // Accès au stockage local
    final selectedMenuStr =
        prefs.getString('selected_menu'); // Récupérer le menu sélectionné
    final selectedMenu = selectedMenuStr == 'week'
        ? StatisticsMenu.week
        : StatisticsMenu.general; // Mapper le menu sélectionné à l'énumération
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

    // Mettre à jour l'état avec les réglages chargés
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
    final prefs =
        await SharedPreferences.getInstance(); // Accès au stockage local
    await prefs.setString(
        'selected_menu',
        state.selectedMenu == StatisticsMenu.general
            ? 'general'
            : 'week'); // Sauvegarder le menu
    await prefs.setBool('show_total_sessions', state.showTotalSessions);
    await prefs.setBool('show_total_weight', state.showTotalWeight);
    await prefs.setBool('show_weekly_sessions', state.showWeeklySessions);
    await prefs.setBool('show_weekly_weight', state.showWeeklyWeight);
    await prefs.setBool('show_weekly_time', state.showWeeklyTime);
    await prefs.setBool('show_weekly_chart', state.showWeeklyChart);
    await prefs.setStringList('general_order', state.generalOrder);
    await prefs.setStringList('week_order', state.weekOrder);
  }

  // Méthode pour changer le menu sélectionné
  Future<void> setSelectedMenu(StatisticsMenu menu) async {
    state = state.copyWith(selectedMenu: menu); // Mettre à jour l'état
    await _saveSettings(); // Sauvegarder les réglages
  }

  // Méthodes pour activer/désactiver les options
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

  // Méthodes pour modifier l'ordre des statistiques
  Future<void> setGeneralOrder(List<String> order) async {
    state = state.copyWith(generalOrder: order); // Mettre à jour l'ordre
    await _saveSettings(); // Sauvegarder les changements
  }

  Future<void> setWeekOrder(List<String> order) async {
    state = state.copyWith(weekOrder: order);
    await _saveSettings();
  }
}
