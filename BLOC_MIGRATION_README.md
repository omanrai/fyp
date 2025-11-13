# 🔄 Flutter GetX to Bloc Migration Guide

This document explains how to migrate your Flutter LMS app from GetX to Bloc state management.

## 📋 Phase 1: Authentication Bloc (COMPLETED) ✅

### What's Been Created

1. **Core Bloc Foundation**
   - `lib/core/bloc/base_state.dart` - Common state classes
   - `lib/core/bloc/base_event.dart` - Common event classes  
   - `lib/core/bloc/bloc_utils.dart` - Helper utilities

2. **AuthBloc Components**
   - `lib/feature/bloc/auth/auth_event.dart` - Authentication events
   - `lib/feature/bloc/auth/auth_state.dart` - Authentication states
   - `lib/feature/bloc/auth/auth_bloc.dart` - Main authentication logic
   - `lib/feature/bloc/auth/auth_bloc_export.dart` - Barrel exports

3. **Example Implementation**
   - `lib/feature/screen/auth/login_screen_bloc.dart` - Bloc-based login screen
   - `lib/example_main_bloc.dart` - Example main app setup

## 🚀 How to Use the AuthBloc

### 1. Setup in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature/bloc/auth/auth_bloc_export.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(const AuthStatusChecked()),
      child: MaterialApp(
        // Your app setup
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
```

### 2. Using AuthBloc in Widgets

#### Login Screen Example:
```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthAuthenticated) {
          // Navigate to main screen
          Navigator.pushReplacement(context, /* main screen route */);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Scaffold(
          body: Column(
            children: [
              // Login form fields
              ElevatedButton(
                onPressed: isLoading ? null : () {
                  // Trigger login event
                  context.read<AuthBloc>().add(LoginRequested(
                    email: emailController.text,
                    password: passwordController.text,
                  ));
                },
                child: isLoading 
                  ? CircularProgressIndicator()
                  : Text('Login'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## 🔄 GetX vs Bloc Comparison

### GetX Controller Way (OLD):
```dart
class LoginController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  
  Future<void> loginUser() async {
    isLoading.value = true;
    // API call
    isLoading.value = false;
  }
}

// In UI:
Obx(() => Text(controller.user.value?.name ?? 'Not logged in'))
```

### Bloc Way (NEW):
```dart
// Events
class LoginRequested extends AuthEvent {
  final String email, password;
  // ...
}

// States
class AuthAuthenticated extends AuthState {
  final UserModel user;
  // ...
}

// In UI:
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthAuthenticated) {
      return Text(state.user.name);
    }
    return Text('Not logged in');
  },
)
```

## 📚 Available AuthBloc Events

```dart
// Login with email/password
context.read<AuthBloc>().add(LoginRequested(
  email: 'user@example.com',
  password: 'password123',
));

// Login with biometrics
context.read<AuthBloc>().add(const BiometricLoginRequested());

// Register new user
context.read<AuthBloc>().add(RegisterRequested(
  email: 'new@example.com',
  password: 'password123',
  name: 'John Doe',
  role: 'student',
));

// Logout
context.read<AuthBloc>().add(const LogoutRequested());

// Check auth status (auto-login)
context.read<AuthBloc>().add(const AuthStatusChecked());

// Toggle password visibility
context.read<AuthBloc>().add(const PasswordVisibilityToggled());

// Enable/disable biometrics
context.read<AuthBloc>().add(const BiometricEnableRequested());
context.read<AuthBloc>().add(const BiometricDisableRequested());
```

## 🎯 Migration Benefits

### Why Bloc > GetX:
- ✅ **Better Testing** - Blocs are easily testable with `bloc_test` package
- ✅ **Predictable State** - Clear state transitions with `BlocObserver`
- ✅ **Flutter Recommended** - Official Flutter team recommendation  
- ✅ **Better DevTools** - Excellent debugging with Bloc Inspector
- ✅ **Separation of Concerns** - Clear separation of events, states, and logic
- ✅ **Immutable States** - Prevents accidental state mutations
- ✅ **Better Architecture** - Follows BLoC pattern principles

## 📈 Next Steps - Remaining Features to Migrate

### Phase 2: Course Management
- Create `CourseBloc` for course-related operations
- Migrate `CourseController` functionality

### Phase 3: Chat System  
- Create `ChatBloc` for real-time messaging
- Migrate `GroupChatController` functionality

### Phase 4: Enrollment System
- Create `EnrollmentBloc` for student enrollment
- Migrate `EnrollmentController` functionality

### Phase 5: Cleanup
- Remove GetX dependency
- Remove old controllers
- Update all UI components

## 🧪 Testing Your AuthBloc

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () => authBloc,
      act: (bloc) => bloc.add(LoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );
  });
}
```

## 🎉 Getting Started

1. **Test the AuthBloc**: 
   - Run `flutter run lib/example_main_bloc.dart` to see the Bloc version in action
   - Try login, biometrics, logout functionality

2. **Replace Your Current Login Screen**:
   - Replace your current `login_screen.dart` with `login_screen_bloc.dart`
   - Update your main.dart to use BlocProvider

3. **Start Using**: 
   - Begin using AuthBloc in your existing app
   - Gradually migrate other features

Ready to continue with Phase 2? Let me know which feature you'd like to migrate next! 🚀
