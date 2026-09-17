import '../entities/assistant_response.dart';

abstract class AssistantRepository {
  Future<bool> isAvailable();

  Future<AssistantResponse> sendMessage({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  });
}
