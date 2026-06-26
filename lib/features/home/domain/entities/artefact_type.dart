/// Output formats the AI can produce at the end of a session.
library;

enum ArtefactType {
  ideaOnePager('ideaOnePager', 'Idea one-pager'),
  actionPlan('actionPlan', 'Action plan'),
  script('script', 'Script / dialogue'),
  pitchThread('pitchThread', 'Pitch thread'),
  visualConcept('visualConcept', 'Visual concept'),
  debateMap('debateMap', 'Debate map'),
  rawNotes('rawNotes', 'Raw notes');

  const ArtefactType(this.id, this.label);

  final String id;
  final String label;

  static ArtefactType fromId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => ArtefactType.rawNotes,
    );
  }
}
