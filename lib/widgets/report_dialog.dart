import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _selectedReason = 'Inappropriate content';
  final List<String> _reportReasons = [
    'Inappropriate content',
    'Spam',
    'Harassment',
    'False information',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Post'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Why are you reporting this post?'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            items: _reportReasons.map((reason) {
              return DropdownMenuItem(
                value: reason,
                child: Text(reason),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedReason = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedReason),
          child: const Text('Report'),
        ),
      ],
    );
  }
}
