/// Output formats the AI can produce at the end of a session.
library;

import 'package:flutter/material.dart';

enum ArtefactType {
  ideaOnePager('ideaOnePager', 'Idea one-pager', Icons.lightbulb_outline),
  actionPlan('actionPlan', 'Action plan', Icons.format_list_numbered),
  script('script', 'Script / dialogue', Icons.chat_bubble_outline),
  pitchThread('pitchThread', 'Pitch thread', Icons.campaign_outlined),
  visualConcept('visualConcept', 'Visual concept', Icons.image_outlined),
  debateMap('debateMap', 'Debate map', Icons.account_tree_outlined),
  rawNotes('rawNotes', 'Raw notes', Icons.notes);

  const ArtefactType(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static ArtefactType fromId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => ArtefactType.rawNotes,
    );
  }
}
