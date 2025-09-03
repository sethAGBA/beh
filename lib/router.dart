import 'package:beh/my_events_page.dart';
import 'package:beh/main_scaffold.dart';
import 'package:beh/payment/payment_failure_page.dart';
import 'package:beh/payment/payment_success_page.dart';
import 'package:beh/payment/payment_verification_page.dart';
import 'package:beh/payment/payment_confirmation_page.dart';
import 'package:beh/payment/payment_methods_page.dart';
import 'package:beh/order_summary_page.dart';
import 'package:beh/prestation_selection_page.dart';
import 'package:beh/event_creation_page.dart';
import 'package:beh/event_details_page.dart';
import 'package:beh/home_page.dart';
import 'package:beh/service_catalog_page.dart';
import 'package:beh/sign_in.dart';
import 'package:beh/sign_up.dart';
import 'package:beh/profile_page.dart';
import 'package:beh/admin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Main application shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServiceCatalogPage(),
        ),
        // Placeholder for my-events, can be built out later
        GoRoute(
          path: '/my-events',
          builder: (context, state) => const MyEventsPage(),
          routes: [
            GoRoute(
              path: 'details/:eventId',
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
                  routes: [
                    GoRoute(
                      path: 'payment',
                      builder: (context, state) {
                        final eventId = state.pathParameters['eventId'];
                        // state.extra may be passed as a double or as a Map containing an amount.
                        double? totalAmount;
                        if (state.extra is double) {
                          totalAmount = state.extra as double;
                        } else if (state.extra is Map) {
                          final m = state.extra as Map<dynamic, dynamic>;
                          final a = m['amount'];
                          if (a is double) {
                            totalAmount = a;
                          } else if (a is int) {
                            totalAmount = a.toDouble();
                          } else if (a is String) {
                            totalAmount = double.tryParse(a);
                          }
                        }
                        if (eventId == null || totalAmount == null) {
                          return const Text(
                              'Error: Event ID or amount not found');
                        }
                        return PaymentMethodsPage(
                            eventId: eventId, totalAmount: totalAmount);
                      },
                      routes: [
                        GoRoute(
                          path: 'confirm',
                          builder: (context, state) {
                            final eventId = state.pathParameters['eventId'];
                            final extra =
                                state.extra as Map<String, dynamic>?;
                            if (eventId == null || extra == null) {
                              return const Text(
                                  'Error: Event ID or extra data not found');
                            }
                            // Safely extract method and amount from extra
                            final methodVal = extra['method'];
                            final amountVal = extra['amount'];
                            String? method;
                            double? amount;
                            if (methodVal is String) method = methodVal;
                            if (amountVal is double) {
                              amount = amountVal;
                            } else if (amountVal is int) {
                              amount = amountVal.toDouble();
                            } else if (amountVal is String) {
                              amount = double.tryParse(amountVal);
                            }
                            if (method == null || amount == null)
                              return const Text('Error: invalid payment data');
                            return PaymentConfirmationPage(
                              eventId: eventId,
                              method: method,
                              amount: amount,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'verify',
                          builder: (context, state) {
                            final eventId = state.pathParameters['eventId'];
                            final extra =
                                state.extra as Map<String, dynamic>?;
                            if (eventId == null || extra == null) {
                              return const Text(
                                  'Error: Event ID or extra data not found');
                            }
                            final methodVal = extra['method'];
                            final amountVal = extra['amount'];
                            String? method;
                            double? amount;
                            if (methodVal is String) method = methodVal;
                            if (amountVal is double) {
                              amount = amountVal;
                            } else if (amountVal is int) {
                              amount = amountVal.toDouble();
                            } else if (amountVal is String) {
                              amount = double.tryParse(amountVal);
                            }
                            if (method == null || amount == null)
                              return const Text('Error: invalid payment data');
                            return PaymentVerificationPage(
                              eventId: eventId,
                              method: method,
                              amount: amount,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'success',
                          builder: (context, state) {
                            final eventId = state.pathParameters['eventId'];
                            if (eventId == null) {
                              return const Text('Error: Event ID not found');
                            }
                            return PaymentSuccessPage(eventId: eventId);
                          },
                        ),
                        GoRoute(
                          path: 'failure',
                          builder: (context, state) {
                            final eventId = state.pathParameters['eventId'];
                            if (eventId == null) {
                              return const Text('Error: Event ID not found');
                            }
                            return PaymentFailurePage(eventId: eventId);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Standalone routes (no shell)
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return '/signin';
        } else {
          // If logged in, default to the home page within the shell
          return '/home';
        }
      },
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) {
        final Map<String, dynamic>? extra =
            state.extra as Map<String, dynamic>?;
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
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPage(),
    ),
    GoRoute(
      path: '/create-event/:eventType',
      builder: (context, state) {
        final eventType = state.pathParameters['eventType'] ?? 'generic';
        final eventDoc = state.extra as DocumentSnapshot?;
        return EventCreationPage(eventType: eventType, eventDoc: eventDoc);
      },
    ),
    GoRoute(
      path: '/event-details/:eventId',
      redirect: (context, state) {
        final eventId = state.pathParameters['eventId'];
        return '/my-events/details/$eventId';
      },
    ),
  ],
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
);