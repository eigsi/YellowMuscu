# YELLOWMUSCU - IDATA2503

## Introduction
The objective of this project is to create a cross-platform Musculation app using `Flutter`, available on Android and IOS .
This application will accompany you during your training sessions and help you motivate yourself and see your progress.

## Project Features

This project runs on `dart` and can be launched on the simulator of your choice using `Android studio` for Android devices, and `Xcode` pour IOS devices, and allows you to simulate a fonctional Musculation application. It's also ready to run on any iPhone running iOS 16 if connected to a Mac with the application running in Xcode.

- There are 5 main pages : homepage, exercices, session, statistics and profile.
- Users can follow their friends, view their progress, and interact with them.
- Users can have a statistic report of their performances.
- Users can create a personalize session, and choice between a large amount of exercices.
- Notifications are displayed to improve the social experience.
- The app guides users during their sessions by providing break times and instructions for the exercises.


## Project Prerequisites
- **Flutter SDK**: Version 3.x or higher
- **Dart SDK**: Included with Flutter
- **Android Studio**: Version 2022.x or higher (for Android)
- **Xcode**: Version 14.x or higher (for iOS)
  
You need at least one emulateur to run this project, like `Android studio` or `Xcode`. You also need to install flutter on your device.
To set up your flutter environement, you can follow the [macOS Setup](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/learn/lecture/37213684#overview) or [Windows Setup](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/learn/lecture/37213680#overview) video from the course "A Complete Guide to the Flutter FrameWork on Udemy. A basic understanding of Dart and Flutter is recommended.

## Installation
1. **Clone the GitHub repo**
```bash
git clone https://github.com/eigsi/YellowMuscu.git
cd YellowMuscu
```
2. **Look for a simulator device to use**
```bash
flutter devices
```
3. **run the Application**
```bash
flutter run -d [device id]
```
4. **refresh after changes**
```bash
flutter hot reload
```

## Material
The application's data is located in the file `/lib/data/exercices_data.dart`
The tutorial pictures to help you understand how the application work are on `/lib/data/tutorial/`

## Contributing
This project is a collaborative effort by a team of 4 students as part of the IDATA2503 course. Contributions are managed internally among team members.

