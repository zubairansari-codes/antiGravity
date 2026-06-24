/// Speech service — STT via speech_to_text, TTS via ElevenLabs.
///
/// ElevenLabs returns MP3 audio bytes which we play via just_audio.
/// STT remains device-native for zero-latency listening.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/constants/app_constants.dart';

/// Abstract interface for testability.
abstract class SpeechService {
  Future<bool> initialize();
  Future<void> startListening({
    required ValueChanged<String> onResult,
    required ValueChanged<String> onError,
  });
  Future<void> stopListening();
  Future<void> speak(String text);
  Future<void> stopSpeaking();
  bool get isListening;
  bool get isSpeaking;
}

/// Production implementation using speech_to_text + ElevenLabs.
class SpeechServiceImpl implements SpeechService {
  final stt.SpeechToText _stt;
  AudioPlayer? _player;
  final Dio _elevenlabsDio;

  bool _isListening = false;
  bool _isSpeaking = false;

  /// Silence detection timer — auto-stops STT after pause.
  Timer? _silenceTimer;
  static const _silenceTimeout = Duration(seconds: 2);

  SpeechServiceImpl({
    stt.SpeechToText? speechToText,
    AudioPlayer? audioPlayer,
    Dio? elevenlabsDio,
  })  : _stt = speechToText ?? stt.SpeechToText(),
        _player = audioPlayer,
        _elevenlabsDio = elevenlabsDio ?? _createElevenLabsDio();

  /// Create a Dio instance configured for ElevenLabs API.
  static Dio _createElevenLabsDio() {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    return Dio(BaseOptions(
      baseUrl: AppConstants.elevenLabsBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      responseType: ResponseType.bytes,
    ));
  }

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<bool> initialize() async {
    final sttAvailable = await _stt.initialize(
      onError: (error) => debugPrint('STT Error: ${error.errorMsg}'),
      onStatus: (status) => debugPrint('STT Status: $status'),
    );

    return sttAvailable;
  }

  /// Reset the silence timer — called on every new partial result.
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, () {
      // User stopped speaking — auto-stop STT to trigger finalResult.
      if (_isListening) {
        debugPrint('[AG-STT] Silence detected — auto-stopping');
        _stt.stop();
      }
    });
  }

  @override
  Future<void> startListening({
    required ValueChanged<String> onResult,
    required ValueChanged<String> onError,
  }) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }

    _isListening = true;
    String lastWords = '';
    bool resultFired = false; // Prevent double-fire on web.

    await _stt.listen(
      onResult: (result) {
        debugPrint('[AG-STT] onResult: final=${result.finalResult} words="${result.recognizedWords}"');

        if (resultFired) return; // Already fired — ignore.

        lastWords = result.recognizedWords;

        if (result.finalResult && lastWords.isNotEmpty) {
          // Final result received — cancel timer and fire.
          resultFired = true;
          _silenceTimer?.cancel();
          _isListening = false;
          onResult(lastWords);
          lastWords = '';
        } else if (lastWords.isNotEmpty) {
          // Got partial result — reset the silence timer.
          _resetSilenceTimer();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        onDevice: false,
      ),
    );

    // Fallback: when STT status changes to "done" or "notListening",
    // fire the last captured words if finalResult never came (web quirk).
    _stt.statusListener = (status) {
      debugPrint('[AG-STT] statusListener: $status, lastWords="$lastWords", fired=$resultFired');
      if (!resultFired &&
          (status == 'done' || status == 'notListening') &&
          lastWords.isNotEmpty &&
          _isListening) {
        resultFired = true;
        _silenceTimer?.cancel();
        _isListening = false;
        onResult(lastWords);
        lastWords = '';
      }
    };
  }

  @override
  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    _isListening = false;
    await _stt.stop();
  }

  @override
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _player?.stop();
    await _player?.dispose();
    _player = null;
  }

  @override
  Future<void> speak(String text) async {
    if (_isListening) {
      await stopListening();
    }

    _isSpeaking = true;
    
    // Explicitly dispose any previous player to reset the Web Audio state.
    await _player?.stop();
    await _player?.dispose();
    
    // Create a pristine, isolated player instance for this utterance.
    _player = AudioPlayer();

    try {
      // Call ElevenLabs TTS API.
      final response = await _elevenlabsDio.post(
        '/text-to-speech/${AppConstants.elevenLabsVoiceId}',
        data: {
          'text': text,
          'model_id': AppConstants.elevenLabsModelId,
          'voice_settings': {
            'stability': 0.4,        // Lower = more expressive/variable
            'similarity_boost': 0.8, // High = stays close to voice
            'style': 0.6,            // Expressiveness
            'use_speaker_boost': true,
          },
        },
      );

      // Convert response to bytes — Dio may return String on web.
      final dynamic rawData = response.data;
      final Uint8List bytes;
      if (rawData is List<int>) {
        bytes = Uint8List.fromList(rawData);
      } else if (rawData is String) {
        // On web, Dio sometimes returns bytes as a Latin-1 string.
        bytes = Uint8List.fromList(rawData.codeUnits);
      } else {
        debugPrint('[AG-TTS] Unexpected response type: ${rawData.runtimeType}');
        _isSpeaking = false;
        return;
      }

      // Use data URI approach — works on all platforms (web + native).
      final dataUri = Uri.dataFromBytes(
        bytes,
        mimeType: 'audio/mpeg',
      ).toString();
      debugPrint('[AG-TTS] bytes length: ${bytes.length}');
      final duration = await _player!.setUrl(dataUri);
      debugPrint('[AG-TTS] setUrl completed. Duration: $duration, state: ${_player!.processingState}');

      await _player!.seek(Duration.zero);
      debugPrint('[AG-TTS] seek completed. Playing...');
      await _player!.play();
      debugPrint('[AG-TTS] play() future completed. State: ${_player!.processingState}');
      
      // Clean up after playback finishes.
      await _player?.dispose();
      _player = null;
    } catch (e) {
      debugPrint('[AG-TTS] ElevenLabs TTS Error: $e');
      _isSpeaking = false;
    }
  }
}
