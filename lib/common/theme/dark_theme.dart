import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/utils/coloors.dart';

ThemeData darkTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: Coloors.backgroundDark,
    extensions: [
      CustomThemeExtension.darkMode,
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: Coloors.greyBackground,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(255, 255, 255, 1),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(
        color: Coloors.greyDark,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: Coloors.greenDark,
          width: 2,
        ),
      ),
      unselectedLabelColor: Coloors.greyDark,
      labelColor: Coloors.greenDark,
    ),
    colorScheme: ThemeData().colorScheme.copyWith(
          surface: Coloors.backgroundDark,
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: Coloors.greenDark,
      foregroundColor: Coloors.backgroundDark,
      splashFactory: NoSplash.splashFactory,
      elevation: 0,
      shadowColor: Colors.transparent,
    )),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Coloors.greyBackground,
      modalBackgroundColor: Coloors.greyBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogBackgroundColor: Coloors.greyBackground,
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
      iconColor: Coloors.greyDark,
      tileColor: Coloors.backgroundDark,
      textColor: Color.fromRGBO(255, 255, 255, 1),
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Coloors.greyDark),
      trackColor: WidgetStatePropertyAll(Color(0xFF344047)),
    ),
  );
}
