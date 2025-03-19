import 'package:flutter/material.dart';

// UTSA colors
const Color utsaBlue = Color(0xFF042444); // UTSA Blue
const Color utsaOrange = Color(0xFFD88D61); // UTSA Orange

// O.D.D. colors
const Color oddRed = Color(0xffffbf99);  // O.D.D. Red
const Color oddBlue = Color(0xFF334D66); // O.D.D. Blue

final ThemeData customTheme = ThemeData(
  primaryColor: utsaBlue,  // Primary color for app bar, buttons, etc.
  scaffoldBackgroundColor: Colors.white,  // Background color of the whole app
  colorScheme: ColorScheme.light(
    primary: utsaBlue,   // Primary color
    secondary: oddRed,   // Secondary color
    surface: Colors.white,  // Use 'surface' instead of 'background'
    onSurface: Colors.black, // Text color for surface (e.g., card, scaffold background)
    onPrimary: Colors.white, // Text color on primary background
    onSecondary: Colors.black, // Text color on secondary background
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: utsaBlue, // Set app bar color to UTSA blue
    elevation: 0,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: oddBlue, // Use O.D.D. blue for buttons
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.black), // Default text color (previously bodyText1)
    bodyMedium: TextStyle(color: Colors.black), // Default text color (previously bodyText2)
    titleLarge: TextStyle(color: Colors.white), // Updated headline6 to titleLarge
  ),
  iconTheme: IconThemeData(color: oddRed), // Icon color for better contrast
);
