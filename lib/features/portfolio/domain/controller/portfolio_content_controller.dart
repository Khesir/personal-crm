import 'package:crm/core/state/state.dart';
import 'package:crm/features/portfolio/data/datasource/portfolio_datasource.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_blog.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_config.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_experience.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_post.dart';
import 'package:crm/features/portfolio/domain/entities/portfolio_project.dart';
import 'package:crm/features/portfolio/domain/repository/portfolio_repository.dart';

class PortfolioHomeConfigController extends StreamState<AsyncState<PortfolioHomeConfig>> {
  final PortfolioDatasource _ds;
  PortfolioHomeConfigController(this._ds) : super(const AsyncLoading());
  Future<void> load() => execute(_ds.fetchHomeConfig);
}

class PortfolioAboutConfigController extends StreamState<AsyncState<PortfolioAboutConfig>> {
  final PortfolioDatasource _ds;
  PortfolioAboutConfigController(this._ds) : super(const AsyncLoading());
  Future<void> load() => execute(_ds.fetchAboutConfig);
}

class PortfolioServicesConfigController extends StreamState<AsyncState<PortfolioServicesConfig>> {
  final PortfolioDatasource _ds;
  PortfolioServicesConfigController(this._ds) : super(const AsyncLoading());
  Future<void> load() => execute(_ds.fetchServicesConfig);
}

class PortfolioBlogController extends StreamState<AsyncState<List<PortfolioBlog>>> {
  final PortfolioRepository _repo;
  PortfolioBlogController(this._repo) : super(const AsyncLoading());

  Future<void> load() => execute(_repo.fetchBlogs);

  Future<void> delete(String id) async {
    await _repo.deleteBlog(id);
    final cur = data;
    if (cur != null) emit(AsyncData(cur.where((b) => b.id != id).toList()));
  }

  Future<void> toggleDraft(String id, bool draft) async {
    await _repo.toggleBlogDraft(id, draft);
    await load();
  }
}

class PortfolioProjectController extends StreamState<AsyncState<List<PortfolioProject>>> {
  final PortfolioRepository _repo;
  PortfolioProjectController(this._repo) : super(const AsyncLoading());

  Future<void> load() => execute(_repo.fetchProjects);

  Future<void> delete(String id) async {
    await _repo.deleteProject(id);
    final cur = data;
    if (cur != null) emit(AsyncData(cur.where((p) => p.id != id).toList()));
  }

  Future<void> toggleDraft(String id, bool draft) async {
    await _repo.toggleProjectDraft(id, draft);
    await load();
  }

  Future<void> togglePinned(String id, bool pinned) async {
    await _repo.toggleProjectPinned(id, pinned);
    await load();
  }
}

class PortfolioExperienceController extends StreamState<AsyncState<List<PortfolioExperience>>> {
  final PortfolioRepository _repo;
  PortfolioExperienceController(this._repo) : super(const AsyncLoading());

  Future<void> load() => execute(_repo.fetchExperiences);

  Future<void> delete(String id) async {
    await _repo.deleteExperience(id);
    final cur = data;
    if (cur != null) emit(AsyncData(cur.where((e) => e.id != id).toList()));
  }

  Future<void> toggleDraft(String id, bool draft) async {
    await _repo.toggleExperienceDraft(id, draft);
    await load();
  }
}

class PortfolioPostController extends StreamState<AsyncState<List<PortfolioPost>>> {
  final PortfolioRepository _repo;
  PortfolioPostController(this._repo) : super(const AsyncLoading());

  Future<void> load() => execute(_repo.fetchPosts);

  Future<void> delete(String id) async {
    await _repo.deletePost(id);
    final cur = data;
    if (cur != null) emit(AsyncData(cur.where((p) => p.id != id).toList()));
  }

  Future<void> toggleDraft(String id, bool draft) async {
    await _repo.togglePostDraft(id, draft);
    await load();
  }

  Future<void> togglePinned(String id, bool pinned) async {
    await _repo.togglePostPinned(id, pinned);
    await load();
  }
}
