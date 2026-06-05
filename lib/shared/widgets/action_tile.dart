import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.icon,
    required this.onTap,
    required this.subtitle,
    required this.title,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
