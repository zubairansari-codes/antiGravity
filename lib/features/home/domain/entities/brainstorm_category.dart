import 'package:flutter/material.dart';

enum BrainstormCategory {
  general(
    id: 'general',
    label: 'General Idea',
    icon: Icons.lightbulb_outline_rounded,
    description: 'Explore and invert any broad concept or idea.',
  ),
  coding(
    id: 'coding',
    label: 'Coding & Arch',
    icon: Icons.code_rounded,
    description: 'System design, edge cases, and tech stack choices.',
  ),
  marketing(
    id: 'marketing',
    label: 'Marketing & Growth',
    icon: Icons.trending_up_rounded,
    description: 'Viral hooks, target audience, and distribution channels.',
  ),
  business(
    id: 'business',
    label: 'Startup Strategy',
    icon: Icons.business_center_rounded,
    description: 'Unit economics, moats, and go-to-market plans.',
  ),
  writing(
    id: 'writing',
    label: 'Creative Writing',
    icon: Icons.edit_document,
    description: 'Narrative arcs, audience engagement, and unique angles.',
  ),
  design(
    id: 'design',
    label: 'Design & UX',
    icon: Icons.design_services_rounded,
    description: 'User journeys, friction points, and aesthetics.',
  ),
  personal(
    id: 'personal',
    label: 'Personal Goals',
    icon: Icons.self_improvement_rounded,
    description: 'Habits, root causes, and actionable routines.',
  );

  const BrainstormCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String id;
  final String label;
  final IconData icon;
  final String description;

  static BrainstormCategory fromId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => BrainstormCategory.general,
    );
  }
}
