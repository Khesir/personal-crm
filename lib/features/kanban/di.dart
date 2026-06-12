import 'data/repository/issues_repository_impl.dart';
import 'domain/controller/issues_controller.dart';
import 'domain/repository/issues_repository.dart';

IssuesController createIssuesController() {
  final repository = IssuesRepositoryImpl();
  return IssuesController(repository);
}

IssuesRepository createIssuesRepository() {
  return IssuesRepositoryImpl();
}
