import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:beh/router.dart';
import 'package:beh/user_provider.dart';
import 'package:beh/theme.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // This error typically occurs on hot restart when Firebase is already initialized.
    // You can ignore it in development, but handle it appropriately in production.
    if (e.code == 'duplicate-app') {
      print('Firebase app already initialized. Ignoring duplicate-app error.');
    } else {
      rethrow; // Re-throw other Firebase exceptions
    }
  } catch (e) {
    rethrow; // Re-throw any other exceptions
  }

  // Initialize Intl locale data used by DateFormat (e.g. 'fr_FR').
  // This avoids LocaleDataException when formatting dates in the app.
  await initializeDateFormatting('fr_FR');

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.theme,
      ),
    ),
  );
}