// Import necessary packages
//full english
import 'package:flutter/material.dart'; // Flutter material widgets library
import 'package:cloud_firestore/cloud_firestore.dart'; // To interact with Firebase Firestore database
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For state management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider to manage theme (light/dark)
import 'package:flutter/cupertino.dart'; // Cupertino widgets for iOS style
import 'package:yellowmuscu/Exercise/exercise_category_list.dart'; // Widget for the category list
import 'package:yellowmuscu/data/exercises_data.dart'; // Exercise data

// Definition of the ProgramDetailPage class, a ConsumerStatefulWidget to integrate Riverpod
class ProgramDetailPage extends ConsumerStatefulWidget {
  // Final variables to store the program, user ID, and an update callback function
  final Map<String, dynamic> program; // The exercise program
  final String userId; // The current user's ID
  final VoidCallback onUpdate; // Callback function to notify updates

  // Constructor of the class with required parameters
  const ProgramDetailPage({
    super.key,
    required this.program,
    required this.userId,
    required this.onUpdate,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProgramDetailPageState createState() => _ProgramDetailPageState();
}

// State associated with the ProgramDetailPage class
class _ProgramDetailPageState extends ConsumerState<ProgramDetailPage> {
  late List<Map<String, dynamic>> exercises; // List of exercises in the program
  bool _isEditingOrder =
      false; // Indicates if the user is in exercise order editing mode
  bool _hasChanges = false; // Indicates if any modifications have been made

  @override
  void initState() {
    super.initState();
    // Initialize the exercises list by copying from the provided program
    // If 'exercises' is absent or null, initialize as an empty list
    exercises = widget.program['exercises'] != null
        ? List<Map<String, dynamic>>.from(widget.program['exercises'])
        : [];

    // Iterate through each exercise to ensure certain keys exist
    for (var exercise in exercises) {
      exercise['restBetweenExercises'] =
          exercise['restBetweenExercises'] ?? 60; // Default 60 seconds
      exercise['restTime'] = exercise['restTime'] ?? 60; // Default 60 seconds
      exercise['sets'] = exercise['sets'] ?? 3; // Default 3 sets
      exercise['reps'] = exercise['reps'] ?? 10; // Default 10 reps
      exercise['weight'] =
          exercise['weight']?.toDouble() ?? 0.0; // Default 0.0 kg
      exercise['image'] = exercise['image'] ??
          'assets/images/default_exercise.png'; // Default image
      exercise['name'] = exercise['name'] ?? 'Exercise'; // Default name
      exercise['id'] = exercise['id'] ??
          UniqueKey().toString(); // Generate unique ID if absent
      exercise['multipleWeights'] =
          exercise['multipleWeights'] ?? false; // Default to false
      if (exercise['multipleWeights']) {
        // If multipleWeights is enabled, initialize weightsPerSet
        exercise['weightsPerSet'] = exercise['weightsPerSet'] != null
            ? List<double>.from(
                exercise['weightsPerSet'].map((w) => w.toDouble()))
            : List<double>.filled(
                exercise['sets'], exercise['weight'].toDouble());
      }
    }
  }

  // Asynchronous method to save modified exercises to Firestore
  Future<void> _saveExercises() async {
    try {
      // Check if the program has a unique ID
      String programId = widget.program['id'];
      if (programId.isEmpty) {
        // If 'id' is absent, generate a new ID and create the document
        DocumentReference newProgramRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('programs')
            .doc(); // Generates a new ID
        programId = newProgramRef.id;
        await newProgramRef.set({
          'id': programId,
          'name': widget.program['name'] ?? 'New Program',
          'exercises': exercises,
        });
      } else {
        // If 'id' exists, update the existing document with 'set' and 'merge: true'
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('programs')
            .doc(programId)
            .set({'exercises': exercises}, SetOptions(merge: true));
      }

      widget.onUpdate(); // Calls the update callback to notify changes

      // Displays a visual confirmation that the exercises have been saved
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercises saved'),
        ),
      );
    } catch (e) {
      // Handles Firestore errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Asynchronous method to display a rest time picker (iOS style)
  void _showRestTimePicker(BuildContext context, int currentRestTime,
      ValueChanged<int> onRestTimeChanged) {
    int currentMinutes = currentRestTime ~/ 60; // Calculate initial minutes
    int currentSeconds = currentRestTime % 60; // Calculate initial seconds

    final isDarkMode = ref.watch(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Modal height
          color: isDarkMode ? Colors.black : Colors.white, // Background color
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes picker
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Height of each item
                  scrollController: FixedExtentScrollController(
                    initialItem: currentMinutes, // Initial minutes value
                  ),
                  onSelectedItemChanged: (int value) {
                    currentMinutes = value; // Update selected minutes
                  },
                  children: List<Widget>.generate(
                    61, // Generates minutes from 0 to 60
                    (int index) {
                      return Text('$index min'); // Displays minutes text
                    },
                  ),
                ),
              ),
              // Seconds picker
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Height of each item
                  scrollController: FixedExtentScrollController(
                    initialItem: (currentSeconds / 10)
                        .floor(), // Initial seconds value (in 10s)
                  ),
                  onSelectedItemChanged: (int value) {
                    currentSeconds = value * 10; // Update selected seconds
                  },
                  children: List<Widget>.generate(
                    6, // Generates seconds from 0 to 50 (in 10s)
                    (int index) {
                      return Text('${index * 10} sec'); // Displays seconds text
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // When the picker is closed, calculate the total time in seconds
      int totalTimeInSeconds = (currentMinutes * 60) + currentSeconds;
      onRestTimeChanged(
          totalTimeInSeconds); // Calls the callback function with the new value
    });
  }

  // Method to display a generic numeric picker
  void _showInputPicker(BuildContext context, String title, int initialValue,
      int minValue, int maxValue, int step, ValueChanged<int> onValueChanged) {
    int currentValue = initialValue; // Initialize current value

    final isDarkMode = ref.watch(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Modal height
          color: isDarkMode ? Colors.black : Colors.white, // Background color
          child: Column(
            children: [
              // Picker title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Height of each item
                  scrollController: FixedExtentScrollController(
                    initialItem: ((currentValue - minValue) ~/ step)
                        .clamp(0, ((maxValue - minValue) ~/ step)),
                  ),
                  onSelectedItemChanged: (int value) {
                    currentValue =
                        minValue + value * step; // Update the selected value
                  },
                  children: List<Widget>.generate(
                    ((maxValue - minValue) ~/ step) +
                        1, // Number of items to generate
                    (int index) {
                      return Text(
                          '${minValue + index * step}'); // Displays each value
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // When the picker is closed, call the callback function with the new value
      onValueChanged(currentValue);
    });
  }

  // Method to display a numeric picker with decimal steps (e.g., 0.5 kg)
  void _showDecimalInputPicker(
      BuildContext context,
      String title,
      double initialValue,
      double minValue,
      double maxValue,
      double step,
      ValueChanged<double> onValueChanged) {
    double currentValue = initialValue; // Initialize current value

    final isDarkMode = ref.watch(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Modal height
          color: isDarkMode ? Colors.black : Colors.white,
          child: Column(
            children: [
              // Picker title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Height of each item
                  scrollController: FixedExtentScrollController(
                    initialItem: ((currentValue - minValue) / step)
                        .round()
                        .clamp(0, ((maxValue - minValue) / step).round()),
                  ),
                  onSelectedItemChanged: (int value) {
                    currentValue =
                        minValue + value * step; // Update the selected value
                  },
                  children: List<Widget>.generate(
                    ((maxValue - minValue) / step).round() +
                        1, // Number of items to generate
                    (int index) {
                      double value = minValue + index * step;
                      return Text(
                          '${value.toStringAsFixed(1)} kg'); // Displays each value with one decimal
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // When the picker is closed, call the callback function with the new value
      onValueChanged(currentValue);
    });
  }

  // Method to edit a specific exercise
  void _editExercise(int index) {
    final exercise =
        exercises[index]; // Retrieve the exercise at the given index
    int sets = exercise['sets']; // Number of sets
    int reps = exercise['reps']; // Number of reps
    double weight =
        exercise['weight']?.toDouble() ?? 0.0; // Weight, default 0.0
    int restTime = exercise['restTime']?.toInt() ??
        60; // Rest time between sets, default 60 seconds
    bool multipleWeights =
        exercise['multipleWeights'] ?? false; // Multiple weights
    List<double> weightsPerSet = multipleWeights
        ? List<double>.from(
            exercise['weightsPerSet']?.map((w) => w.toDouble()) ??
                List<double>.filled(sets, weight))
        : [weight.toDouble()]; // Weights per set

    final isDarkMode =
        ref.watch(themeModeProvider); // Check if dark mode is enabled

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // Use a StatefulBuilder to manage local state within the dialog
          return AlertDialog(
            backgroundColor: isDarkMode
                ? Colors.black
                : Colors.white, // Background color based on theme
            title: Text(
              'Edit ${exercise['name']}', // Dialog title
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Editing the number of sets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sets:'), // Label
                      GestureDetector(
                        onTap: () {
                          _showInputPicker(
                            context,
                            'Sets', // Picker title
                            sets, // Initial value
                            1, // Minimum value
                            99, // Maximum value
                            1, // Step
                            (newSets) {
                              setStateDialog(() {
                                sets = newSets; // Update the number of sets
                                if (multipleWeights) {
                                  // Adjust the weightsPerSet list
                                  if (newSets > weightsPerSet.length) {
                                    weightsPerSet.addAll(List<double>.filled(
                                        newSets - weightsPerSet.length,
                                        weight));
                                  } else if (newSets < weightsPerSet.length) {
                                    weightsPerSet =
                                        weightsPerSet.sublist(0, newSets);
                                  }
                                }
                              });
                            },
                          );
                        },
                        child: Text('$sets sets'), // Displays the current value
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Space between fields
                  // Editing the number of reps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Repetitions:'),
                      GestureDetector(
                        onTap: () {
                          _showInputPicker(
                            context,
                            'Repetitions',
                            reps,
                            1,
                            99,
                            1,
                            (newReps) {
                              setStateDialog(() {
                                reps =
                                    newReps; // Update the number of repetitions
                              });
                            },
                          );
                        },
                        child: Text('$reps repetitions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Editing the weight
                  if (!multipleWeights)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Weight (kg):'),
                        GestureDetector(
                          onTap: () {
                            _showDecimalInputPicker(
                              context,
                              'Weight (kg)',
                              weight,
                              0.0,
                              500.0,
                              0.5,
                              (newWeight) {
                                setStateDialog(() {
                                  weight = newWeight; // Update the weight
                                });
                              },
                            );
                          },
                          child: Text(
                              '${weight.toStringAsFixed(1)} kg'), // Displays the current value with one decimal
                        ),
                      ],
                    ),
                  if (multipleWeights)
                    Column(
                      children: List.generate(sets, (s) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Weight set ${s + 1}:'),
                            GestureDetector(
                              onTap: () {
                                _showDecimalInputPicker(
                                  context,
                                  'Weight set ${s + 1}',
                                  weightsPerSet[s],
                                  0.0,
                                  500.0,
                                  0.5,
                                  (newWeight) {
                                    setStateDialog(() {
                                      weightsPerSet[s] =
                                          newWeight; // Update the set's weight
                                    });
                                  },
                                );
                              },
                              child: Text(
                                  '${weightsPerSet[s].toStringAsFixed(1)} kg'), // Displays the set's weight
                            ),
                          ],
                        );
                      }),
                    ),
                  const SizedBox(height: 16),
                  // Editing the rest time between sets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rest between sets:'),
                      GestureDetector(
                        onTap: () {
                          _showRestTimePicker(context, restTime, (newRestTime) {
                            setStateDialog(() {
                              restTime = newRestTime; // Update the rest time
                            });
                          });
                        },
                        child: Text(_formatDuration(
                            restTime)), // Displays the formatted rest time
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Button to toggle multiple weights
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Multiple Weights:'),
                      CupertinoSwitch(
                        value: multipleWeights,
                        onChanged: (bool value) {
                          setStateDialog(() {
                            multipleWeights = value;
                            if (value) {
                              // Initialize weightsPerSet if enabled
                              weightsPerSet = List<double>.filled(sets, weight);
                            } else {
                              // Reset weight if disabled
                              weight = weightsPerSet.isNotEmpty
                                  ? weightsPerSet[0]
                                  : 0.0;
                              weightsPerSet = [];
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              // Button to cancel modifications
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                ),
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              // Button to save modifications
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                ),
                child: const Text('Save'),
                onPressed: () async {
                  setState(() {
                    // Update the exercise values in the list
                    exercises[index]['sets'] = sets;
                    exercises[index]['reps'] = reps;
                    exercises[index]['restTime'] = restTime;
                    exercises[index]['multipleWeights'] = multipleWeights;
                    if (multipleWeights) {
                      exercises[index]['weightsPerSet'] = weightsPerSet;
                      exercises[index]['weight'] =
                          weightsPerSet.isNotEmpty ? weightsPerSet[0] : 0.0;
                    } else {
                      exercises[index]['weight'] = weight;
                      exercises[index].remove('weightsPerSet');
                    }
                  });

                  // Save the modifications to Firestore
                  await _saveExercises();

                  setState(() {
                    _hasChanges =
                        true; // Indicates that modifications have been made
                  });

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Closes the dialog
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to modify the rest time between exercises
  void _changeRestBetweenExercises(int index, int change) {
    setState(() {
      int newRest = (exercises[index]['restBetweenExercises'] + change)
          .clamp(0, 3600); // Limits between 0 and 3600 seconds
      exercises[index]['restBetweenExercises'] =
          newRest; // Updates the rest time
      _hasChanges = true; // Indicates that modifications have been made
    });
    _saveExercises(); // Saves the modifications
  }

  // Method to reorder exercises in the list
  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1; // Adjusts the index if necessary
      final item = exercises
          .removeAt(oldIndex); // Removes the exercise from its current position
      exercises.insert(
          newIndex, item); // Inserts the exercise at the new position
      _hasChanges = true; // Indicates that modifications have been made
    });
    _saveExercises(); // Saves the modifications
  }

  // Method to toggle the exercise order editing mode
  void _toggleEditingOrder() {
    setState(() {
      _isEditingOrder = !_isEditingOrder; // Toggles the boolean value
      if (!_isEditingOrder) {
        _saveExercises(); // Saves the modifications if exiting edit mode
      }
    });
  }

  // Method to format the duration into minutes and seconds
  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds sec'; // If less than a minute, display seconds
    } else {
      int minutes = totalSeconds ~/ 60; // Calculates minutes
      int seconds = totalSeconds % 60; // Calculates remaining seconds
      String minutesPart =
          '$minutes min${minutes > 1 ? 's' : ''}'; // Handles plural
      String secondsPart =
          seconds > 0 ? ' $seconds sec' : ''; // Displays seconds if > 0
      return secondsPart.isNotEmpty
          ? '$minutesPart $secondsPart'
          : minutesPart; // Combines both
    }
  }

  // Method to display the exercise categories menu
  void _addNewExercises() {
    final isDarkMode = ref.watch(themeModeProvider);
    final List<Map<String, dynamic>> categories = [
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

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled: true, // Modals take up the entire height of the page
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            children: [
              // Small close icon at the top left
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Closes the modal
                  },
                ),
              ),
              Expanded(
                child: ExerciseCategoryList(
                  categories: categories,
                  onCategoryTap: (category) {
                    Navigator.of(context).pop(); // Closes the category modal
                    _showExercises(category);
                  },
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to display the list of exercises for a category
  void _showExercises(String category) {
    List<Map<String, String>> exercisesList;

    // Selects exercises based on the category
    if (category == 'Biceps') {
      exercisesList = ExercisesData.bicepsExercises;
    } else if (category == 'Abs') {
      exercisesList = ExercisesData.abExercises;
    } else if (category == 'Triceps') {
      exercisesList = ExercisesData.tricepsExercises;
    } else if (category == 'Legs & Glutes') {
      exercisesList = ExercisesData.legExercises;
    } else if (category == 'Chest') {
      exercisesList = ExercisesData.chestExercises;
    } else if (category == 'Back') {
      exercisesList = ExercisesData.backExercises;
    } else if (category == 'Shoulders') {
      exercisesList = ExercisesData.shoulderExercises;
    } else if (category == 'Calves') {
      exercisesList = ExercisesData.calfExercises;
    } else if (category == 'Stretching') {
      exercisesList = ExercisesData.stretchingExercises;
    } else {
      exercisesList = [];
    }

    final isDarkMode = ref.watch(themeModeProvider);

    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredExercises = List.from(exercisesList);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled: true, // Modals take up the entire height of the page
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  // Small close icon at the top left
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop(); // Closes the modal
                      },
                    ),
                  ),
                  // Category title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for an exercise',
                        hintStyle: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600]),
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
                          filteredExercises = exercisesList
                              .where((exercise) => exercise['name']!
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];
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
                                        exercise['image']!,
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
                                  exercise['name']!,
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.info_outline,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        _showExerciseInfo(exercise);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Closes the exercises modal
                                        _showRestTimePopup(exercise);
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

  // Method to display exercise details
  void _showExerciseInfo(Map<String, String> exercise) {
    final isDarkMode = ref.watch(themeModeProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
          contentPadding: const EdgeInsets.all(16.0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise['description'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise['goals'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to display the rest time popup between exercises
  void _showRestTimePopup(Map<String, String> exercise) {
    int restBetweenExercises = 60;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = ref.watch(themeModeProvider);
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
          title: Text(
            'Rest time',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (restBetweenExercises > 10) {
                        setStateDialog(() {
                          restBetweenExercises -= 10;
                        });
                      }
                    },
                  ),
                  Text(
                    '$restBetweenExercises s',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setStateDialog(() {
                        restBetweenExercises += 10;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                Navigator.of(context).pop(); // Closes the dialog
                _addExerciseToProgramWithRest(exercise, restBetweenExercises);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to add an exercise to the program with rest time
  void _addExerciseToProgramWithRest(
      Map<String, String> exercise, int restBetweenExercises) async {
    // Add default values to the exercise
    Map<String, dynamic> newExercise = {
      'name': exercise['name'],
      'image': exercise['image'],
      'sets': 3,
      'reps': 10,
      'restTime': 60,
      'restBetweenExercises': restBetweenExercises,
      'weight': 0.0,
      'description': exercise['description'] ?? '',
      'goals': exercise['goals'] ?? '',
      'id': UniqueKey().toString(),
      'multipleWeights': false,
    };

    setState(() {
      exercises.add(newExercise);
      _hasChanges = true;
    });

    await _saveExercises();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeModeProvider); // Checks if dark mode is enabled

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Handles back button behavior
        Navigator.of(context).pop(
            _hasChanges); // Returns to the previous page with the changes indicator
        return false; // Prevents automatic closure
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Colors.black54
              : null, // Background color based on theme
          title: Text(widget.program['name'] ??
              'Program'), // Displays the program name in the app bar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Back icon
            onPressed: () {
              Navigator.of(context).pop(
                  _hasChanges); // Returns to the previous page with the changes indicator
            },
            tooltip: 'Back',
          ),
          actions: [
            // Button to toggle exercise order editing mode
            IconButton(
              icon: Icon(_isEditingOrder
                  ? Icons.check
                  : Icons.reorder), // Changing icon
              onPressed: _toggleEditingOrder, // Calls the method to toggle mode
              tooltip: _isEditingOrder ? 'Finish Editing' : 'Reorder Exercises',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: exercises.isEmpty
                  ? Center(
                      // If the exercises list is empty, display a message
                      child: Text(
                        'No exercises added to the program',
                        style: TextStyle(
                            fontSize: 18,
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    )
                  : _isEditingOrder
                      ? ReorderableListView(
                          onReorder: _reorderExercises,
                          buildDefaultDragHandles: false,
                          children: [
                            for (int index = 0;
                                index < exercises.length;
                                index++)
                              Dismissible(
                                key: ValueKey(exercises[index]['id'] ?? index),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  setState(() {
                                    final removedItem =
                                        exercises.removeAt(index);
                                    _hasChanges = true;
                                    _saveExercises();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${removedItem['name']} removed'),
                                      ),
                                    );
                                  });
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                child: ListTile(
                                  leading: Semantics(
                                    label:
                                        'Exercise image ${exercises[index]['name']}',
                                    child: CircleAvatar(
                                      backgroundImage:
                                          AssetImage(exercises[index]['image']),
                                    ),
                                  ),
                                  title: Text(
                                    exercises[index]['name'] ?? 'Exercise',
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  trailing: ReorderableDragStartListener(
                                    index: index,
                                    child: Semantics(
                                      label: 'Move exercise',
                                      child: const Icon(Icons.drag_handle),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            return Column(
                              children: [
                                ListTile(
                                  leading: Semantics(
                                    label: 'Exercise image ${exercise['name']}',
                                    child: CircleAvatar(
                                      backgroundImage: AssetImage(
                                        exercise['image'],
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    exercise['name'] ?? 'Exercise',
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!exercise['multipleWeights'])
                                        Text(
                                          '${exercise['sets']} sets x ${exercise['reps']} reps\n'
                                          'Weight: ${exercise['weight']?.toStringAsFixed(1) ?? '0.0'} kg\n'
                                          'Rest between sets: ${_formatDuration(exercise['restTime'] ?? 60)}',
                                          style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black87),
                                        ),
                                      if (exercise['multipleWeights'])
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${exercise['sets']} sets x ${exercise['reps']} reps',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                            Text(
                                              'Weight per set:',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                            ...List.generate(
                                              (exercise['weightsPerSet']
                                                      as List<dynamic>)
                                                  .length,
                                              (s) => Text(
                                                '  Set ${s + 1}: ${((exercise['weightsPerSet'] as List<dynamic>)[s] as double).toStringAsFixed(1)} kg',
                                                style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              'Rest between sets: ${_formatDuration(exercise['restTime'] ?? 60)}',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editExercise(index),
                                    tooltip: 'Edit Exercise',
                                  ),
                                ),
                                if (index < exercises.length - 1)
                                  // If not the last exercise, display rest time between exercises
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () =>
                                              _changeRestBetweenExercises(
                                                  index, -10),
                                          tooltip: 'Change Rest time',
                                        ),
                                        Text(
                                          'Rest time: ${_formatDuration(exercises[index]['restBetweenExercises'] ?? 60)}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () =>
                                              _changeRestBetweenExercises(
                                                  index, 10),
                                          tooltip:
                                              'Increase rest time between exercises',
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: CupertinoButton(
                    color: darkWidget,
                    borderRadius: BorderRadius.circular(30.0),
                    onPressed: _addNewExercises,
                    child: const Text(
                      'Add new exercises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
