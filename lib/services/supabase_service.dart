import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Database methods
  Future<List<Map<String, dynamic>>> getData(String table) async {
    final response = await _client
        .from(table)
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> insertData(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.from(table).insert(data).select().single();
    return response;
  }

  Future<Map<String, dynamic>> updateData(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _client.from(table).update(data).eq('id', id).select().single();
    return response;
  }

  Future<void> deleteData(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
