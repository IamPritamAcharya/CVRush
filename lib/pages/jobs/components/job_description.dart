import 'package:flutter/material.dart';
import 'package:horz/markdown_renderer.dart';

class JobDescription extends StatelessWidget {
  final String description;
  const JobDescription({Key? key, required this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: CustomMarkdown(markdownText: description),
    );
  }
}
