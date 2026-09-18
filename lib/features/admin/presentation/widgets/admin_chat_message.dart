import 'package:flutter/material.dart';

class AdminChatMessage extends StatelessWidget {
  final String sender;
  final String message;
  final bool isFlagged;
  
  const AdminChatMessage({
    super.key,
    required this.sender,
    required this.message,
    required this.isFlagged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$sender: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isFlagged ? Colors.red : Colors.black,
                backgroundColor: isFlagged ? Colors.red.withAlpha(20) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
