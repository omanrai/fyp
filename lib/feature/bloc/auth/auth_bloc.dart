import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/bloc/bloc_utils.dart';
import '../../model/auth/user_model.dart';
import '../../services/api_services.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocStateMixin {
  // Dependencies
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Current state tracking
  bool _canUseBiometrics = false;
  bool _isBiometricEnabled = false;

  AuthBloc() : super(const AuthInitial()) {
    // Register event handlers
    on<LoginRequested>(_onLoginRequested);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<BiometricEnableRequested>(_onBiometricEnableRequested);
    on<BiometricDisableRequested>(_onBiometricDisableRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<ProfileImageSelected>(_onProfileImageSelected);
    on<ImageUploadingStateChanged>(_onImageUploadingStateChanged);

    // Initialize biometric capabilities
    _initializeBiometrics();
  }

  /// Initialize biometric capabilities on bloc creation
  Future<void> _initializeBiometrics() async {
    try {
      _canUseBiometrics = await _localAuth.canCheckBiometrics;
      await _loadBiometricPreference();
      log('Biometric capabilities initialized: canUse=$_canUseBiometrics, enabled=$_isBiometricEnabled');
    } catch (e) {
      log('Error initializing biometrics: $e');
      _canUseBiometrics = false;
      _isBiometricEnabled = false;
    }
  }

  /// Load biometric preference from secure storage
  Future<void> _loadBiometricPreference() async {
    try {
      String? value = await _secureStorage.read(key: 'biometric_enabled');
      _isBiometricEnabled = value == 'true' && _canUseBiometrics;
      log('Biometric preference loaded: $_isBiometricEnabled');
    } catch (e) {
      log('Error loading biometric preference: $e');
      _isBiometricEnabled = false;
    }
  }

  /// Handle login with email and password
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    emit(AuthLoading(
      loadingMessage: 'Logging in...',
      isPasswordVisible: _getPasswordVisibility(),
      canUseBiometrics: _canUseBiometrics,
      isBiometricEnabled: _isBiometricEnabled,
    ));

    try {
      final response = await ApiService.loginUser(event.email, event.password);

      if (response.success && response.data != null) {
        final userData = response.data!;
        final user = UserModel.fromJson(userData);
        
        // Store credentials securely
        await _storeUserCredentials(user, event.email);
        
        log('Login successful: ${user.name}, ${user.email}');
        
        emit(AuthAuthenticated(
          user: user,
          isPasswordVisible: false, // Reset password visibility after login
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
        ));
      } else {
        emit(AuthError(
          message: response.message,
          isPasswordVisible: _getPasswordVisibility(),
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
        ));
      }
    } catch (e) {
      log('Login error: $e');
      emit(AuthError(
        message: 'Login failed: ${e.toString()}',
        errorCode: 'LOGIN_EXCEPTION',
        isPasswordVisible: _getPasswordVisibility(),
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
    }
  }

  /// Handle biometric login
  Future<void> _onBiometricLoginRequested(
    BiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    if (!_isBiometricEnabled || !_canUseBiometrics) {
      emit(AuthError(
        message: 'Biometric authentication is not available or enabled',
        isPasswordVisible: _getPasswordVisibility(),
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
      return;
    }

    emit(AuthLoading(
      loadingMessage: 'Authenticating with biometrics...',
      isPasswordVisible: _getPasswordVisibility(),
      canUseBiometrics: _canUseBiometrics,
      isBiometricEnabled: _isBiometricEnabled,
    ));

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to log in to LMS',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Load user data from secure storage
        final userData = await _loadStoredUserData();
        if (userData != null) {
          emit(AuthAuthenticated(
            user: userData,
            canUseBiometrics: _canUseBiometrics,
            isBiometricEnabled: _isBiometricEnabled,
          ));
        } else {
          emit(AuthError(
            message: 'No stored user data found. Please login with credentials.',
            isPasswordVisible: _getPasswordVisibility(),
            canUseBiometrics: _canUseBiometrics,
            isBiometricEnabled: _isBiometricEnabled,
          ));
        }
      } else {
        emit(AuthError(
          message: 'Biometric authentication failed',
          isPasswordVisible: _getPasswordVisibility(),
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
        ));
      }
    } catch (e) {
      log('Biometric authentication error: $e');
      emit(AuthError(
        message: 'Biometric authentication failed: ${e.toString()}',
        isPasswordVisible: _getPasswordVisibility(),
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
    }
  }

  /// Handle user registration
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    emit(AuthLoading(
      loadingMessage: 'Registering user...',
      isPasswordVisible: _getPasswordVisibility(),
      canUseBiometrics: _canUseBiometrics,
      isBiometricEnabled: _isBiometricEnabled,
      selectedProfileImage: _getSelectedImage(),
    ));

    try {
      final response = await ApiService.registerUser(
        event.email,
        event.password,
        event.name,
        event.role,
        imagePath: event.imagePath,
      );

      if (response.success) {
        log('Registration successful');
        emit(AuthUnauthenticated(
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
        ));
      } else {
        emit(AuthError(
          message: response.message,
          isPasswordVisible: _getPasswordVisibility(),
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
          selectedProfileImage: _getSelectedImage(),
        ));
      }
    } catch (e) {
      log('Registration error: $e');
      emit(AuthError(
        message: 'Registration failed: ${e.toString()}',
        errorCode: 'REGISTRATION_EXCEPTION',
        isPasswordVisible: _getPasswordVisibility(),
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
        selectedProfileImage: _getSelectedImage(),
      ));
    }
  }

  /// Handle logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    emit(AuthLoading(
      loadingMessage: 'Logging out...',
      canUseBiometrics: _canUseBiometrics,
      isBiometricEnabled: _isBiometricEnabled,
    ));

    try {
      // Clear stored credentials (but keep biometric preference)
      await _secureStorage.delete(key: 'user_data');
      await _secureStorage.delete(key: 'user_token');
      await _secureStorage.delete(key: 'user_email');
      
      log('User logged out successfully');
      
      emit(AuthUnauthenticated(
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
    } catch (e) {
      log('Logout error: $e');
      // Even if there's an error, still log the user out locally
      emit(AuthUnauthenticated(
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
    }
  }

  /// Check authentication status (auto-login)
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    emit(AuthLoading(
      loadingMessage: 'Checking authentication status...',
      canUseBiometrics: _canUseBiometrics,
      isBiometricEnabled: _isBiometricEnabled,
    ));

    try {
      final userData = await _loadStoredUserData();
      if (userData != null) {
        log('User found in storage: ${userData.name}');
        emit(AuthAuthenticated(
          user: userData,
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
        ));
      } else {
        log('No stored user data found');
        emit(AuthUnauthenticated(
          canUseBiometrics: _canUseBiometrics,
          isBiometricEnabled: _isBiometricEnabled,
        ));
      }
    } catch (e) {
      log('Error checking auth status: $e');
      emit(AuthUnauthenticated(
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
    }
  }

  /// Handle enabling biometric authentication
  Future<void> _onBiometricEnableRequested(
    BiometricEnableRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    if (!_canUseBiometrics) {
      emit(_copyCurrentStateWithError(
        'Biometric authentication is not available on this device.',
      ));
      return;
    }

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.write(key: 'biometric_enabled', value: 'true');
        _isBiometricEnabled = true;
        
        log('Biometric authentication enabled');
        
        if (state is AuthAuthenticated) {
          final currentState = state as AuthAuthenticated;
          emit(currentState.copyWith(isBiometricEnabled: true));
        } else {
          emit(AuthBiometricEnabled(
            canUseBiometrics: _canUseBiometrics,
            isBiometricEnabled: _isBiometricEnabled,
          ));
        }
      } else {
        emit(_copyCurrentStateWithError(
          'Biometric authentication failed.',
        ));
      }
    } catch (e) {
      log('Error enabling biometrics: $e');
      emit(_copyCurrentStateWithError(
        'An error occurred while enabling biometric authentication: ${e.toString()}',
      ));
    }
  }

  /// Handle disabling biometric authentication
  Future<void> _onBiometricDisableRequested(
    BiometricDisableRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    try {
      await _secureStorage.write(key: 'biometric_enabled', value: 'false');
      _isBiometricEnabled = false;
      
      log('Biometric authentication disabled');
      
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(currentState.copyWith(isBiometricEnabled: false));
      } else if (state is AuthUnauthenticated) {
        final currentState = state as AuthUnauthenticated;
        emit(currentState.copyWith(isBiometricEnabled: false));
      }
    } catch (e) {
      log('Error disabling biometrics: $e');
      emit(_copyCurrentStateWithError(
        'An error occurred while disabling biometric authentication: ${e.toString()}',
      ));
    }
  }

  /// Handle profile update
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    logEvent(event);

    if (state is! AuthAuthenticated) {
      emit(AuthError(
        message: 'User not authenticated',
        canUseBiometrics: _canUseBiometrics,
        isBiometricEnabled: _isBiometricEnabled,
      ));
      return;
    }

    final currentState = state as AuthAuthenticated;
    
    emit(currentState.copyWith(isImageUploading: true));

    try {
      // Here you would call your API to update the profile
      // For now, we'll just update the local user model
      final updatedUser = UserModel(
        id: currentState.user.id,
        name: event.name,
        email: currentState.user.email,
        role: currentState.user.role,
        token: currentState.user.token,
        image: currentState.user.image,
        enrollments: currentState.user.enrollments,
        notificationTokens: currentState.user.notificationTokens,
        isSuspended: currentState.user.isSuspended,
        createdAt: currentState.user.createdAt,
        updatedAt: currentState.user.updatedAt,
        version: currentState.user.version,
      );

      // Store updated user data
      await _storeUserCredentials(updatedUser, updatedUser.email);
      
      emit(currentState.copyWith(
        user: updatedUser,
        isImageUploading: false,
      ));
    } catch (e) {
      log('Profile update error: $e');
      emit(currentState.copyWith(
        isImageUploading: false,
      ));
      emit(_copyCurrentStateWithError('Profile update failed: ${e.toString()}'));
    }
  }

  /// Handle password visibility toggle
  void _onPasswordVisibilityToggled(
    PasswordVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    logEvent(event);

    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(currentState.copyWith(isPasswordVisible: !currentState.isPasswordVisible));
    } else if (state is AuthUnauthenticated) {
      final currentState = state as AuthUnauthenticated;
      emit(currentState.copyWith(isPasswordVisible: !currentState.isPasswordVisible));
    } else if (state is AuthError) {
      final currentState = state as AuthError;
      emit(currentState.copyWith(isPasswordVisible: !currentState.isPasswordVisible));
    } else if (state is AuthLoading) {
      final currentState = state as AuthLoading;
      emit(currentState.copyWith(isPasswordVisible: !currentState.isPasswordVisible));
    }
  }

  /// Handle profile image selection
  void _onProfileImageSelected(
    ProfileImageSelected event,
    Emitter<AuthState> emit,
  ) {
    logEvent(event);

    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(currentState.copyWith(selectedProfileImage: event.image));
    } else if (state is AuthUnauthenticated) {
      final currentState = state as AuthUnauthenticated;
      emit(currentState.copyWith(selectedProfileImage: event.image));
    }
  }

  /// Handle image uploading state change
  void _onImageUploadingStateChanged(
    ImageUploadingStateChanged event,
    Emitter<AuthState> emit,
  ) {
    logEvent(event);

    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(currentState.copyWith(isImageUploading: event.isUploading));
    } else if (state is AuthUnauthenticated) {
      final currentState = state as AuthUnauthenticated;
      emit(currentState.copyWith(isImageUploading: event.isUploading));
    }
  }

  // Helper methods

  /// Store user credentials securely
  Future<void> _storeUserCredentials(UserModel user, String email) async {
    try {
      String userDataJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: 'user_data', value: userDataJson);
      await _secureStorage.write(key: 'user_token', value: user.token);
      await _secureStorage.write(key: 'user_email', value: email);
      log('User credentials stored successfully');
    } catch (e) {
      log('Error storing user credentials: $e');
      throw Exception('Failed to store user credentials');
    }
  }

  /// Load stored user data
  Future<UserModel?> _loadStoredUserData() async {
    try {
      String? userDataJson = await _secureStorage.read(key: 'user_data');
      if (userDataJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userDataJson);
        return UserModel.fromJson(userMap);
      }
    } catch (e) {
      log('Error loading stored user data: $e');
    }
    return null;
  }

  /// Get current password visibility state
  bool _getPasswordVisibility() {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).isPasswordVisible;
    } else if (state is AuthUnauthenticated) {
      return (state as AuthUnauthenticated).isPasswordVisible;
    } else if (state is AuthError) {
      return (state as AuthError).isPasswordVisible;
    } else if (state is AuthLoading) {
      return (state as AuthLoading).isPasswordVisible;
    }
    return false;
  }

  /// Get current selected image
  File? _getSelectedImage() {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).selectedProfileImage;
    } else if (state is AuthUnauthenticated) {
      return (state as AuthUnauthenticated).selectedProfileImage;
    }
    return null;
  }

  /// Copy current state with error message
  AuthState _copyCurrentStateWithError(String errorMessage) {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      return AuthError(
        message: errorMessage,
        isPasswordVisible: currentState.isPasswordVisible,
        canUseBiometrics: currentState.canUseBiometrics,
        isBiometricEnabled: currentState.isBiometricEnabled,
        isImageUploading: currentState.isImageUploading,
        selectedProfileImage: currentState.selectedProfileImage,
      );
    } else if (state is AuthUnauthenticated) {
      final currentState = state as AuthUnauthenticated;
      return AuthError(
        message: errorMessage,
        isPasswordVisible: currentState.isPasswordVisible,
        canUseBiometrics: currentState.canUseBiometrics,
        isBiometricEnabled: currentState.isBiometricEnabled,
        isImageUploading: currentState.isImageUploading,
        selectedProfileImage: currentState.selectedProfileImage,
      );
    }
    
    return AuthError(
      message: errorMessage,
      canUseBiometrics: _canUseBiometrics,
      isBiometricEnabled: _isBiometricEnabled,
    );
  }
}
