import 'package:dio/dio.dart';
import '../../domain/model/bug_report.dart';

class BugReportsDatasource {
  final Dio _dio;
  final String _projectKey;

  BugReportsDatasource(this._dio, this._projectKey);

  String get _basePath => '/api/v1/projects/$_projectKey/bug-reports';

  Future<List<BugReport>> fetchBugReports() async {
    final response = await _dio.get<List<dynamic>>(_basePath);
    return (response.data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(BugReport.fromJson)
        .toList();
  }

  Future<void> updateBugReport(String id, {required bool resolved}) async {
    await _dio.patch('$_basePath/$id', data: {'resolved': resolved});
  }

  Future<void> deleteBugReport(String id) async {
    await _dio.delete('$_basePath/$id');
  }
}
