import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';

class ClipboardBanner extends StatelessWidget {
  final String detectedText;
  final VoidCallback onConvert;
  final VoidCallback onDismiss;

  const ClipboardBanner({
    super.key,
    required this.detectedText,
    required this.onConvert,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.content_paste, color: Colors.blue[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '检测到视频链接',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _truncateUrl(detectedText),
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onConvert,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[900],
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('转换', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: Colors.blue[400]),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateUrl(String text) {
    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(text);
    final url = urlMatch?.group(0) ?? text;
    if (url.length > 50) return '${url.substring(0, 50)}...';
    return url;
  }
}
