import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/add_edit_transaction_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/screens/dashboard_screen.dart';
import 'package:my_budget_client/presentation/screens/edit_account_screen.dart';
import 'package:my_budget_client/presentation/screens/edit_style_screen.dart';
import 'package:my_budget_client/presentation/screens/main_screen.dart';
import 'package:my_budget_client/presentation/screens/manage_styles_screen.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';

// Private navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// The router configuration.
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.dashboard,
  navigatorKey: _rootNavigatorKey,
  routes: <RouteBase>[
    /// MainWrapper
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScreen(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) {
            return const DashboardScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.accounts,
          builder: (context, state) {
            return const AccountsScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.transactions,
          builder: (context, state) {
            return const TransactionsScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.categories,
          builder: (context, state) {
            return const CategoriesScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) {
            return const SettingsScreen();
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.editAccount,
      builder: (context, state) {
        final accountId = state.pathParameters['id']!;
        return EditAccountScreen(accountId: accountId);
      },
    ),
    GoRoute(
      path: AppRoutes.manageAccountStyles,
      builder: (context, state) {
        return const ManageStylesScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.editAccountStyle,
      builder: (context, state) {
        final styleId = state.pathParameters['id']!;
        return EditStyleScreen(styleId: styleId);
      },
    ),
    GoRoute(
      path: AppRoutes.addEditTransaction,
      builder: (context, state) {
        int? transactionId;
        int? categoryId;

        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          transactionId = extra['transactionId'];
          categoryId = extra['categoryId'];
        }

        return AddEditTransactionScreen(
          transactionId: transactionId,
          categoryId: categoryId,
        );
      },
    ),
  ],
);
