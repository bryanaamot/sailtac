# SailTac

## High Priority

## Medium Priority
- Add Lat/Lon to remaining clubs
- Add velocity when sending location

## Low Priority
- Search course by name
- Add status field to club: new, approved, removed
- Allow users to share "new" clubs as they are waiting to be approved
- Allow users to request removal of a club.
- Add Gate

## Completed
- Improve visibility of "Search by club name" on clubs screen.
- Add an "X" to slide-up screens
- Add Delete Course option
- Change "Create" button to "+" button in upper right
- Add tools page to calculate things like: start line width based on boat length
- Use GPS to broadcast the user's position instead of the fake position.
- Move club name from nav title to the screen.
- Add edit course name. Maybe use menu in upper right?
- Center map using course center
- Change Android map circle to match iOS
- Added delete option for courses
- Remove Reload button on map
- Sort course list by last-modified date
- Show bearing to the selected mark.
- Enable compass
- If the user joins, send mark updates made by other people
- Let slideup sheet for club use [.medium, .large] option.
- Let users choose clubs on a map
x Change defult color for links (from light blue to ?)
- Add map type option
- Let users choose course on by map
x See if we can create a skip-map based on the work that was done.
- Save edit mark changes
- Hook up delete mark button
- Add Edit mark (name, position) sheet
- Add polylines to Android
- Add Edit Mark
- Add Android Map support
- Change dashes so they are under marks
- Show bearing and distance when moving relative marks
- Show lat/lon when moving fixed marks
- Use bearing/distance when creating a relative mark
- Set Relative Mark using bearing and distance
- Show Wind direction on button
- Add Wind control
- Add Wind to Course
- Add Relative and Fixed marks
- Let user name their mark
- Add mark: starboard or port rounding
- Let user define their boat by name.
- Let user move markers


This is a [Skip](https://skip.tools) dual-platform app project.
It builds a native app for both iOS and Android.

## Building

This project is both a stand-alone Swift Package Manager module,
as well as an Xcode project that builds and transpiles the project
into a Kotlin Gradle project for Android using the Skip plugin.

Building the module requires that Skip be installed using
[Homebrew](https://brew.sh) with `brew install skiptools/skip/skip`.

This will also install the necessary transpiler prerequisites:
Kotlin, Gradle, and the Android build tools.

Installation prerequisites can be confirmed by running `skip checkup`.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.

## Running

Xcode and Android Studio must be downloaded and installed in order to
run the app in the iOS simulator / Android emulator.
An Android emulator must already be running, which can be launched from 
Android Studio's Device Manager.

To run both the Swift and Kotlin apps simultaneously, 
launch the SailTacApp target from Xcode.
A build phases runs the "Launch Android APK" script that
will deploy the transpiled app a running Android emulator or connected device.
Logging output for the iOS app can be viewed in the Xcode console, and in
Android Studio's logcat tab for the transpiled Kotlin app.
