# YELLOWMUSCU - IDATA2503

The objective of this project is to create a cross-plateform Musculation app using `Flutter`, available on Android and IOS .
This application will accompany you during your training sessions and help you motivate yourself and see your progress.

## Project Features

This project runs on `dart` and can be launched on the simulator of your choice using `Android studio` for Android devices, and `Xcode` pour IOS devices, and allows you to simulate a fonctional quizz application. It's also ready to run on any iPhone running iOS 16 if connected to a Mac with the application running in Xcode.
- There are 10 categories, offering a total of 10 meals.
- There is a favorite section where the user can find the recipes he saved.
- Users can now select a meal difficulty level (easy, challenging, or hard) in the filters section.
- In the categories screen, only categories containing meals that match the selected filters are displayed.


## Project Prerequisites
You need at least one emulateur to run this project, like `Android studio` or `Xcode`. You also need to install flutter on your device.
To set up your flutter environement, you can follow the [macOS Setup](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/learn/lecture/37213684#overview) or [Windows Setup](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/learn/lecture/37213680#overview) video from the course "A Complete Guide to the Flutter FrameWork on Udemy.

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



