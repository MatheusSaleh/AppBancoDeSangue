import '../../domain/models/donation.dart';
import '../../domain/models/donor_profile.dart';
import '../../domain/models/news_article.dart';

/// Error with a message that can be shown to the user (pt-BR).
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AppUser {
  const AppUser({required this.id, this.email, this.isGuest = false});

  final String id;
  final String? email;
  final bool isGuest;
}

abstract interface class AuthRepository {
  /// Emits the current user immediately and on every change.
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  /// Whether this backend supports e-mail/password accounts.
  bool get supportsEmailPassword;

  /// Whether a local guest session (demo mode) is available.
  bool get supportsGuest;

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> sendPasswordReset(String email);

  /// Sets a new password using the code received by e-mail.
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });
  Future<void> signInAsGuest();
  Future<void> signOut();
}

abstract interface class DonationRepository {
  /// Donations of [userId], most recent first.
  Future<List<Donation>> fetchAll(String userId);
  Future<Donation> add(String userId, Donation donation);
  Future<void> update(String userId, Donation donation);
  Future<void> delete(String userId, String donationId);
}

abstract interface class ProfileRepository {
  Future<DonorProfile> fetch(String userId);
  Future<void> save(String userId, DonorProfile profile);
}

abstract interface class NewsRepository {
  /// True when articles are bundled sample content rather than real news.
  bool get isDemoContent;
  Future<List<NewsArticle>> fetchAll();
}
