import 'dart:io';
import '../../../core/bloc/base_state.dart';
import '../../model/auth/user_model.dart';

abstract class AuthState extends BaseState {
  const AuthState();
}

/// Initial authentication state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final bool isPasswordVisible;
  final bool isBiometricEnabled;
  final bool canUseBiometrics;
  final bool isImageUploading;
  final File? selectedProfileImage;

  const AuthAuthenticated({
    required this.user,
    this.isPasswordVisible = false,
    this.isBiometricEnabled = false,
    this.canUseBiometrics = false,
    this.isImageUploading = false,
    this.selectedProfileImage,
  });

  AuthAuthenticated copyWith({
    UserModel? user,
    bool? isPasswordVisible,
    bool? isBiometricEnabled,
    bool? canUseBiometrics,
    bool? isImageUploading,
    File? selectedProfileImage,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      selectedProfileImage: selectedProfileImage ?? this.selectedProfileImage,
    );
  }

  @override
  List<Object?> get props => [
        user,
        isPasswordVisible,
        isBiometricEnabled,
        canUseBiometrics,
        isImageUploading,
        selectedProfileImage,
      ];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  final bool isPasswordVisible;
  final bool canUseBiometrics;
  final bool isBiometricEnabled;
  final bool isImageUploading;
  final File? selectedProfileImage;

  const AuthUnauthenticated({
    this.isPasswordVisible = false,
    this.canUseBiometrics = false,
    this.isBiometricEnabled = false,
    this.isImageUploading = false,
    this.selectedProfileImage,
  });

  AuthUnauthenticated copyWith({
    bool? isPasswordVisible,
    bool? canUseBiometrics,
    bool? isBiometricEnabled,
    bool? isImageUploading,
    File? selectedProfileImage,
  }) {
    return AuthUnauthenticated(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      selectedProfileImage: selectedProfileImage ?? this.selectedProfileImage,
    );
  }

  @override
  List<Object?> get props => [
        isPasswordVisible,
        canUseBiometrics,
        isBiometricEnabled,
        isImageUploading,
        selectedProfileImage,
      ];
}

/// Loading state for authentication operations
class AuthLoading extends AuthState {
  final String? loadingMessage;
  final bool isPasswordVisible;
  final bool canUseBiometrics;
  final bool isBiometricEnabled;
  final bool isImageUploading;
  final File? selectedProfileImage;

  const AuthLoading({
    this.loadingMessage,
    this.isPasswordVisible = false,
    this.canUseBiometrics = false,
    this.isBiometricEnabled = false,
    this.isImageUploading = false,
    this.selectedProfileImage,
  });

  AuthLoading copyWith({
    String? loadingMessage,
    bool? isPasswordVisible,
    bool? canUseBiometrics,
    bool? isBiometricEnabled,
    bool? isImageUploading,
    File? selectedProfileImage,
  }) {
    return AuthLoading(
      loadingMessage: loadingMessage ?? this.loadingMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      selectedProfileImage: selectedProfileImage ?? this.selectedProfileImage,
    );
  }

  @override
  List<Object?> get props => [
        loadingMessage,
        isPasswordVisible,
        canUseBiometrics,
        isBiometricEnabled,
        isImageUploading,
        selectedProfileImage,
      ];
}

/// Error state for authentication operations
class AuthError extends AuthState {
  final String message;
  final String? errorCode;
  final bool isPasswordVisible;
  final bool canUseBiometrics;
  final bool isBiometricEnabled;
  final bool isImageUploading;
  final File? selectedProfileImage;

  const AuthError({
    required this.message,
    this.errorCode,
    this.isPasswordVisible = false,
    this.canUseBiometrics = false,
    this.isBiometricEnabled = false,
    this.isImageUploading = false,
    this.selectedProfileImage,
  });

  AuthError copyWith({
    String? message,
    String? errorCode,
    bool? isPasswordVisible,
    bool? canUseBiometrics,
    bool? isBiometricEnabled,
    bool? isImageUploading,
    File? selectedProfileImage,
  }) {
    return AuthError(
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      selectedProfileImage: selectedProfileImage ?? this.selectedProfileImage,
    );
  }

  @override
  List<Object?> get props => [
        message,
        errorCode,
        isPasswordVisible,
        canUseBiometrics,
        isBiometricEnabled,
        isImageUploading,
        selectedProfileImage,
      ];
}

/// Biometric setup successful
class AuthBiometricEnabled extends AuthState {
  final UserModel? user;
  final bool isPasswordVisible;
  final bool canUseBiometrics;
  final bool isBiometricEnabled;
  final bool isImageUploading;
  final File? selectedProfileImage;

  const AuthBiometricEnabled({
    this.user,
    this.isPasswordVisible = false,
    this.canUseBiometrics = false,
    this.isBiometricEnabled = true,
    this.isImageUploading = false,
    this.selectedProfileImage,
  });

  @override
  List<Object?> get props => [
        user,
        isPasswordVisible,
        canUseBiometrics,
        isBiometricEnabled,
        isImageUploading,
        selectedProfileImage,
      ];
}
