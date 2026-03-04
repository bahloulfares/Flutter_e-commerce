import 'package:atelier7/data/repositories/user.repository.dart';

class AuthenticateUserUseCase {
  final UserRepository _repository;

  AuthenticateUserUseCase({required UserRepository repository})
      : _repository = repository;

  Future<bool> call(String email, String password) {
    return _repository.authenticate(email, password);
  }

  Future<bool> register(String name, String email, String password) async {
    return _repository.registerUser(name, email, password);
  }
}
