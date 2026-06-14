import '../../domain/model/tool_execution_result.dart';
import '../../domain/repository/web_search_repository.dart';
import '../datasource/searxng_datasource.dart';

const kDefaultWebSearchResultCount = 5;

class WebSearchRepositoryImpl implements WebSearchRepository {
  final SearxngDatasource _datasource;

  WebSearchRepositoryImpl(this._datasource);

  @override
  Future<ToolExecutionResult> search(String query, {int? count}) async {
    final limit = count ?? kDefaultWebSearchResultCount;
    List<Map<String, dynamic>> results;
    try {
      results = await _datasource.search(query);
    } catch (_) {
      return const ToolError('Web search request failed.');
    }

    if (results.isEmpty) {
      return const ToolOutput('No results found.');
    }

    final text = results
        .take(limit)
        .map((result) {
          final title = result['title'] as String? ?? '';
          final url = result['url'] as String? ?? '';
          final snippet = result['content'] as String? ?? '';
          return '$title\n$url\n$snippet';
        })
        .join('\n\n');
    return ToolOutput(text);
  }
}
