import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromRGBO(255, 204, 0, 1.0),
                const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor:
              Colors.transparent, // Make scaffold background transparent
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Poids total soulevé',
                    value: '750 kg',
                    subtitle: 'Cette semaine',
                    icon: Icons.fitness_center,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    title: 'Nombre de pas',
                    value: '45,000',
                    subtitle: 'Cette semaine',
                    icon: Icons.directions_walk,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    title: 'Nombre d\'entraînements',
                    value: '5 sessions',
                    subtitle: 'Cette semaine',
                    icon: Icons.event_note,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 32),
                  _buildChartSection(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.yellow[700],
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Poids soulevé par jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            // Ajouter ici un widget graphique pour afficher les données
            color: Colors.grey[
                300], // Temporaire pour montrer l'emplacement du graphique
          ),
        ],
      ),
    );
  }
}
