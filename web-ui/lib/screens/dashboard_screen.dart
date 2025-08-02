import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/user.dart';
import '../widgets/satellite_card.dart';
import '../widgets/command_history_list.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/edit_user_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    print('DashboardScreen initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('About to call loadDashboardData');
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barnaby Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/chat');
            },
            tooltip: 'Chat View',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text(authProvider.currentUser?.username ?? 'User'),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => authProvider.logout(),
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${dashboardProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dashboardProvider.loadDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(dashboardProvider),
                const SizedBox(height: 24),
                _buildSatellitesSection(dashboardProvider),
                const SizedBox(height: 24),
                _buildUsersSection(dashboardProvider),
                const SizedBox(height: 24),
                _buildCommandHistorySection(dashboardProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(DashboardProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.devices, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.onlineSatellites}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Online Satellites'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.devices_other, size: 32, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.offlineSatellites}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Offline Satellites'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.history, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.commandHistory.length}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Recent Commands'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSatellitesSection(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Satellites',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (provider.satellites.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No satellites found'),
            ),
          )
        else
          ...provider.satellites.map((satellite) => SatelliteCard(satellite: satellite)),
      ],
    );
  }

  Widget _buildUsersSection(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(provider),
              icon: const Icon(Icons.add),
              label: const Text('Add User'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.users.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No users found'),
            ),
          )
        else
          Card(
            child: Column(
              children: provider.users.map((user) => ListTile(
                leading: Icon(
                  user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                  color: user.role == 'admin' ? Colors.orange : Colors.blue,
                ),
                title: Text(user.username),
                subtitle: Text('Role: ${user.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Created: ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditUserDialog(provider, user),
                      tooltip: 'Edit User',
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommandHistorySection(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Commands',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        CommandHistoryList(commands: provider.commandHistory),
      ],
    );
  }

  void _showAddUserDialog(DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onAddUser: (username, password, role) async {
          await provider.addUser(username, password, role);
        },
      ),
    );
  }

  void _showEditUserDialog(DashboardProvider provider, User user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onEditUser: (userId, username, password, role) async {
          await provider.editUser(userId, username, password, role);
        },
      ),
    );
  }
}