import '../../domain/model/tool_execution_result.dart';
import '../../domain/repository/fetch_page_repository.dart';
import '../datasource/page_fetch_datasource.dart';

class FetchPageRepositoryImpl implements FetchPageRepository {
  final PageFetchDatasource _datasource;

  FetchPageRepositoryImpl(this._datasource);

  @override
  Future<ToolExecutionResult> fetch(String url) async {
    String text;
    try {
      text = await _datasource.fetchText(url);
    } catch (_) {
      return const ToolError('Failed to fetch the page.');
    }

    if (text.trim().isEmpty) {
      return ToolOutput('No readable content found at $url.');
    }
    return ToolOutput(text);
  }
}
