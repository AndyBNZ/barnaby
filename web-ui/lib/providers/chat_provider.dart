import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.assistant(
        "Hello! I'm Barnaby, your voice assistant. How can I help you today?",
      ));
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    print('ChatProvider.sendMessage called with: $text');
    
    // Add user message
    final userMessage = ChatMessage.user(text);
    _messages.add(userMessage);
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      print('About to call _processMessage');
      final response = await _processMessage(text);
      
      final assistantMessage = ChatMessage.assistant(
        response['text'],
        intent: response['intent'],
        confidence: response['confidence'],
      );
      
      _messages.add(assistantMessage);
    } catch (e) {
      final errorMessage = ChatMessage.assistant(
        "I'm sorry, I encountered an error processing your request. Please try again.",
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _processMessage(String text) async {
    try {
      print('Sending to backend: text:$text');
      // Call the actual backend API
      final response = await _apiService.processVoiceCommand('text:$text');
      print('Backend response: ${response.response}');
      return {
        'text': response.response,
        'intent': response.intent,
        'confidence': 0.95,
      };
    } catch (e) {
      print('Backend error: $e');
      print('Error type: ${e.runtimeType}');
      // Don't fallback - show the actual error
      return {
        'text': 'Backend error: $e',
        'intent': 'error',
        'confidence': 0.1,
      };
    }
  }

  void clearMessages() {
    _messages.clear();
    addWelcomeMessage();
    notifyListeners();
  }
}