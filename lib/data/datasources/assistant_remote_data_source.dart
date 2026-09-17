import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/assistant_response.dart';
import '../models/assistant_response_model.dart';

abstract class AssistantRemoteDataSource {
  Future<bool> isAvailable();

  Future<AssistantResponseModel> sendMessage({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  });
}

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  const AssistantRemoteDataSourceImpl(this.client);

  final DioClient client;

  @override
  Future<bool> isAvailable() async {
    final response = await client.get(ApiConstants.assistantAvailability);
    return response.data is Map && response.data['enabled'] == true;
  }

  @override
  Future<AssistantResponseModel> sendMessage({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  }) async {
    final boundedHistory = history.length <= 12
        ? history
        : history.sublist(history.length - 12);
    final response = await client.post(
      ApiConstants.assistantMessages,
      data: {
        'message': message,
        'locale': locale,
        'history': boundedHistory
            .map((item) => {'role': item.role, 'content': item.content})
            .toList(),
      },
    );
    return AssistantResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}
