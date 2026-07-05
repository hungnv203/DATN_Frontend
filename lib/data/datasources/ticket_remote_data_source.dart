import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getMyTickets();
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final DioClient client;

  TicketRemoteDataSourceImpl(this.client);

  @override
  Future<List<TicketModel>> getMyTickets() async {
    try {
      final response = await client.get(ApiConstants.myTickets);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => TicketModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load tickets');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
