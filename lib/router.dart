import 'package:beh/order_summary_page.dart';
import 'package:beh/prestation_selection_page.dart';
import 'package:beh/event_creation_page.dart';
import 'package:beh/event_details_page.dart';
import 'package:beh/home_page.dart';
import 'package:beh/sign_in.dart';
import 'package:beh/sign_up.dart';
import 'package:beh/profile_page.dart';
import 'package:beh/admin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Import for StreamSubscription

// Helper class to convert a Stream to a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // Notify immediately to check initial state
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return '/signin'; // Should redirect here if user is null
        } else {
          return '/home';
        }
      },
      builder: (context, state) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Show loading while redirecting
        ),
      ),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) {
        final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
        return SignInScreen(
          initialEmail: extra?['email'],
          initialPassword: extra?['password'],
        );
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPage(),
    ),
    GoRoute(
      path: '/create-event',
      builder: (context, state) => const EventCreationPage(),
    ),
    GoRoute(
      path: '/event-details/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId'];
        if (eventId == null) {
          return const Text('Error: Event ID not found');
        }
        return EventDetailsPage(eventId: eventId);
      },
      routes: [
        GoRoute(
          path: 'prestations',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'];
            if (eventId == null) {
              return const Text('Error: Event ID not found');
            }
            return PrestationSelectionPage(eventId: eventId);
          },
        ),
        GoRoute(
          path: 'summary',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'];
            if (eventId == null) {
              return const Text('Error: Event ID not found');
            }
            return OrderSummaryPage(eventId: eventId);
          },
        ),
      ]
    ),
  ],
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()), // Added this line
);