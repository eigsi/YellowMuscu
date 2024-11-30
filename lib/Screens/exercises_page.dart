// Import necessary libraries
import 'package:flutter/material.dart'; // Material Design widgets and themes
import 'package:yellowmuscu/data/exercises_data.dart'; // Exercise data
import 'package:yellowmuscu/Exercise/exercise_category_list.dart'; // Custom widget for the exercise category list
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Cloud Firestore database
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider for theme (light/dark mode)
import 'package:yellowmuscu/Screens/ProgramDetailPage.dart'; // Program detail page

// Declaration of the main class for the exercises page
class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key}); // Class constructor

  @override
  ExercisesPageState createState() =>
      ExercisesPageState(); // Create the associated state
}

// State class for ExercisesPage
class ExercisesPageState extends ConsumerState<ExercisesPage> {
  // List of exercise categories with their name and icon
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Chest', 'icon': Icons.fitness_center},
    {'name': 'Back', 'icon': Icons.fitness_center},
    {'name': 'Shoulders', 'icon': Icons.fitness_center},
    {'name': 'Biceps', 'icon': Icons.fitness_center},
    {'name': 'Triceps', 'icon': Icons.fitness_center},
    {'name': 'Legs & Glutes', 'icon': Icons.fitness_center},
    {'name': 'Calves', 'icon': Icons.fitness_center},
    {'name': 'Abs', 'icon': Icons.fitness_center},
    {'name': 'Stretching', 'icon': Icons.fitness_center},
  ];

  // List of user's programs
  List<Map<String, dynamic>> _programs = [];

  // Instance of FirebaseAuth for authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Currently logged-in user

  @override
  void initState() {
    super.initState(); // Call the parent class's initState method
    _user = _auth.currentUser; // Retrieve the logged-in user
    if (_user != null) {
      _fetchPrograms(); // If a user is logged in, fetch their programs
    }
  }

  // Method to fetch the user's programs from Firestore
  Future<void> _fetchPrograms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users') // Access the 'users' collection
          .doc(_user!.uid) // Document corresponding to the logged-in user
          .collection('programs') // User's 'programs' subcollection
          .get(); // Retrieve the documents

      if (!mounted) return;
      setState(() {
        _programs = snapshot.docs.map((doc) {
          Map<String, dynamic>? data = doc.data(); // Document data

          // Retrieve the exercises of the program
          List<dynamic> exercisesData = data['exercises'] ?? [];

          // Transform exercises into a list of Map<String, dynamic>
          List<Map<String, dynamic>> exercises = exercisesData
              .map((exercise) {
                if (exercise is String) {
                  // If the exercise is a string, create a default Map
                  return {
                    'name': exercise,
                    'image': '',
                    'sets': 3,
                    'reps': 10,
                    'restTime': 60,
                    'restBetweenExercises': 60,
                    'weight': 0,
                    'description': '',
                    'goals': '',
                  };
                } else if (exercise is Map<String, dynamic>) {
                  // If it's already a Map, convert it
                  return Map<String, dynamic>.from(exercise);
                } else {
                  return null; // Otherwise, ignore
                }
              })
              .whereType<Map<String, dynamic>>() // Filter out nulls
              .toList();

          // Return a Map representing the program
          return {
            'id': doc.id, // Document identifier
            'name': data['name'] ?? 'Unnamed Program', // Program name
            'icon':
                data['icon'] ?? 'lib/data/icon_images/chest_part.png', // Icon
            'iconName': data['iconName'] ?? 'Chest part', // Icon name
            'day': data['day'] ?? '', // Day associated with the program
            'isFavorite': data['isFavorite'] ?? false, // Favorite status
            'exercises': exercises, // List of exercises
          };
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      // In case of error, display a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching programs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to display exercises of a selected category
  void _showExercises(String category) {
    List<Map<String, String>> exercises; // List of exercises to display

    // Select exercises based on the category
    if (category == 'Biceps') {
      exercises = ExercisesData.bicepsExercises;
    } else if (category == 'Abs') {
      exercises = ExercisesData.abExercises;
    } else if (category == 'Triceps') {
      exercises = ExercisesData.tricepsExercises;
    } else if (category == 'Legs & Glutes') {
      exercises = ExercisesData.legExercises;
    } else if (category == 'Chest') {
      exercises = ExercisesData.chestExercises;
    } else if (category == 'Back') {
      exercises = ExercisesData.backExercises;
    } else if (category == 'Shoulders') {
      exercises = ExercisesData.shoulderExercises;
    } else if (category == 'Calves') {
      exercises = ExercisesData.calfExercises;
    } else if (category == 'Stretching') {
      exercises = ExercisesData.stretchingExercises;
    } else {
      exercises = []; // If the category is not recognized, empty list
    }

    final isDarkMode = ref.watch(themeProvider); // Check the theme

    // Add a controller for the search
    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredExercises = List.from(exercises);

    // Display a modal bottom sheet with the list of exercises
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDarkMode ? Colors.black : Colors.white, // Background color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.0)), // Rounded corners
      ),
      isScrollControlled: true, // Allows scrolling if content exceeds height
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: const EdgeInsets.all(16.0), // Padding
              height: MediaQuery.of(context).size.height *
                  0.8, // 80% of screen height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left alignment
                children: [
                  // Category title
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16), // Vertical spacing
                  // Search bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search an exercise',
                      hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : Colors.grey[600]), // Placeholder color
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.white : Colors.grey[600],
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isDarkMode ? Colors.white70 : Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isDarkMode ? Colors.white : Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                    onChanged: (value) {
                      setStateModal(() {
                        filteredExercises = exercises
                            .where((exercise) => exercise['name']!
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16), // Vertical spacing
                  // List of exercises
                  Expanded(
                    child: filteredExercises.isEmpty
                        ? Center(
                            child: Text(
                              'No exercises found.',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const BouncingScrollPhysics(), // Bounce effect
                            itemCount:
                                filteredExercises.length, // Number of items
                            itemBuilder: (context, index) {
                              final exercise =
                                  filteredExercises[index]; // Current exercise
                              return ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Image.asset(
                                        exercise['image']!, // Exercise image
                                        width: 40,
                                        height: 40,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                              Icons.image_not_supported);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  exercise['name']!, // Exercise name
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min, // Adjust size
                                  children: [
                                    // Button to display exercise details
                                    IconButton(
                                      icon: Icon(Icons.info_outline,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        _showExerciseInfo(
                                            exercise); // Show info
                                      },
                                    ),
                                    // Button to add exercise to a program
                                    IconButton(
                                      icon: Icon(Icons.add,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        _showProgramSelection(
                                            exercise); // Select program
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Method to display detailed information of an exercise
  void _showExerciseInfo(Map<String, String> exercise) {
    final isDarkMode = ref.watch(themeProvider); // Check the theme

    // Display a dialog with exercise details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? Colors.black : Colors.white, // Background color
          contentPadding: const EdgeInsets.all(16.0), // Padding
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust size
              crossAxisAlignment: CrossAxisAlignment.start, // Left alignment
              children: [
                // Display the exercise image
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.asset(
                    exercise['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 100);
                    },
                  ),
                ),
                const SizedBox(height: 16), // Vertical spacing
                // Title "Description"
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8), // Vertical spacing
                // Description text
                Text(
                  exercise['description'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16), // Vertical spacing
                // Title "Goals"
                Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8), // Vertical spacing
                // Goals text
                Text(
                  exercise['goals'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            // Button to close the dialog
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to select a program to which to add the exercise
  void _showProgramSelection(Map<String, String> exercise) {
    final isDarkMode = ref.watch(themeProvider); // Check the theme

    // Sort programs alphabetically
    List<Map<String, dynamic>> sortedPrograms = List.from(_programs);
    sortedPrograms.sort((a, b) => a['name'].compareTo(b['name']));

    // Display a bottom sheet with the list of programs
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDarkMode ? Colors.black : Colors.white, // Background color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.0)), // Rounded corners
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0), // Padding
          child: _user == null
              ? Center(
                  // Message if the user is not logged in
                  child: Text(
                    'Please log in to add exercises to programs.',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Left alignment
                  mainAxisSize: MainAxisSize.min, // Adjust size
                  children: [
                    // Title
                    Text(
                      'Select a program',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16), // Vertical spacing
                    sortedPrograms.isEmpty
                        ? Text(
                            // Message if no programs are available
                            'No programs available. Add a new one.',
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          )
                        : Expanded(
                            // List of available programs
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: sortedPrograms.length,
                              itemBuilder: (context, index) {
                                final program =
                                    sortedPrograms[index]; // Current program
                                return ListTile(
                                  title: Text(
                                    program['name'], // Program name
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  onTap: () {
                                    Navigator.of(context)
                                        .pop(); // Close the bottom sheet
                                    _showRestTimePopup(
                                        exercise,
                                        _programs.indexWhere((p) =>
                                            p['id'] ==
                                            program[
                                                'id'])); // Ask for rest time
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                ),
        );
      },
    );
  }

  // Method to ask for rest time between exercises
  void _showRestTimePopup(Map<String, String> exercise, int programIndex) {
    int restBetweenExercises = 60; // Default rest time
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = ref.watch(themeProvider); // Check the theme
        return AlertDialog(
          backgroundColor:
              isDarkMode ? darkWidget : Colors.white, // Background color
          title: const Text(
            'Rest time',
            style: TextStyle(color: Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centered horizontally
                children: [
                  // Button to decrease rest time
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.black),
                    onPressed: () {
                      if (restBetweenExercises > 10) {
                        setStateDialog(() {
                          restBetweenExercises -= 10; // Decrease by 10 seconds
                        });
                      }
                    },
                  ),
                  // Display current rest time
                  Text(
                    '$restBetweenExercises s',
                    style: const TextStyle(color: Colors.black),
                  ),
                  // Button to increase rest time
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        restBetweenExercises += 10; // Increase by 10 seconds
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            // Button to add the exercise to the program
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Couleur du texte
              ),
              child: const Text('Add'),
              onPressed: () async {
                final messenger =
                    ScaffoldMessenger.of(context); // To display messages
                try {
                  await _addExerciseToProgram(
                      programIndex, exercise, restBetweenExercises); // Add
                  if (!mounted) {
                    return; // Check if the widget is still mounted
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error adding exercise: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Method to add the exercise to the selected program
  Future<void> _addExerciseToProgram(int programIndex,
      Map<String, String> exercise, int restBetweenExercises) async {
    if (_user != null) {
      final program = _programs[programIndex]; // Selected program
      // Add the exercise to the program's exercise list
      program['exercises'].add({
        'name': exercise['name'],
        'image': exercise['image'],
        'sets': 3,
        'reps': 10,
        'restTime': 60,
        'restBetweenExercises': restBetweenExercises,
        'weight': 0,
        'description': exercise['description'] ?? '',
        'goals': exercise['goals'] ?? '',
      });

      try {
        // Update the program in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'exercises': program['exercises'],
        });
      } catch (e) {
        rethrow; // Rethrow the exception to be handled elsewhere
      }

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _programs[programIndex] = program; // Update local state
      });
    }
  }

  // Method to delete a program
  void _deleteProgram(int index) async {
    if (_user != null) {
      final program = _programs[index]; // Selected program
      final programId = program['id']; // Program identifier
      try {
        // Delete the program in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(programId)
            .delete();
      } catch (e) {
        if (!mounted) return;
        // In case of error, display a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting program: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _programs.removeAt(index); // Remove the program from the local list
      });

      // Display a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Program "${program['name']}" has been deleted'),
        ),
      );
    }
  }

  // Method to add a new program
  void _addNewProgram(BuildContext context) {
    final TextEditingController programController =
        TextEditingController(); // Controller for the text field
    String? selectedDay; // Selected day
    String? selectedImage; // Selected image
    String? selectedLabel; // Name of the selected image

    // List of available image options
    final List<Map<String, dynamic>> imageOptions = [
      {'name': 'Chest part', 'image': 'lib/data/icon_images/chest_part.png'},
      {'name': 'Back part', 'image': 'lib/data/icon_images/back_part.png'},
      {'name': 'Leg part', 'image': 'lib/data/icon_images/leg_part.png'},
    ];

    // List of days of the week
    final List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final isDarkMode = ref.watch(themeProvider); // Check the theme

    // Display a dialog to add a program
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? Colors.black : Colors.white, // Background color
          title: Text(
            'Add a new program',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Adjust size
                  children: [
                    // Text field for the program name
                    TextField(
                      controller: programController,
                      decoration: InputDecoration(
                        labelText: 'Program name',
                        labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isDarkMode ? Colors.white70 : Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isDarkMode ? Colors.white : Colors.blue),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 16), // Vertical spacing
                    // Title "Select a category"
                    Text(
                      'Select a category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8), // Vertical spacing
                    // Image options
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: imageOptions.map((option) {
                        final isSelected = selectedImage ==
                            option['image']; // Check if the image is selected
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedImage =
                                  option['image']; // Update selected image
                              selectedLabel =
                                  option['name']; // Update image name
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Adjust size
                            children: [
                              // Category image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.black,
                                          width: 3) // Border if selected
                                      : null,
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    option['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4), // Vertical spacing
                              // Category name
                              Text(
                                option['name'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.black.withOpacity(
                                          0.3), // Reduced opacity if not selected
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16), // Vertical spacing
                    // Dropdown menu to select the day
                    DropdownButtonFormField<String>(
                      value: selectedDay, // Currently selected day
                      decoration: InputDecoration(
                        labelText: selectedDay == null
                            ? 'Select a day'
                            : 'Selected day',
                        labelStyle: TextStyle(
                          color: selectedDay == null
                              ? Colors.red
                              : isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: selectedDay == null
                                ? Colors.red
                                : isDarkMode
                                    ? Colors.white
                                    : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                selectedDay == null ? Colors.red : Colors.blue,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      hint: Text(
                        'Select a day',
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      dropdownColor: isDarkMode
                          ? Colors.black
                          : Colors.white, // Dropdown menu color
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedDay = newValue; // Update selected day
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a day'; // Error message if no day selected
                        }
                        return null;
                      },
                      items: daysOfWeek
                          .map<DropdownMenuItem<String>>((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(
                            day,
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            // "Cancel" button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            // "Add" button
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                final messenger =
                    ScaffoldMessenger.of(context); // To display messages
                // Check that all fields are filled
                if (programController.text.isEmpty ||
                    selectedImage == null ||
                    selectedDay == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields.'),
                    ),
                  );
                  return;
                }

                if (_user != null) {
                  final newProgram = {
                    'name': programController.text, // Program name
                    'icon': selectedImage, // Selected image
                    'iconName': selectedLabel, // Image name
                    'day': selectedDay, // Selected day
                    'isFavorite': false, // Default to not favorite
                    'exercises': [], // Empty list of exercises
                  };

                  try {
                    // Add the new program to Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('programs')
                        .add(newProgram);
                    if (!mounted) {
                      return; // Check if the widget is still mounted
                    }
                    _fetchPrograms(); // Refresh the list of programs
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop(); // Close the dialog
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            "Program '${programController.text}' added successfully."),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error adding program: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Method to build the visual element of a program in the list
  Widget _buildProgramItem(String programName, String iconPath, String day,
      bool isFavorite, VoidCallback onFavoriteToggle) {
    final isDarkMode = ref.watch(themeProvider); // Check the theme

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0), // External margins
      padding: const EdgeInsets.all(12.0), // Padding
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white, // Background color
        borderRadius: BorderRadius.circular(16.0), // Rounded corners
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Horizontal distribution
        children: [
          Row(
            children: [
              // Program image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  image: DecorationImage(
                    image: AssetImage(iconPath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16), // Horizontal spacing
              // Program name and day
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left alignment
                children: [
                  Text(
                    programName, // Program name
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    day, // Program day
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Button to mark the program as favorite
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.star
                  : Icons.star_border, // Icon based on status
              color: isFavorite
                  ? Colors.yellow[700]
                  : isDarkMode
                      ? Colors.white
                      : Colors.black,
            ),
            onPressed: onFavoriteToggle, // Action when pressed
          ),
        ],
      ),
    );
  }

  // Method to toggle the favorite status of a program
  Future<void> _toggleFavorite(int index) async {
    if (_user != null) {
      final program = _programs[index]; // Selected program
      program['isFavorite'] = !program['isFavorite']; // Invert status

      try {
        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'isFavorite': program['isFavorite'],
        });
      } catch (e) {
        // Error handling (display a message)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        // Sort programs so that favorites appear first
        _programs.sort((a, b) {
          if (a['isFavorite'] && !b['isFavorite']) {
            return -1;
          } else if (!a['isFavorite'] && b['isFavorite']) {
            return 1;
          } else {
            return 0;
          }
        });
      });
    }
  }

  // Method to display program details
  Future<void> _showProgramDetail(Map<String, dynamic> program) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailPage(
          program: program, // Program to display
          userId: _user!.uid, // User ID
          onUpdate: () {
            if (mounted) {
              _fetchPrograms(); // Refresh programs if changes have been made
            }
          }, // Callback when updated
        ),
      ),
    );
    if (result == true && mounted) {
      _fetchPrograms(); // Refresh programs if changes have been made
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [darkTop, darkBottom]
                  : [
                      lightTop,
                      lightBottom,
                    ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent, // Transparent background
          body: Padding(
            padding: const EdgeInsets.all(16.0), // Padding
            child: _user == null
                ? Center(
                    // If the user is not logged in, display a sign-in button
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, '/signIn'); // Navigate to the sign-in page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700], // Button color
                      ),
                      child: const Text('Sign in'),
                    ),
                  )
                : Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Left alignment
                    children: [
                      // Title "Library"
                      Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16), // Vertical spacing
                      // List of exercise categories
                      Expanded(
                        flex: 1, // Take available space
                        child: Card(
                          color: isDarkMode
                              ? Colors.black
                              : Colors.white, // Background color
                          elevation: 4.0, // Elevation for shadow
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16.0), // Rounded corners
                          ),
                          child: ExerciseCategoryList(
                            categories: _categories, // List of categories
                            onCategoryTap:
                                _showExercises, // Action when a category is selected
                            isDarkMode: isDarkMode, // Theme
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Vertical spacing
                      // Title "My Programs" with add button
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Horizontal distribution
                        children: [
                          Text(
                            'My Programs',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          // Button to add a new program
                          IconButton(
                            icon: Icon(Icons.add,
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                            onPressed: () {
                              _addNewProgram(context); // Call the add method
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Vertical spacing
                      // List of programs
                      Expanded(
                        flex: 1, // Take available space
                        child: _programs.isEmpty
                            ? Center(
                                // Message if no programs are available
                                child: Text(
                                  'No programs available. Add a new one.',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    _programs.length, // Number of programs
                                itemBuilder: (context, index) {
                                  final program =
                                      _programs[index]; // Current program
                                  return Dismissible(
                                    key: UniqueKey(), // Unique key for the item
                                    direction: DismissDirection
                                        .startToEnd, // Swipe direction
                                    onDismissed: (direction) {
                                      _deleteProgram(
                                          index); // Delete the program
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${program['name']} has been deleted'),
                                        ),
                                      );
                                    },
                                    background: Container(
                                      padding: const EdgeInsets.only(left: 16),
                                      alignment: Alignment.centerLeft,
                                      color: Colors
                                          .red, // Background color when swiped
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _showProgramDetail(
                                          program), // Display program details
                                      child: _buildProgramItem(
                                        program['name'],
                                        program['icon'],
                                        program['day'] ?? '',
                                        program['isFavorite'],
                                        () => _toggleFavorite(
                                            index), // Toggle favorite status
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
