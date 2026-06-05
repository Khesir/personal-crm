import 'package:dio/dio.dart';
import '../../presentation/state/support_state.dart';

const _base = '/api/v1/support';

class SupportDatasource {
  final Dio _dio;
  SupportDatasource(this._dio);

  Future<List<SupportTicket>> fetchAll({String? status}) async {
    final res = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: status != null ? {'status': status} : null,
    );
    return (res.data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(SupportTicket.fromJson)
        .toList();
  }

  Future<void> updateTicket(String id, {String? status, String? adminNote}) async {
    await _dio.patch('$_base/$id', data: {
      if (status != null) 'status': status,
      if (adminNote != null) 'adminNote': adminNote,
    });
  }

  Future<void> deleteTicket(String id) async {
    await _dio.delete('$_base/$id');
  }
}
