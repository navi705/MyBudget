import 'package:flutter/material.dart';

/// A splash screen that shows initialization progress.
class SplashScreen extends StatelessWidget {
  final String message;
  final double? progress;

  const SplashScreen({super.key, this.message = 'Loading...', this.progress});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 56,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              const Text(
                'MyBudget',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),

              // Progress Indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    if (progress != null)
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      )
                    else
                      const LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
