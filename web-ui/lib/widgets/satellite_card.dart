import 'package:flutter/material.dart';
import '../models/satellite.dart';

class SatelliteCard extends StatelessWidget {
  final Satellite satellite;

  const SatelliteCard({super.key, required this.satellite});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: satellite.isOnline ? Colors.green : Colors.red,
          child: Icon(
            satellite.isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
          ),
        ),
        title: Text(satellite.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${satellite.status}'),
            if (satellite.lastSeen != null)
              Text('Last seen: ${_formatDateTime(satellite.lastSeen!)}'),
            if (satellite.ipAddress != null)
              Text('IP: ${satellite.ipAddress}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restart',
              child: Row(
                children: [
                  Icon(Icons.restart_alt),
                  SizedBox(width: 8),
                  Text('Restart'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'configure',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Configure'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'restart':
                _showRestartDialog(context);
                break;
              case 'configure':
                _showConfigureDialog(context);
                break;
            }
          },
        ),
      ),
    );
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

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Satellite'),
        content: Text('Are you sure you want to restart ${satellite.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Restart command sent to ${satellite.name}')),
              );
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showConfigureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Satellite'),
        content: Text('Configuration for ${satellite.name} is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}