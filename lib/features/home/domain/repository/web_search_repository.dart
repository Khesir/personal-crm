import '../model/tool_execution_result.dart';

/// Executes the `web_search` agent tool against a configured search engine.
abstract class WebSearchRepository {
  /// Searches for [query] and returns up to [count] results formatted as a
  /// [ToolOutput], or a [ToolError] if the search request fails.
  Future<ToolExecutionResult> search(String query, {int? count});
}
