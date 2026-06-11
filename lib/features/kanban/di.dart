import 'data/repository/issues_repository_impl.dart';
import 'domain/controller/issues_controller.dart';

IssuesController createIssuesController() {
  final repository = IssuesRepositoryImpl();
  return IssuesController(repository);
}
