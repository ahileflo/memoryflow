import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/models/import_job.dart';
import '../../data/providers.dart';

/// The AI "organizing your memories" screen.
///
/// • Mock mode: a self-contained animation sweeps 0→100% over ~2.8s.
/// • Backend mode: polls the real import job (Edge Function) and reflects live
///   progress — processed / total photos — then advances Home.
class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen>
    with SingleTickerProviderStateMixin {
  static const _stages = [
    'Removing duplicates & blurry shots',
    'Detecting faces, pets & places',
    'Grouping into events & trips',
    'Picking your best shots',
    'Designing gift ideas',
  ];
  static const _titles = [
    'Removing duplicates…',
    'Detecting faces…',
    'Grouping events…',
    'Picking best shots…',
    'Designing gifts…',
  ];

  // mock animation
  AnimationController? _controller;
  bool _navigated = false;

  // backend polling
  String? _jobId;
  Timer? _poll;
  ImportJob? _job;
  String? _error;
  bool _organizing = false;

  @override
  void initState() {
    super.initState();
    _jobId = ref.read(currentImportJobIdProvider);
    if (AppConfig.backendEnabled && _jobId != null) {
      _startPolling();
    } else {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_navigated) {
          _navigated = true;
          Future.delayed(const Duration(milliseconds: 850), _goHome);
        }
      })
      ..forward();
  }

  void _startPolling() {
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
    _tick();
  }

  Future<void> _tick() async {
    final id = _jobId;
    if (id == null) return;
    try {
      final job = await ref.read(repositoryProvider).getImportJob(id);
      if (!mounted) return;
      setState(() => _job = job);
      if (job.isDone && !_navigated) {
        _navigated = true;
        _poll?.cancel();
        // Import done → run the AI organization pipeline, then go Home with
        // freshly organized albums.
        setState(() => _organizing = true);
        try {
          final repo = ref.read(repositoryProvider);
          // 'ai' uses Claude when ANTHROPIC_API_KEY is set on the functions,
          // and auto-falls-back to heuristic otherwise.
          await repo.organize(mode: 'ai');
          // Then generate gift suggestions from the freshly built albums.
          await repo.generateSuggestions(mode: 'ai');
        } catch (_) {
          // Organization/suggestions are best-effort; proceed to Home regardless.
        }
        if (!mounted) return;
        ref.invalidate(albumsProvider);
        ref.invalidate(suggestionsProvider);
        ref.invalidate(profileProvider);
        Future.delayed(const Duration(milliseconds: 500), _goHome);
      } else if (job.isError) {
        _poll?.cancel();
        setState(() => _error = job.message ?? 'Import failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      _poll?.cancel();
    }
  }

  void _goHome() {
    ref.read(currentImportJobIdProvider.notifier).state = null;
    if (mounted) context.go(Routes.home);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poll?.cancel();
    super.dispose();
  }

  String _withCommas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final backend = AppConfig.backendEnabled && _jobId != null;

    // Progress + labels come from either the live job or the animation.
    final double p;
    final String countLine;
    if (backend) {
      final job = _job;
      p = job?.progress ?? 0;
      final processed = job?.processed ?? 0;
      final total = job?.total ?? 0;
      countLine = total == 0
          ? 'Starting import…'
          : 'Imported ${_withCommas(processed)} of ${_withCommas(total)} photos'
              '${(job?.duplicates ?? 0) > 0 ? ' · ${job!.duplicates} duplicates skipped' : ''}';
    } else {
      p = _controller?.value ?? 0;
      final processed = (p * AppConfig.demoLibraryPhotoCount).round();
      countLine =
          'Processed ${_withCommas(processed)} of ${_withCommas(AppConfig.demoLibraryPhotoCount)} photos';
    }

    // While organizing, peg the ring at 100% and show the organize message.
    final organizing = _organizing && _error == null;
    final pEffective = organizing ? 1.0 : p;
    final pct = (pEffective * 100).round();
    final done = !organizing && pEffective >= 1.0 && (!backend || (_job?.isDone ?? false));
    final allDone = done || organizing;
    final stage = math.min(4, (pEffective * 5).floor());
    final title = _error != null
        ? 'Something went wrong'
        : organizing
            ? 'Organizing your memories ✨'
            : (done ? 'Your memories are ready ✨' : _titles[stage]);
    final displayLine =
        _error ?? (organizing ? 'Grouping events & picking your best shots…' : countLine);

    return Scaffold(
      backgroundColor: BrandColors.indigo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: _RingPainter(progress: pEffective),
                    child: Center(
                      child: Text('$pct%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  displayLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _error != null ? BrandColors.coral : const Color(0xFFBDB8DC),
                      fontSize: 14),
                ),
                const SizedBox(height: 26),
                if (_error != null)
                  TextButton(
                    onPressed: _goHome,
                    child: const Text('Continue anyway',
                        style: TextStyle(color: BrandColors.amber)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(
                      children: [
                        for (var i = 0; i < _stages.length; i++)
                          _ScanLine(
                            index: i,
                            label: _stages[i],
                            state: allDone || i < stage
                                ? _LineState.done
                                : (i == stage ? _LineState.active : _LineState.pending),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _LineState { pending, active, done }

class _ScanLine extends StatelessWidget {
  const _ScanLine({required this.index, required this.label, required this.state});
  final int index;
  final String label;
  final _LineState state;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    switch (state) {
      case _LineState.pending:
        textColor = const Color(0x66D9D5EE);
      case _LineState.active:
        textColor = BrandColors.amber;
      case _LineState.done:
        textColor = Colors.white;
    }
    final isDone = state == _LineState.done;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? BrandColors.mint : Colors.white.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(isDone ? '✓' : '${index + 1}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: state == _LineState.active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = BrandColors.coral;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
