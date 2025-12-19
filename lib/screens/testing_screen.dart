import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/services/image_generation_service.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  final TextEditingController _playersController = TextEditingController(text: '3');
  bool _loading = false;
  bool _loadingImage = false;

  static const String _qaSample = """
What's your favourite drink? Mai Tai
Where do you want to go on holiday next? Japan
What's your favourite cartoon? Futurama
Where did you grow up? Scotland
What was your first pet? A Goldfish
""";

  // Editable controller for Questions & Answers box
  final TextEditingController _qaController = TextEditingController(text: _qaSample.trim());

  @override
  void dispose() {
    _playersController.dispose();
    _qaController.dispose();
    super.dispose();
  }

  Future<void> _runTest() async {
    final theme = Theme.of(context);
    final int? count = int.tryParse(_playersController.text.trim());
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid number of players (> 0)')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in first.');
      }
      // Refresh token; Functions SDK includes it
      await user.getIdToken(true);

      debugPrint('TestingScreen calling generatePlayerQuestions (callable) for $count players');
      final callable = FirebaseFunctions.instance.httpsCallable('generatePlayerQuestions');
      final resp = await callable.call({'numberOfPlayers': count}).timeout(const Duration(seconds: 30));

      final data = Map<String, dynamic>.from(resp.data as Map);
      if (data['success'] != true) {
        throw Exception('Function reported failure');
      }

      final List<dynamic> questions = (data['questions'] as List<dynamic>?) ?? <dynamic>[];
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Questions (${questions.length})', style: theme.textTheme.titleLarge),
            content: SizedBox(
              width: 480,
              child: questions.isEmpty
                  ? Text('No questions returned', style: theme.textTheme.bodyLarge)
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final q = Map<String, dynamic>.from(questions[index] as Map);
                          final text = (q['text'] ?? '').toString();
                          final difficulty = (q['difficulty'] ?? '').toString();
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.help_outline, size: 18, color: theme.colorScheme.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(text, style: theme.textTheme.bodyLarge),
                                    if (difficulty.isNotEmpty)
                                      Text(difficulty, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.tertiary)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('TestingScreen error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch questions: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runImageGeneration() async {
    final theme = Theme.of(context);
    setState(() => _loadingImage = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please sign in first.');
      final email = user.email ?? '';
      if (email.isEmpty) throw Exception('Signed-in user has no email.');

      final qa = (_qaController.text.trim().isEmpty) ? _qaSample.trim() : _qaController.text.trim();

      final imageUrl = await ImageGenerationService.generateCharacterPortrait(
        email: email,
        questionsAndAnswers: qa,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Generated Image', style: theme.textTheme.titleLarge),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                SelectableText(imageUrl, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.tertiary)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('TestingScreen image generation error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate image: $e')));
    } finally {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Testing'),
          bottom: TabBar(
            labelColor: theme.colorScheme.secondary,
            unselectedLabelColor: theme.colorScheme.secondary,
            tabs: const [
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Questions'),
              Tab(icon: Icon(Icons.image_outlined), text: 'Image'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Questions tab
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Number of players', style: theme.textTheme.titleMedium),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _playersController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 4'),
                        onSubmitted: (_) => _runTest(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _runTest,
                          icon: _loading
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))
                              : const Icon(Icons.play_arrow),
                          label: Text(_loading ? 'Testing…' : 'Test'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Image tab
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Generate Character Portrait', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final email = FirebaseAuth.instance.currentUser?.email ?? '—';
                          return Text('Signed-in email: $email', style: theme.textTheme.bodyMedium);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Questions & Answers (editable)', style: theme.textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qaController,
                        minLines: 6,
                        maxLines: 12,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Enter 6 questions and answers, one per line',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadingImage ? null : _runImageGeneration,
                        icon: _loadingImage
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))
                            : const Icon(Icons.auto_awesome),
                        label: Text(_loadingImage ? 'Generating…' : 'Generate Image'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}