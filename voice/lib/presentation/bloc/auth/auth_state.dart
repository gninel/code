import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

enum SyncStatus {
  idle,
  uploading,
  downloading,
  success,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? error;
  final SyncStatus syncStatus;
  final String? syncMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.syncStatus = SyncStatus.idle,
    this.syncMessage,
  });

  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    SyncStatus? syncStatus,
    String? syncMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: syncMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, error, syncStatus, syncMessage];
}
