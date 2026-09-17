import '../entities/assistant_response.dart';
import '../repositories/assistant_repository.dart';

class GetAssistantAvailabilityUseCase {
  const GetAssistantAvailabilityUseCase(this.repository);

  final AssistantRepository repository;

  Future<bool> call() => repository.isAvailable();
}

class SendAssistantMessageUseCase {
  const SendAssistantMessageUseCase(this.repository);

  final AssistantRepository repository;

  Future<AssistantResponse> call({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  }) {
    return repository.sendMessage(
      message: message,
      locale: locale,
      history: history,
    );
  }
}
