import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/theme/dark_theme.dart';
import 'package:tuyage/common/theme/light_theme.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/home/pages/home_page.dart';
import 'package:tuyage/feature/welcome/pages/welcome_page.dart';
import 'package:tuyage/firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offline_messages');
  await Hive.openBox('phoneNumberCache');
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    print('Firebase initialisé avec succès');
  }).catchError((e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
  });

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tuyage Burundi',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      home: ref.watch(userInfoAuthProvider).when(
        data: (user) {
          print('Données utilisateur récupérées: $user');
          FlutterNativeSplash.remove();
          if (user == null) {
            print('L\'utilisateur est null, affichage de la WelcomePage');
            return const WelcomePage();
          }
          print('L\'utilisateur est authentifié, affichage de la HomePage');
          return const HomePage();
        },
        error: (error, trace) {
          print('Erreur: $error');
          return Scaffold(
            body: Center(
              child: Text('Habaye ikibazo kivuga $error'),
            ),
          );
        },
        loading: () {
          print('Chargement en cours...');
          return const SizedBox();
        },
      ),
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
