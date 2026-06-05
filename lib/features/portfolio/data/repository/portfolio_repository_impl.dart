import 'package:crm/features/portfolio/data/datasource/portfolio_datasource.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_blog.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_experience.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_post.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_project.dart';
import 'package:crm/features/portfolio/domain/repository/portfolio_repository.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioDatasource _ds;
  PortfolioRepositoryImpl(this._ds);

  @override Future<List<PortfolioBlog>> fetchBlogs() => _ds.fetchBlogs();
  @override Future<void> deleteBlog(String id) => _ds.deleteBlog(id);
  @override Future<void> toggleBlogDraft(String id, bool draft) => _ds.toggleBlogDraft(id, draft);

  @override Future<List<PortfolioProject>> fetchProjects() => _ds.fetchProjects();
  @override Future<void> deleteProject(String id) => _ds.deleteProject(id);
  @override Future<void> toggleProjectDraft(String id, bool draft) => _ds.toggleProjectDraft(id, draft);
  @override Future<void> toggleProjectPinned(String id, bool pinned) => _ds.toggleProjectPinned(id, pinned);

  @override Future<List<PortfolioExperience>> fetchExperiences() => _ds.fetchExperiences();
  @override Future<void> deleteExperience(String id) => _ds.deleteExperience(id);
  @override Future<void> toggleExperienceDraft(String id, bool draft) => _ds.toggleExperienceDraft(id, draft);

  @override Future<List<PortfolioPost>> fetchPosts() => _ds.fetchPosts();
  @override Future<void> deletePost(String id) => _ds.deletePost(id);
  @override Future<void> togglePostDraft(String id, bool draft) => _ds.togglePostDraft(id, draft);
  @override Future<void> togglePostPinned(String id, bool pinned) => _ds.togglePostPinned(id, pinned);

  @override Future<bool> verifyAuth() => _ds.verifyAuth();
}
