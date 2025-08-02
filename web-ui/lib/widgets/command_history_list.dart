import 'package:flutter/material.dart';
import '../models/command.dart';

class CommandHistoryList extends StatelessWidget {
  final List<CommandHistory> commands;

  const CommandHistoryList({super.key, required this.commands});

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No commands found'),
        ),
      );
    }

    return Card(
      child: Column(
        children: commands.map((command) => _buildCommandTile(command)).toList(),
      ),
    );
  }

  Widget _buildCommandTile(CommandHistory command) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getConfidenceColor(command.confidence),
        child: Text(
          command.confidence != null 
              ? '${(command.confidence! * 100).round()}%'
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(command.commandText),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (command.intent != null)
            Text('Intent: ${command.intent}'),
          if (command.response != null)
            Text('Response: ${command.response}'),
          Row(
            children: [
              Text(_formatDateTime(command.createdAt)),
              if (command.processingTimeMs != null) ...[
                const SizedBox(width: 16),
                Text('${command.processingTimeMs}ms'),
              ],
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showCommandDetails(command),
      ),
    );
  }

  Color _getConfidenceColor(double? confidence) {
    if (confidence == null) return Colors.grey;
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showCommandDetails(CommandHistory command) {
    // This would show a dialog with full command details
    // Implementation depends on the context where this widget is used
  }
}