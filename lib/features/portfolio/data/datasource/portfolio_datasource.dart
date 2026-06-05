import 'package:dio/dio.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_blog.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_config.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_experience.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_post.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_project.dart';

class PortfolioDatasource {
  final Dio _dio;

  PortfolioDatasource(this._dio);

  Future<List<PortfolioBlog>> fetchBlogs() async {
    final res = await _dio.get('blogs/cms');
    return (res.data as List).map((e) => PortfolioBlog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteBlog(String id) => _dio.delete('blogs/$id');
  Future<void> toggleBlogDraft(String id, bool draft) => _dio.put('blogs/$id', data: {'draft': draft});

  Future<List<PortfolioProject>> fetchProjects() async {
    final res = await _dio.get('projects/cms');
    return (res.data as List).map((e) => PortfolioProject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteProject(String id) => _dio.delete('projects/$id');
  Future<void> toggleProjectDraft(String id, bool draft) => _dio.put('projects/$id', data: {'draft': draft});
  Future<void> toggleProjectPinned(String id, bool pinned) => _dio.put('projects/$id', data: {'pinned': pinned});

  Future<List<PortfolioExperience>> fetchExperiences() async {
    final res = await _dio.get('experiences/cms');
    return (res.data as List).map((e) => PortfolioExperience.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteExperience(String id) => _dio.delete('experiences/$id');
  Future<void> toggleExperienceDraft(String id, bool draft) => _dio.put('experiences/$id', data: {'draft': draft});

  Future<List<PortfolioPost>> fetchPosts() async {
    final res = await _dio.get('posts/cms');
    return (res.data as List).map((e) => PortfolioPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deletePost(String id) => _dio.delete('posts/$id');
  Future<void> togglePostDraft(String id, bool draft) => _dio.put('posts/$id', data: {'draft': draft});
  Future<void> togglePostPinned(String id, bool pinned) => _dio.put('posts/$id', data: {'pinned': pinned});

  Future<PortfolioHomeConfig> fetchHomeConfig() async {
    final res = await _dio.get('config/home');
    return PortfolioHomeConfig.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PortfolioAboutConfig> fetchAboutConfig() async {
    final res = await _dio.get('config/about');
    return PortfolioAboutConfig.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PortfolioServicesConfig> fetchServicesConfig() async {
    final res = await _dio.get('config/services');
    return PortfolioServicesConfig.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> verifyAuth() async {
    try {
      await _dio.get('auth/login');
      return true;
    } on DioException {
      return false;
    }
  }
}
