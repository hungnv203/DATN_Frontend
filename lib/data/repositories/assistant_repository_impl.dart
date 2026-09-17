import '../../domain/entities/assistant_response.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_remote_data_source.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  const AssistantRepositoryImpl(this.remoteDataSource);

  final AssistantRemoteDataSource remoteDataSource;

  @override
  Future<bool> isAvailable() => remoteDataSource.isAvailable();

  @override
  Future<AssistantResponse> sendMessage({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  }) {
    return remoteDataSource.sendMessage(
      message: message,
      locale: locale,
      history: history,
    );
  }
}
