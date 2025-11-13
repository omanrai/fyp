import 'dart:io';
import '../../../core/bloc/base_event.dart';

abstract class AuthEvent extends BaseEvent {
  const AuthEvent();
}

/// Event to login user with email and password
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event to login user with biometrics
class BiometricLoginRequested extends AuthEvent {
  const BiometricLoginRequested();
}

/// Event to register a new user
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? imagePath;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.imagePath,
  });

  @override
  List<Object?> get props => [email, password, name, role, imagePath];
}

/// Event to logout user
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event to check if user is already logged in (auto-login)
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// Event to enable biometric authentication
class BiometricEnableRequested extends AuthEvent {
  const BiometricEnableRequested();
}

/// Event to disable biometric authentication
class BiometricDisableRequested extends AuthEvent {
  const BiometricDisableRequested();
}

/// Event to update user profile
class ProfileUpdateRequested extends AuthEvent {
  final String name;
  final String? imagePath;

  const ProfileUpdateRequested({
    required this.name,
    this.imagePath,
  });

  @override
  List<Object?> get props => [name, imagePath];
}

/// Event to toggle password visibility
class PasswordVisibilityToggled extends AuthEvent {
  const PasswordVisibilityToggled();
}

/// Event to update profile image
class ProfileImageSelected extends AuthEvent {
  final File? image;

  const ProfileImageSelected(this.image);

  @override
  List<Object?> get props => [image];
}

/// Event to set image uploading state
class ImageUploadingStateChanged extends AuthEvent {
  final bool isUploading;

  const ImageUploadingStateChanged(this.isUploading);

  @override
  List<Object?> get props => [isUploading];
}
