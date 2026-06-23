import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

class IELTSSpeakingPage extends ConsumerStatefulWidget {
  const IELTSSpeakingPage({super.key});

  @override
  ConsumerState<IELTSSpeakingPage> createState() => _IELTSSpeakingPageState();
}

class _IELTSSpeakingPageState extends ConsumerState<IELTSSpeakingPage> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploading = false;
  String? _localPath;
  
  // Evaluation Result state
  Map<String, dynamic>? _evaluation;
  String? _errorMessage;

  // Question Cue-Card
  static const _cueCards = [
    "Describe a website you visit frequently. You should say: what website it is, how you found it, what it contains, and explain why you visit it so often.",
    "Describe a piece of technology you own that is very useful. You should say: what it is, when you got it, how you use it, and explain why it is so important to you.",
    "Describe a time you solved a difficult problem at work or school. You should say: what the problem was, how you solved it, what tools you used, and explain how you felt afterwards.",
    "Describe an environmental problem in your city or country. You should say: what it is, what causes it, how it affects people, and suggest what can be done to solve it."
  ];
  int _currentCueCardIdx = 0;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _errorMessage = null;
      _evaluation = null;
    });

    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/speaking_test_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _localPath = path;
        });
      } else {
        setState(() => _errorMessage = "Microphone permission denied.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to start recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isUploading = true;
      });

      if (path != null) {
        await _uploadAudio(path);
      } else {
        setState(() {
          _isUploading = false;
          _errorMessage = "No audio recorded.";
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isUploading = false;
        _errorMessage = "Failed to stop recording: $e";
      });
    }
  }

  Future<void> _uploadAudio(String filePath) async {
    try {
      final dio = ref.read(dioProvider);
      final file = File(filePath);
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'response.m4a',
        ),
      });

      final response = await dio.post('/ielts/speaking/submit', data: formData);
      setState(() {
        _evaluation = response.data;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = "Evaluation failed: $e. Please verify Groq API connection.";
      });
    }
  }

  void _nextCard() {
    setState(() {
      _currentCueCardIdx = (_currentCueCardIdx + 1) % _cueCards.length;
      _evaluation = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cueCardText = _cueCards[_currentCueCardIdx];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('IELTS Speaking Simulator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cue card card
            M27Card(
              borderColor: AppColors.domainIELTS.withOpacity(0.4),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SPEAKING PART 2', style: AppTypography.labelSmall.copyWith(color: AppColors.domainIELTS, letterSpacing: 1.0)),
                      TextButton(
                        onPressed: _isRecording || _isUploading ? null : _nextCard,
                        child: Row(
                          children: const [
                            Text('Next Card', style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                            SizedBox(width: 4),
                            Icon(Icons.navigate_next_rounded, size: 16, color: AppColors.primaryLight),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(cueCardText, style: AppTypography.titleMedium.copyWith(height: 1.5)),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 28),

            // Active State UI
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
              ).animate().shake(),

            if (_isUploading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.domainIELTS),
                      const SizedBox(height: 16),
                      Text('Transcribing speech & analyzing grammar...', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else if (_evaluation != null)
              _EvaluationResult(evaluation: _evaluation!).animate().fadeIn(duration: 500.ms)
            else
              // Recorder button
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isRecording)
                              Container(
                                width: 90, height: 90,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withOpacity(0.15)),
                              ).animate(onPlay: (c) => c.repeat()).scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.4, 1.4)).fadeOut(),
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: _isRecording ? AppColors.error : AppColors.domainIELTS,
                              child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 36),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording ? 'TAP TO COMPLETE TEST' : 'TAP MICROPHONE TO RESPOND (SPEAK FOR 1-2 MINS)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _isRecording ? AppColors.error : AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationResult extends StatelessWidget {
  final Map<String, dynamic> evaluation;
  const _EvaluationResult({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final band = (evaluation['band_estimate'] as num?)?.toDouble() ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score Header
        M27Card(
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(color: AppColors.domainIELTS, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    band.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Band Score', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text('IELTS Examiner Review', style: AppTypography.titleMedium),
                    Text('+20 XP Earned', style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Transcript
        Text('Speech Transcript', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        M27Card(
          padding: const EdgeInsets.all(14),
          child: Text(
            '"${evaluation['transcript'] ?? ''}"',
            style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),

        // Review Details
        Text('Feedback Breakdown', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        _FeedbackBlock(title: 'Fluency & Coherence', feedback: evaluation['fluency_feedback'] ?? '', icon: Icons.speed_outlined),
        _FeedbackBlock(title: 'Lexical Resource (Vocabulary)', feedback: evaluation['lexical_feedback'] ?? '', icon: Icons.text_snippet_outlined),
        _FeedbackBlock(title: 'Grammar & Accuracy', feedback: evaluation['grammar_feedback'] ?? '', icon: Icons.g_translate_outlined),
        _FeedbackBlock(title: 'Coherence & Structure', feedback: evaluation['coherence_feedback'] ?? '', icon: Icons.account_tree_outlined),
      ],
    );
  }
}

class _FeedbackBlock extends StatelessWidget {
  final String title;
  final String feedback;
  final IconData icon;

  const _FeedbackBlock({required this.title, required this.feedback, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.domainIELTS),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            feedback,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
