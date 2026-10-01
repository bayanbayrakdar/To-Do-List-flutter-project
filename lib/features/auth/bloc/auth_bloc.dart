import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  // Is someone already logged in when the app starts?
  void _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) {
    final user = _repository.currentUser;
    emit(user == null ? Unauthenticated() : Authenticated(user.uid));
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(event.email, event.password);
      emit(Authenticated(user.uid));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(Unauthenticated());
    }
  }

  Future<void> _onRegister(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(event.email, event.password);
      emit(Authenticated(user.uid));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(Unauthenticated());
  }
}
