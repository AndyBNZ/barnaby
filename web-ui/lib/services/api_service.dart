import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/satellite.dart';
import '../models/command.dart';

class ApiService {
  static const String baseUrl = 'http://0.0.0.0:3000/api';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Authentication
  Future<LoginResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode(LoginRequest(username: username, password: password).toJson()),
    );

    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      setToken(loginResponse.token);
      return loginResponse;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    _token = null;
  }

  // Users
  Future<List<User>> getUsers() async {
    print('=== getUsers() called ===');
    print('Getting users with headers: $_headers');
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
    );

    print('Users response status: ${response.statusCode}');
    print('Users response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Raw users data: ${data['users']}');
      try {
        final users = (data['users'] as List)
            .map((json) {
              print('Parsing user: $json');
              return User.fromJson(json);
            })
            .toList();
        print('Parsed ${users.length} users successfully');
        return users;
      } catch (e) {
        print('Error parsing users: $e');
        throw Exception('Failed to parse users: $e');
      }
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  Future<User> createUser(String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<User> updateUser(String userId, String username, String? password, String role) async {
    final body = {'username': username, 'role': role};
    if (password != null) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<User> getUser(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  // Satellites
  Future<List<Satellite>> getSatellites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/satellites'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['satellites'] as List)
          .map((json) => Satellite.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load satellites: ${response.body}');
    }
  }

  // Commands
  Future<List<CommandHistory>> getCommandHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/commands/history'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['commands'] as List)
          .map((json) => CommandHistory.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load command history: ${response.body}');
    }
  }

  Future<ProcessVoiceResponse> processVoiceCommand(String audioData, {String? satelliteId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/commands/process'),
      headers: _headers,
      body: jsonEncode(ProcessVoiceRequest(
        audioData: audioData,
        satelliteId: satelliteId,
      ).toJson()),
    );

    if (response.statusCode == 200) {
      return ProcessVoiceResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to process voice command: ${response.body}');
    }
  }
}
