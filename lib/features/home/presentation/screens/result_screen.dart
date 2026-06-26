/// Result screen — displays final session artefacts with copy, share, and export.
///
/// Renders a gallery of [ConversationArtefact] cards. Legacy [BrainstormResult]
/// data is folded into a single artefact so the UI is uniform.
library;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/artefact_type.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_result.dart';
import '../../domain/entities/conversation_artefact.dart';

class ResultScreen extends StatelessWidget {

  const ResultScreen({super.key, required this.brainstorm});
  final Brainstorm brainstorm;

  List<ConversationArtefact> get _artefacts => brainstorm.artefacts.isNotEmpty
      ? brainstorm.artefacts
      : (brainstorm.result != null
          ? [_legacyResultToArtefact(brainstorm.result!)]
          : const []);

  static ConversationArtefact _legacyResultToArtefact(BrainstormResult result) {
    final buffer = StringBuffer()
      ..writeln('## Refined idea\n')
      ..writeln(result.refinedIdea)
      ..writeln('\n## Ready-to-use prompt\n')
      ..writeln(result.readyPrompt)
      ..writeln('\n## Action plan\n')
      ..writeAll(
        result.actionPlan.map(
          (s) => '${s.stepNumber}. ${s.title}${s.description.isNotEmpty ? ' — ${s.description}' : ''}',
        ),
        '\n',
      );
    if (result.riskiestAssumption.isNotEmpty) {
      buffer
        ..writeln('\n\n## Riskiest assumption\n')
        ..writeln(result.riskiestAssumption);
    }
    return ConversationArtefact(
      artefactType: ArtefactType.ideaOnePager,
      title: result.refinedIdea.isNotEmpty
          ? result.refinedIdea
          : 'Your brainstorm',
      content: buffer.toString(),
      followUpQuestions: result.alternatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artefacts = _artefacts;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Your Artefacts',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text('Your Artefacts'),
            ],
          ),
        ),
        actions: [
          Semantics(
            label: 'Share all artefacts',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareAll,
              tooltip: 'Share',
            ),
          ),
          Semantics(
            label: 'Export as Markdown',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: _exportMarkdown,
              tooltip: 'Export Markdown',
            ),
          ),
        ],
      ),
      body: artefacts.isEmpty
          ? _EmptyResult(
              onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...artefacts.indexed.expand((entry) {
                    final index = entry.$1;
                    final artefact = entry.$2;
                    return [
                      if (index == 0) const SizedBox(height: 8),
                      _ArtefactCard(artefact: artefact),
                      const SizedBox(height: 16),
                    ];
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        'Keep Riffing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _artefactMarkdown(ConversationArtefact artefact) {
    final buffer = StringBuffer()
      ..writeln('# ${artefact.title}')
      ..writeln()
      ..writeln('_${artefact.artefactType.label}_')
      ..writeln()
      ..writeln(artefact.content);
    if (artefact.followUpQuestions.isNotEmpty) {
      buffer
        ..writeln('\n## Follow-up questions')
        ..writeAll(
          artefact.followUpQuestions.map((q) => '- $q'),
          '\n',
        );
    }
    return buffer.toString();
  }

  void _shareAll() {
    final text = _artefacts
        .map(_artefactMarkdown)
        .join('\n\n---\n\n');
    Share.share(text, subject: brainstorm.title);
  }

  void _exportMarkdown() {
    final markdown = '''# ${brainstorm.title}

${brainstorm.result != null ? _legacyMarkdown(brainstorm.result!) : _artefacts.map(_artefactMarkdown).join('\n\n---\n\n')}

---

_Generated by AntiGravity_
''';
    Share.share(markdown, subject: brainstorm.title);
  }

  String _legacyMarkdown(BrainstormResult result) {
    return '''# ${result.refinedIdea}

## Ready-to-Use Prompt

${result.readyPrompt}

## Action Plan

${result.actionPlan.map((s) => '### ${s.stepNumber}. ${s.title}\n\n${s.description}').join('\n\n')}

## Alternative Angles

${result.alternatives.map((a) => '- $a').join('\n')}

## Riskiest Assumption

${result.riskiestAssumption}
''';
  }
}

class _ArtefactCard extends StatelessWidget {

  const _ArtefactCard({required this.artefact});
  final ConversationArtefact artefact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${artefact.artefactType.label}: ${artefact.title}',
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.surfaceVariant.withOpacity(0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      artefact.artefactType.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _CopyButton(
                    onCopy: () => Clipboard.setData(
                      ClipboardData(text: artefact.content),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                artefact.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artefact.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              if (artefact.followUpQuestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Keep riffing on:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: artefact.followUpQuestions.map((question) {
                    return Chip(
                      label: Text(question),
                      backgroundColor:
                          AppColors.primary.withOpacity(0.08),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {

  const _CopyButton({required this.onCopy});
  final Future<void> Function() onCopy;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Copy to clipboard',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await widget.onCopy();
          HapticFeedback.lightImpact();
          if (mounted) setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _copied
                ? AppColors.success.withOpacity(0.15)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check : Icons.copy_outlined,
                size: 14,
                color: _copied ? AppColors.success : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _copied ? 'Copied!' : 'Copy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _copied
                      ? AppColors.success
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {

  const _EmptyResult({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome,
              size: 48, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text(
            'No artefacts yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep riffing — a tangible output will appear here when you wrap up.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }
}
