import 'package:flutter/material.dart';
// Assurez-vous d'importer votre page principale
import 'package:yellowmuscu/Screens/main_page.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TutorialStep> tutorialSteps = [
      // Main Page Tutorial
      TutorialStep(
        overviewImage: 'lib/data/tutorial/main_page.png',
        overviewComment:
            'The Main Page serves as the central hub of the application, giving you a quick snapshot of your fitness journey.',
        zoomedFeatures: [
          ZoomedFeature(
            image: 'lib/data/tutorial/streaks.png',
            comment:
                'Track your streaks and see how many consecutive sessions you’ve completed to stay motivated.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/next_session.png',
            comment:
                'View details about your next scheduled session, including the exercises, sets, repetitions, and rest times.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/friend_activity.jpg',
            comment:
                'Stay inspired by keeping up with the fitness activities of your friends.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/your_activity.png',
            comment:
                'View a personal log of your own activities, such as program creation and session updates.',
          ),
        ],
      ),
      // Exercise Page Tutorial
      TutorialStep(
        overviewImage: 'lib/data/tutorial/exercise_page.png',
        overviewComment:
            'Manage and explore exercises from your personal library and programs.',
        zoomedFeatures: [
          ZoomedFeature(
            image: 'lib/data/tutorial/library.png',
            comment:
                'Browse the library of exercises organized by categories like chest, legs, back, etc.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/my_programs.png',
            comment:
                'Access and manage your saved training programs for structured workout routines. Easily create a new program by clicking the "plus" button.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/add_program.png',
            comment:
                'By clicking the "plus" button, you can select the category of the exercise, the day of the session, and the name of the program.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/program_detail.png',
            comment:
                'Click on a program to manage its exercises: change the order, rest times, weights, sets, and repetitions.',
          ),
        ],
      ),
      // Statistics Page Tutorial
      TutorialStep(
        overviewImage: 'lib/data/tutorial/general_stats.png',
        overviewComment:
            'Analyze your performance and track progress over different time periods.You can explore in this first page, your overall fitness work with long-term statistics.',
        zoomedFeatures: [
          ZoomedFeature(
            image: 'lib/data/tutorial/week_stats.png',
            comment:
                'Get a detailed breakdown of your weekly performance, including total sessions, weight lifted, and time spent.',
          ),
        ],
      ),
      // Session Page Tutorial
      TutorialStep(
        overviewImage: 'lib/data/tutorial/session_page.png',
        overviewComment:
            'View and manage your workout sessions, including ongoing and saved sessions.',
        zoomedFeatures: [
          ZoomedFeature(
            image: 'lib/data/tutorial/exercise_screen.png',
            comment:
                'Get detailed information about each exercise, including user-specific metrics like weight, sets, and repetitions.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/rest_screen.png',
            comment:
                'Use a chronometer between sets and exercises, with metrics for the next set and exercise.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/stronger.png',
            comment:
                'A pop-up menu allows you to automatically modify the weights in the exercises done during the session.',
          ),
        ],
      ),
      // Profile Page Tutorial
      TutorialStep(
        overviewImage: 'lib/data/tutorial/profile_page.png',
        overviewComment:
            'Access and view your personal details such as name, email, weight, height, date of birth, and more.',
        zoomedFeatures: [
          ZoomedFeature(
            image: 'lib/data/tutorial/log_out.png',
            comment:
                'Log out or delete your account easily. Update personal details, such as weight, height, or email, to keep your profile accurate.',
          ),
          ZoomedFeature(
            image: 'lib/data/tutorial/search_friends.jpg',
            comment:
                'Find and add friends to connect and stay motivated together.',
          ),
        ],
      ),
      // End of Tutorial
      TutorialStep(
        overviewImage: '',
        overviewComment:
            'You have completed the tutorial! Now you are ready to start exploring YellowMuscu. Press the button below to begin.',
        zoomedFeatures: [],
      ),
    ];

    final List<TutorialContent> tutorialPages = [];
    for (var step in tutorialSteps) {
      // Ajouter la page d'aperçu
      tutorialPages.add(
        TutorialContent(
          image: step.overviewImage,
          comment: step.overviewComment,
          isLast: false,
        ),
      );
      // Ajouter les pages de fonctionnalités zoomées
      for (var feature in step.zoomedFeatures) {
        tutorialPages.add(
          TutorialContent(
            image: feature.image,
            comment: feature.comment,
            isLast: false,
          ),
        );
      }
    }
    // Marquer la dernière page
    tutorialPages.last = TutorialContent(
      image: '', // Pas d'image pour la dernière page
      comment: tutorialSteps.last.overviewComment,
      isLast: true,
    );

    return Scaffold(
      backgroundColor: Colors.yellow, // Fond jaune
      appBar: AppBar(
        title: const Text('Tutorial'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.yellow,
        elevation: 0,
      ),
      body: PageView.builder(
        itemCount: tutorialPages.length,
        itemBuilder: (context, index) {
          return tutorialPages[index];
        },
      ),
    );
  }
}

class TutorialContent extends StatelessWidget {
  final String image;
  final String comment;
  final bool isLast;

  const TutorialContent({
    super.key,
    required this.image,
    required this.comment,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenir la hauteur de l'écran
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      // Permet le scroll si le contenu dépasse l'écran
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Affiche l'image si elle n'est pas vide
            if (image.isNotEmpty)
              Container(
                constraints: BoxConstraints(
                  // Limite la hauteur de l'image à 2/3 de la hauteur de l'écran
                  maxHeight: screenHeight * (2 / 3),
                ),
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            // Petit espace entre l'image et le texte
            if (image.isNotEmpty) const SizedBox(height: 8.0),
            // Texte directement sous l'image
            Text(
              comment,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Affiche le bouton "Begin" seulement sur la dernière page
            if (isLast)
              ElevatedButton(
                onPressed: () {
                  // Navigue vers la mainPage lorsque le bouton est pressé
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Begin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Affiche l'indicateur "Swipe left to continue" si ce n'est pas la dernière page
            if (!isLast) const SizedBox(height: 20),
            if (!isLast)
              const Text(
                'Swipe left to continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TutorialStep {
  final String overviewImage;
  final String overviewComment;
  final List<ZoomedFeature> zoomedFeatures;

  TutorialStep({
    required this.overviewImage,
    required this.overviewComment,
    required this.zoomedFeatures,
  });
}

class ZoomedFeature {
  final String image;
  final String comment;

  ZoomedFeature({
    required this.image,
    required this.comment,
  });
}
