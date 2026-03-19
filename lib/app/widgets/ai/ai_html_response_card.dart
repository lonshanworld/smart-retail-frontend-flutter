import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AiHtmlResponseCard extends StatelessWidget {
  const AiHtmlResponseCard({
    super.key,
    required this.html,
    required this.fallbackText,
  });

  final String html;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHtml = html.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: hasHtml
          ? Html(
              data: html,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(15),
                  color: theme.colorScheme.onSurface,
                  lineHeight: const LineHeight(1.45),
                ),
                'h1': Style(
                  margin: Margins.only(bottom: 12),
                  color: theme.colorScheme.onSurface,
                ),
                'h2': Style(
                  margin: Margins.only(bottom: 10),
                  color: theme.colorScheme.onSurface,
                ),
                'h3': Style(
                  margin: Margins.only(bottom: 8),
                  color: theme.colorScheme.onSurface,
                ),
                'table': Style(
                  width: Width(100),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                'th': Style(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  padding: HtmlPaddings.all(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                'td': Style(
                  padding: HtmlPaddings.all(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                '.kpi': Style(
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  padding: HtmlPaddings.all(12),
                  margin: Margins.only(bottom: 10),
                ),
                '.ai-report-panel': Style(
                  backgroundColor: theme.colorScheme.surface,
                  padding: HtmlPaddings.all(4),
                ),
                '.ai-auto-insights': Style(
                  margin: Margins.only(top: 14),
                  padding: HtmlPaddings.all(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                ),
                '.ai-chart': Style(margin: Margins.only(top: 10, bottom: 10)),
                '.ai-chart-row': Style(margin: Margins.only(bottom: 8)),
                '.ai-chart-label': Style(
                  fontSize: FontSize(12),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                '.ai-chart-value': Style(
                  fontSize: FontSize(12),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                '.ai-chart-track': Style(
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  height: Height(10),
                ),
                '.ai-chart-fill': Style(
                  backgroundColor: theme.colorScheme.primary,
                  height: Height(10),
                ),
              },
            )
          : Text(fallbackText, style: theme.textTheme.bodyMedium),
    );
  }
}
