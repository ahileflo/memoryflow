/// Progress of a photo-import run. The scanning screen polls this in backend
/// mode to show live import progress; the Edge Function writes it.
class ImportJob {
  const ImportJob({
    required this.id,
    required this.status,
    required this.total,
    required this.processed,
    this.duplicates = 0,
    this.message,
  });

  final String id;

  /// queued | running | done | error
  final String status;
  final int total;
  final int processed;
  final int duplicates;
  final String? message;

  bool get isDone => status == 'done';
  bool get isError => status == 'error';

  double get progress => total <= 0 ? 0 : (processed / total).clamp(0.0, 1.0);

  factory ImportJob.fromMap(Map<String, dynamic> m) => ImportJob(
        id: m['id'] as String,
        status: (m['status'] as String?) ?? 'running',
        total: (m['total'] as int?) ?? 0,
        processed: (m['processed'] as int?) ?? 0,
        duplicates: (m['duplicates'] as int?) ?? 0,
        message: m['message'] as String?,
      );
}
