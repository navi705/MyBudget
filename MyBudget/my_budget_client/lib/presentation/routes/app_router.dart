import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/debug/debug_screen.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/add_edit_transaction_screen.dart';
import 'package:my_budget_client/presentation/screens/dashboard_screen.dart';
import 'package:my_budget_client/presentation/screens/edit_account_screen.dart';
import 'package:my_budget_client/presentation/screens/edit_style_screen.dart';
import 'package:my_budget_client/presentation/screens/import_screen.dart';
import 'package:my_budget_client/presentation/screens/main_screen.dart';
import 'package:my_budget_client/presentation/screens/manage_styles_screen.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';
import 'package:my_budget_client/presentation/screens/theme_settings_screen.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/screens/data_screen.dart';
import 'package:my_budget_client/presentation/screens/api_settings_screen.dart';
import 'package:my_budget_client/domain/entities/account.dart';

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
            return const CategoriesScreen(isStandalone: true);
          },
        ),
        GoRoute(
          path: AppRoutes.exchangeRates,
          builder: (context, state) {
            return const DataScreen(initialTabIndex: 0);
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) {
            return const SettingsScreen();
          },
        ),
        if (kDebugMode)
          GoRoute(
            path: AppRoutes.debug,
            builder: (context, state) => const DebugScreen(),
          ),
        GoRoute(
          path: AppRoutes.manageAccountStyles,
          builder: (context, state) {
            return const ManageStylesScreen();
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.editAccount,
      builder: (context, state) {
        final account = state.extra as Account?;
        if (account == null) {
          // Handle the case where the account is not provided,
          // maybe by navigating back or showing an error.
          // For now, let's just return an empty container or an error screen.
          return const Scaffold(
            body: Center(child: Text('Account not found!')),
          );
        }
        return EditAccountScreen(account: account);
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
        Transaction? transaction;
        String? accountId;
        bool isTransfer = false;
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          transaction = extra['transaction'] as Transaction?;
          accountId = extra['accountId'] as String?;
          isTransfer = extra['isTransfer'] as bool? ?? false;
        }

        return AddEditTransactionScreen(
          transaction: transaction,
          accountId: accountId,
          isTransfer: isTransfer,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.importScreen,
      builder: (context, state) {
        return const ImportScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.themeSettings,
      builder: (context, state) {
        return const ThemeSettingsScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.apiSettings,
      builder: (context, state) {
        return const ApiSettingsScreen();
      },
    ),
  ],
);
