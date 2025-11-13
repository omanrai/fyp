import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature/bloc/auth/auth_bloc_export.dart';
import 'feature/screen/auth/login_screen_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide AuthBloc at the root level so it's accessible throughout the app
      create: (context) => AuthBloc()..add(const AuthStatusChecked()),
      child: MaterialApp(
        title: 'LMS App - Bloc Version',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
          useMaterial3: true,
        ),
        // Use BlocBuilder to handle initial route based on auth state
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Show loading screen while checking auth status
            if (state is AuthInitial || 
                (state is AuthLoading && state.loadingMessage?.contains('Checking') == true)) {
              return const SplashScreen();
            }
            
            // If user is authenticated, show main screen
            if (state is AuthAuthenticated) {
              // Replace with your MainScreen
              return const MainScreenPlaceholder();
            }
            
            // Otherwise, show login screen
            return const LoginScreenBloc();
          },
        ),
      ),
    );
  }
}

// Placeholder splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6366F1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LMS App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder main screen
class MainScreenPlaceholder extends StatelessWidget {
  const MainScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Text('Profile (${state.user.name})'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome, ${state.user.name}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Role: ${state.user.role}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 16),
                  if (state.canUseBiometrics) ...[
                    if (state.isBiometricEnabled)
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(const BiometricDisableRequested());
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Disable Biometrics'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(const BiometricEnableRequested());
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Enable Biometrics'),
                      ),
                  ],
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
