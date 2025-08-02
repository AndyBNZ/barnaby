import 'package:flutter/foundation.dart';
import '../models/satellite.dart';
import '../models/command.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Satellite> _satellites = [];
  List<CommandHistory> _commandHistory = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<Satellite> get satellites => _satellites;
  List<CommandHistory> get commandHistory => _commandHistory;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get onlineSatellites => _satellites.where((s) => s.isOnline).length;
  int get offlineSatellites => _satellites.where((s) => s.isOffline).length;

  Future<void> loadDashboardData() async {
    print('=== loadDashboardData() called ===');
    _setLoading(true);
    _error = null;

    try {
      print('Loading satellites...');
      await _loadSatellites();
      print('Loading command history...');
      await _loadCommandHistory();
      print('Loading users...');
      await _loadUsers();
      print('All data loaded successfully');
    } catch (e) {
      print('Error in loadDashboardData: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadSatellites() async {
    try {
      _satellites = await _apiService.getSatellites();
    } catch (e) {
      // Satellites endpoint might not exist yet, use mock data
      _satellites = [
        Satellite(
          id: 'sat-001',
          name: 'Kitchen Assistant',
          status: 'online',
          lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Satellite(
          id: 'sat-002',
          name: 'Living Room Assistant',
          status: 'offline',
          lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    }
  }

  Future<void> _loadCommandHistory() async {
    try {
      _commandHistory = await _apiService.getCommandHistory();
    } catch (e) {
      // Command history might be empty, use mock data
      _commandHistory = [
        CommandHistory(
          id: 'cmd-001',
          commandText: 'What time is it?',
          intent: 'get_time',
          response: 'The current time is 10:30 AM',
          confidence: 0.95,
          processingTimeMs: 150,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        CommandHistory(
          id: 'cmd-002',
          commandText: 'Turn on the lights',
          intent: 'control_lights',
          response: 'Light control is not yet implemented',
          confidence: 0.88,
          processingTimeMs: 200,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    try {
      _users = await _apiService.getUsers();
      notifyListeners(); // Notify after loading users
    } catch (e) {
      _users = [];
      notifyListeners(); // Notify even on error
    }
  }

  Future<void> addUser(String username, String password, String role) async {
    try {
      final newUser = await _apiService.createUser(username, password, role);
      _users.add(newUser);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add user: $e');
    }
  }

  Future<void> editUser(String userId, String username, String? password, String role) async {
    try {
      final updatedUser = await _apiService.updateUser(userId, username, password, role);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}