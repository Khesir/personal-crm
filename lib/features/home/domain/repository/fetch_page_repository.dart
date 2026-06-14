import '../model/tool_execution_result.dart';

/// Executes the `fetch_page` agent tool, returning a URL's readable text
/// content.
abstract class FetchPageRepository {
  /// Fetches [url] and returns its readable text content as a [ToolOutput],
  /// or a [ToolError] if the request fails.
  Future<ToolExecutionResult> fetch(String url);
}
