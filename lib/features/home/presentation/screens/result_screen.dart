/// Result screen — displays the final brainstorm output with copy, export, and share.
///
/// Sections: refined idea, ready-to-use prompt, 3-step action plan,
/// alternative angles, and riskiest assumption.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/brainstorm_result.dart';
import '../widgets/action_step_card.dart';
import '../widgets/alternatives_section.dart';
import '../widgets/prompt_box.dart';
import '../widgets/result_header.dart';
import '../widgets/risk_card.dart';

class ResultScreen extends StatelessWidget {
  final BrainstormResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Your Plan',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('Your Plan'),
            ],
          ),
        ),
        actions: [
          Semantics(
            label: 'Share result',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareResult,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Refined Idea ──────────────────────────────
            _CopyableSection(
              label: 'Refined Idea',
              child: ResultHeader(title: result.refinedIdea),
              onCopy: () => _copyToClipboard(result.refinedIdea, 'Refined idea'),
            ),

            const SizedBox(height: 28),

            // ── Ready-to-Use Prompt ───────────────────────
            PromptBox(prompt: result.readyPrompt),

            const SizedBox(height: 28),

            // ── Action Plan ───────────────────────────────
            if (result.actionPlan.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Do These 3 Things Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CopyButton(
                    onCopy: () => _copyToClipboard(
                      result.actionPlan
                          .map((s) => '${s.stepNumber}. ${s.title}\n${s.description}')
                          .join('\n\n'),
                      'Action plan',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...result.actionPlan
                  .map((step) => ActionStepCard(step: step)),
              const SizedBox(height: 20),
            ],

            // ── Alternative Angles ────────────────────────
            if (result.alternatives.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Alternative Angles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CopyButton(
                    onCopy: () => _copyToClipboard(
                      result.alternatives.join('\n\n'),
                      'Alternative angles',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AlternativesSection(alternatives: result.alternatives),
              const SizedBox(height: 20),
            ],

            // ── Riskiest Assumption ───────────────────────
            if (result.riskiestAssumption.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Riskiest Assumption',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CopyButton(
                    onCopy: () => _copyToClipboard(
                      result.riskiestAssumption,
                      'Riskiest assumption',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RiskCard(text: result.riskiestAssumption),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 32),

            // ── Export buttons ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _exportMarkdown,
                icon: const Icon(Icons.download_outlined),
                label: const Text(
                  'Export as Markdown',
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
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF export coming soon!')),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text(
                  'Export as PDF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Done button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    // Haptic feedback is handled by the widget, but we can also do it here.
  }

  void _shareResult() {
    final text = '''
🚀 ${result.refinedIdea}

✅ Action Plan:
${result.actionPlan.map((s) => '  ${s.stepNumber}. ${s.title}').join('\n')}

💡 Ready-to-use prompt:
${result.readyPrompt}

⚠️ Riskiest assumption:
${result.riskiestAssumption}

Generated by AntiGravity
''';
    Share.share(text);
  }

  void _exportMarkdown() {
    final markdown = '''
# 🚀 ${result.refinedIdea}

---

## 💡 Ready-to-Use Prompt

${result.readyPrompt}

---

## ✅ Action Plan

${result.actionPlan.map((s) => '### ${s.stepNumber}. ${s.title}\n\n${s.description}').join('\n\n')}

---

## 🔄 Alternative Angles

${result.alternatives.map((a) => '- $a').join('\n')}

---

## ⚠️ Riskiest Assumption

${result.riskiestAssumption}

---

_Generated by AntiGravity_
''';
    Share.share(markdown, subject: 'My AntiGravity brainstorm');
  }
}

class _CopyableSection extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onCopy;

  const _CopyableSection({
    required this.label,
    required this.child,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: _CopyButton(onCopy: onCopy),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  final VoidCallback onCopy;

  const _CopyButton({required this.onCopy});

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
        onTap: () {
          widget.onCopy();
          HapticFeedback.lightImpact();
          setState(() => _copied = true);
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
