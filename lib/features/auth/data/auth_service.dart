import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_model.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  // Stream untuk memantau perubahan status autentikasi secara real-time
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Mendapatkan data user yang sedang login saat ini (Supabase Auth User)
  User? get currentUser => _supabase.auth.currentUser;

  // Registrasi pengguna baru dengan email, password, username, dan nama lengkap
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
      },
    );
  }

  // Login menggunakan email & password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout dari aplikasi
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Mengambil profil publik pengguna dari tabel 'profiles'
  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Memperbarui informasi profil pengguna
  Future<ProfileModel> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? currency,
  }) async {
    final updates = {
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (currency != null) 'currency': currency,
    };

    final response = await _supabase
        .from('profiles')
        .upsert(updates)
        .select()
        .single();
    
    return ProfileModel.fromJson(response);
  }
}
