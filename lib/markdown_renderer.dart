import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomMarkdown extends StatelessWidget {
  final String markdownText;
  final double width;

  const CustomMarkdown(
      {super.key, required this.markdownText, this.width = 600});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: MarkdownBody(data: markdownText),
    );
  }
}
