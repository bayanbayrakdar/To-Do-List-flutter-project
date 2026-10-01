import 'package:flutter/material.dart';

/// Shared layout for Login and Register:
/// icon + title + subtitle above a white card that holds the form.
/// The width is limited so it looks good on a big Windows window too.
class AuthFormLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final PreferredSizeWidget? appBar;

  const AuthFormLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: appBar,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(icon, size: 32, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: Padding(padding: const EdgeInsets.all(24), child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
