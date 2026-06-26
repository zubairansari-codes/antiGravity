/// ElevenLabs voice personas used by the speech service.
///
/// Each persona bundles the voice ID with the settings that shape
/// expressiveness and stability. New voices can be added here without
/// touching the TTS implementation.
library;

/// A selectable TTS voice persona.
class VoicePersona {
  const VoicePersona({
    required this.id,
    required this.label,
    this.stability = 0.4,
    this.similarityBoost = 0.8,
    this.style = 0.6,
    this.useSpeakerBoost = true,
  });

  /// ElevenLabs voice ID.
  final String id;

  /// Human-readable label shown in settings.
  final String label;

  /// Lower = more expressive/variable.
  final double stability;

  /// Higher = stays closer to the voice sample.
  final double similarityBoost;

  /// Expressiveness / style intensity.
  final double style;

  /// ElevenLabs speaker boost flag.
  final bool useSpeakerBoost;
}

/// Predefined voice personas.
abstract final class VoicePersonas {
  static const VoicePersona rachel = VoicePersona(
    id: '21m00Tcm4TlvDq8ikWAM',
    label: 'Rachel — warm & natural',
    stability: 0.4,
    similarityBoost: 0.8,
    style: 0.6,
    useSpeakerBoost: true,
  );

  static const VoicePersona adam = VoicePersona(
    id: 'pNInz6obpgDQGcFmaJgB',
    label: 'Adam — steady & grounded',
    stability: 0.45,
    similarityBoost: 0.8,
    style: 0.45,
    useSpeakerBoost: true,
  );

  static const VoicePersona bella = VoicePersona(
    id: 'EXAVITQu4vr4xnSDxMaL',
    label: 'Bella — energetic & playful',
    stability: 0.35,
    similarityBoost: 0.75,
    style: 0.75,
    useSpeakerBoost: true,
  );

  static const VoicePersona antoni = VoicePersona(
    id: 'ErXwobaYiN019PkySvjV',
    label: 'Antoni — curious & thoughtful',
    stability: 0.4,
    similarityBoost: 0.8,
    style: 0.55,
    useSpeakerBoost: true,
  );

  /// All personas in the order they appear in settings.
  static const List<VoicePersona> all = [rachel, adam, bella, antoni];

  /// Look up a persona by ElevenLabs voice ID.
  static VoicePersona fromId(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => rachel,
    );
  }
}
