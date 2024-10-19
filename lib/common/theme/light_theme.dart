import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/utils/coloors.dart';

ThemeData lightTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: Coloors.backgroundLight,
    extensions: [
      CustomThemeExtension.lightMode,
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: Coloors.greenLight,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(255, 255, 255, 1),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: Colors.white,
          width: 2,
        ),
      ),
      unselectedLabelColor: Color(0xFFB3D9D2),
      labelColor: Colors.white,
    ),
    colorScheme: ThemeData().colorScheme.copyWith(
          surface: Coloors.backgroundLight,
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Coloors.greenLight,
        foregroundColor: Coloors.backgroundLight,
        splashFactory: NoSplash.splashFactory,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Coloors.backgroundLight,
      modalBackgroundColor: Coloors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogBackgroundColor: Coloors.backgroundLight,
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Coloors.greenDark,
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Coloors.greenDark,
      tileColor: Coloors.backgroundLight,
      textColor: Color.fromRGBO(0, 0, 0, 1),
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Color(0xFF83939C)),
      trackColor: WidgetStatePropertyAll(
        Color(0XFFDADFE2),
      ),
    ),
  );
}
