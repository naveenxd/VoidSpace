// lib/ui/detail/components/edit_item_form.dart
// Editable title and content fields

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:void_space/ui/theme/void_design.dart';
import 'package:void_space/ui/theme/void_theme.dart';

class EditItemForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isNoteType;

  const EditItemForm({
    super.key,
    required this.titleController,
    required this.contentController,
    this.isNoteType = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    return Column(
      children: [
        _buildEditableTitle(theme),
        if (isNoteType) ...[
          const SizedBox(height: VoidDesign.space2XL),
          _buildEditableContent(theme),
        ],
      ],
    );
  }

  Widget _buildEditableTitle(VoidTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TITLE',
          style: GoogleFonts.ibmPlexMono(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: titleController,
          style: GoogleFonts.ibmPlexSans(
            color: theme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Enter title...',
            hintStyle: GoogleFonts.ibmPlexSans(
              color: theme.textSecondary,
              fontSize: 28,
            ),
            filled: true,
            fillColor: theme.textPrimary.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.3)),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableContent(VoidTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTENT',
          style: GoogleFonts.ibmPlexMono(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: contentController,
          style: GoogleFonts.ibmPlexSans(
            color: theme.textPrimary.withValues(alpha: 0.9),
            fontSize: 16,
            height: 1.8,
            letterSpacing: 0.1,
          ),
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Enter content...',
            hintStyle: GoogleFonts.ibmPlexMono(
              color: theme.textSecondary,
              fontSize: 16,
            ),
            filled: true,
            fillColor: theme.textPrimary.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.textPrimary.withValues(alpha: 0.3)),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }
}
