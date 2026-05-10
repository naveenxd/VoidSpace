// lib/ui/detail/components/summary_section.dart
// Summary section with AI context generation

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:void_space/app/feature_flags.dart';
import '../../theme/void_theme.dart';
import 'package:void_space/data/models/void_item.dart';

class SummarySection extends StatelessWidget {
  final VoidItem item;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const SummarySection({
    super.key,
    required this.item,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'SUMMARY',
              style: GoogleFonts.ibmPlexMono(
                color: theme.textSecondary.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            // AI regenerate button - only visible when AI is enabled
            if (isAiEnabled)
              GestureDetector(
                onTap: onGenerate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        if (isGenerating)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.cyanAccent,
                            ),
                          )
                        else
                          const Icon(Icons.auto_awesome_rounded,
                              size: 10, color: Colors.cyanAccent),
                        const SizedBox(width: 6),
                        Text(
                          isGenerating ? 'THINKING...' : 'REFRESH',
                          style: GoogleFonts.ibmPlexMono(
                            color: Colors.cyanAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 12),
        if (item.tldr?.isNotEmpty ?? false) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'TL;DR',
                      style: GoogleFonts.ibmPlexMono(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  item.tldr ?? '',
                  style: GoogleFonts.ibmPlexSans(
                    color: theme.textPrimary.withValues(alpha: 0.95),
                    fontSize: 17,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (item.summary?.isNotEmpty ?? false)
          SelectableText(
            item.summary ?? '',
            style: GoogleFonts.ibmPlexSans(
              color: theme.textSecondary,
              fontSize: 16,
              height: 1.8,
              letterSpacing: 0.1,
            ),
          ),
      ],
    );
  }
}
