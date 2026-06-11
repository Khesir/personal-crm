import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/home/presentation/widget/code_block.dart';

class MarkdownIssueBody extends StatelessWidget {
  final String content;

  const MarkdownIssueBody({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      builders: {'pre': _CodeBlockBuilder()},
      styleSheet: MarkdownStyleSheet(
        p: AppStyling.bodyLg,
        code: AppStyling.monoSm.copyWith(
          backgroundColor: AppColors.surfaceRaised,
        ),
        h1: AppStyling.headingLg,
        h2: AppStyling.headingMd,
        h3: AppStyling.headingMd,
        listBullet: AppStyling.bodyLg,
        a: AppStyling.bodyLg.copyWith(color: AppColors.accentLight),
        strong: AppStyling.bodyLg.copyWith(fontWeight: FontWeight.w700),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          border: const Border(
            left: BorderSide(color: AppColors.accent, width: 3),
          ),
        ),
      ),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final codeElement = element.children?.whereType<md.Element>().firstOrNull;
    final classes = codeElement?.attributes['class'] ?? '';
    final language = classes.startsWith('language-')
        ? classes.substring('language-'.length)
        : null;
    final code = element.textContent.trimRight();
    return CodeBlock(code: code, language: language);
  }
}

extension on Iterable<md.Element> {
  md.Element? get firstOrNull => isEmpty ? null : first;
}
