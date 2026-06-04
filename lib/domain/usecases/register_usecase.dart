import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> call({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) {
    return _repository.register(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}
