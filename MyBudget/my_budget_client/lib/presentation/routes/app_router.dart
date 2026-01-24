import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/navigation/navigator_keys.dart';
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
import '../screens/hot_keys_screen.dart';
import 'package:my_budget_client/presentation/screens/theme_settings_screen.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/screens/data_screen.dart';
import 'package:my_budget_client/presentation/screens/api_settings_screen.dart';
import 'package:my_budget_client/presentation/screens/sms_settings_screen.dart';
import 'package:my_budget_client/presentation/screens/sync_settings_screen.dart';
import 'package:my_budget_client/domain/entities/account.dart';

// Navigator keys now handled by AppNavigator

/// The router configuration.
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.dashboard,
  navigatorKey: AppNavigator.rootNavigatorKey,
  routes: <RouteBase>[
    /// MainWrapper
    ShellRoute(
      navigatorKey: AppNavigator.shellNavigatorKey,
      builder: (context, state, child) {
        return MainScreen(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) {
            return _buildPage(const DashboardScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.accounts,
          pageBuilder: (context, state) {
            return _buildPage(const AccountsScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.transactions,
          pageBuilder: (context, state) {
            return _buildPage(const TransactionsScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.categories,
          pageBuilder: (context, state) {
            return _buildPage(const CategoriesScreen(isStandalone: true));
          },
        ),
        GoRoute(
          path: AppRoutes.exchangeRates,
          pageBuilder: (context, state) {
            return _buildPage(const DataScreen(initialTabIndex: 0));
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) {
            return _buildPage(const SettingsScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.hotKeys,
          pageBuilder: (context, state) {
            return _buildPage(const HotKeysScreen());
          },
        ),
        if (kDebugMode)
          GoRoute(
            path: AppRoutes.debug,
            pageBuilder: (context, state) => _buildPage(const DebugScreen()),
          ),
        GoRoute(
          path: AppRoutes.manageAccountStyles,
          pageBuilder: (context, state) {
            return _buildPage(const ManageStylesScreen());
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.editAccount,
      pageBuilder: (context, state) {
        final account = state.extra as Account?;
        if (account == null) {
          return _buildPage(
            const Scaffold(body: Center(child: Text('Account not found!'))),
          );
        }
        return _buildPage(EditAccountScreen(account: account));
      },
    ),
    GoRoute(
      path: AppRoutes.editAccountStyle,
      pageBuilder: (context, state) {
        final styleId = state.pathParameters['id']!;
        return _buildPage(EditStyleScreen(styleId: styleId));
      },
    ),
    GoRoute(
      path: AppRoutes.addEditTransaction,
      pageBuilder: (context, state) {
        Transaction? transaction;
        String? accountId;
        bool isTransfer = false;
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          transaction = extra['transaction'] as Transaction?;
          accountId = extra['accountId'] as String?;
          isTransfer = extra['isTransfer'] as bool? ?? false;
        }

        return _buildPage(
          AddEditTransactionScreen(
            transaction: transaction,
            accountId: accountId,
            isTransfer: isTransfer,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.importScreen,
      pageBuilder: (context, state) {
        return _buildPage(const ImportScreen());
      },
    ),
    GoRoute(
      path: AppRoutes.themeSettings,
      pageBuilder: (context, state) {
        return _buildPage(const ThemeSettingsScreen());
      },
    ),
    GoRoute(
      path: AppRoutes.apiSettings,
      pageBuilder: (context, state) {
        return _buildPage(const ApiSettingsScreen());
      },
    ),
    GoRoute(
      path: AppRoutes.smsSettings,
      pageBuilder: (context, state) {
        return _buildPage(const SmsSettingsScreen());
      },
    ),
    GoRoute(
      path: AppRoutes.syncSettings,
      pageBuilder: (context, state) {
        return _buildPage(const SyncSettingsScreen());
      },
    ),
  ],
);

CustomTransitionPage _buildPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child; // No animation
    },
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
