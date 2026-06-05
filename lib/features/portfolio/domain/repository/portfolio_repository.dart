import 'package:crm/features/portfolio/domain/entities/portfolio_blog.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_experience.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_post.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_project.dart';

abstract class PortfolioRepository {
  Future<List<PortfolioBlog>> fetchBlogs();
  Future<void> deleteBlog(String id);
  Future<void> toggleBlogDraft(String id, bool draft);

  Future<List<PortfolioProject>> fetchProjects();
  Future<void> deleteProject(String id);
  Future<void> toggleProjectDraft(String id, bool draft);
  Future<void> toggleProjectPinned(String id, bool pinned);

  Future<List<PortfolioExperience>> fetchExperiences();
  Future<void> deleteExperience(String id);
  Future<void> toggleExperienceDraft(String id, bool draft);

  Future<List<PortfolioPost>> fetchPosts();
  Future<void> deletePost(String id);
  Future<void> togglePostDraft(String id, bool draft);
  Future<void> togglePostPinned(String id, bool pinned);

  Future<bool> verifyAuth();
}
