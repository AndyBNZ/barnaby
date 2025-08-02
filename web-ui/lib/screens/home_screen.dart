import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAdminView = false;

  @override
  void initState() {
    super.initState();
    // Initialize chat welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).addWelcomeMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAdmin = authProvider.currentUser?.role == 'admin';
        
        // Regular users always see chat
        if (!isAdmin) {
          return const ChatScreen();
        }
        
        // Admin can switch between views
        return _showAdminView ? _buildAdminView() : _buildChatView();
      },
    );
  }

  Widget _buildAdminView() {
    return Scaffold(
      body: const DashboardScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAdminView = false),
        tooltip: 'Switch to Chat',
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildChatView() {
    return const ChatScreen();
  }
}