import 'package:path/path.dart' as path;

enum DownloadStatus {
  queued,
  resolving,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}

extension DownloadStatusInfo on DownloadStatus {
  bool get isActive =>
      this == DownloadStatus.resolving || this == DownloadStatus.downloading;

  bool get isFinished =>
      this == DownloadStatus.completed ||
      this == DownloadStatus.failed ||
      this == DownloadStatus.canceled;
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.cid,
    required this.fileName,
    required this.destinationDirectory,
    required this.createdAt,
    this.ipfsPath = '',
    this.status = DownloadStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes,
    this.speedBytesPerSecond = 0,
    this.completedAt,
    this.error,
    this.gateway,
    this.retryCount = 0,
    this.isDirectoryArchive = false,
    this.fileNameIsProvisional = false,
  });

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? DownloadStatus.queued.name;
    final status = DownloadStatus.values.where(
      (candidate) => candidate.name == statusName,
    );
    final restoredStatus = status.isEmpty
        ? DownloadStatus.queued
        : status.first;
    final ipfsPath = json['ipfsPath'] as String? ?? '';
    final fileName = _requiredString(json, 'fileName');
    final isDirectoryArchive = json['isDirectoryArchive'] as bool? ?? false;
    final sourceFileName = ipfsPath.isEmpty ? '' : ipfsPath.split('/').last;
    final legacyProvisionalName =
        restoredStatus != DownloadStatus.completed &&
        !isDirectoryArchive &&
        ((ipfsPath.isEmpty &&
                path.extension(fileName).toLowerCase() == '.bin') ||
            (ipfsPath.isNotEmpty &&
                path.extension(sourceFileName).isEmpty &&
                path.extension(fileName).isEmpty));

    return DownloadTask(
      id: _requiredString(json, 'id'),
      cid: _requiredString(json, 'cid'),
      ipfsPath: ipfsPath,
      fileName: fileName,
      destinationDirectory: _requiredString(json, 'destinationDirectory'),
      status: restoredStatus,
      receivedBytes: _intValue(json['receivedBytes']) ?? 0,
      totalBytes: _intValue(json['totalBytes']),
      speedBytesPerSecond:
          (json['speedBytesPerSecond'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
      completedAt: switch (json['completedAt']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      error: json['error'] as String?,
      gateway: json['gateway'] as String?,
      retryCount: _intValue(json['retryCount']) ?? 0,
      isDirectoryArchive: isDirectoryArchive,
      fileNameIsProvisional:
          json['fileNameIsProvisional'] as bool? ?? legacyProvisionalName,
    );
  }

  final String id;
  final String cid;
  final String ipfsPath;
  final String fileName;
  final String destinationDirectory;
  final DownloadStatus status;
  final int receivedBytes;
  final int? totalBytes;
  final double speedBytesPerSecond;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? error;
  final String? gateway;
  final int retryCount;
  final bool isDirectoryArchive;
  final bool fileNameIsProvisional;

  String get finalPath => path.join(destinationDirectory, fileName);

  String get partialPath => '$finalPath.part';

  String get canonicalSource =>
      '/ipfs/$cid${ipfsPath.isEmpty ? '' : '/$ipfsPath'}';

  double? get progress {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0, 1).toDouble();
  }

  Duration? get estimatedTimeRemaining {
    final total = totalBytes;
    if (total == null || speedBytesPerSecond <= 0) return null;
    final remaining = total - receivedBytes;
    if (remaining <= 0) return Duration.zero;
    return Duration(seconds: (remaining / speedBytesPerSecond).ceil());
  }

  DownloadTask copyWith({
    String? id,
    String? cid,
    String? ipfsPath,
    String? fileName,
    String? destinationDirectory,
    DownloadStatus? status,
    int? receivedBytes,
    Object? totalBytes = _unset,
    double? speedBytesPerSecond,
    DateTime? createdAt,
    Object? completedAt = _unset,
    Object? error = _unset,
    Object? gateway = _unset,
    int? retryCount,
    bool? isDirectoryArchive,
    bool? fileNameIsProvisional,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      cid: cid ?? this.cid,
      ipfsPath: ipfsPath ?? this.ipfsPath,
      fileName: fileName ?? this.fileName,
      destinationDirectory: destinationDirectory ?? this.destinationDirectory,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: identical(totalBytes, _unset)
          ? this.totalBytes
          : totalBytes as int?,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      createdAt: createdAt ?? this.createdAt,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      error: identical(error, _unset) ? this.error : error as String?,
      gateway: identical(gateway, _unset) ? this.gateway : gateway as String?,
      retryCount: retryCount ?? this.retryCount,
      isDirectoryArchive: isDirectoryArchive ?? this.isDirectoryArchive,
      fileNameIsProvisional:
          fileNameIsProvisional ?? this.fileNameIsProvisional,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'cid': cid,
    'ipfsPath': ipfsPath,
    'fileName': fileName,
    'destinationDirectory': destinationDirectory,
    'status': status.name,
    'receivedBytes': receivedBytes,
    'totalBytes': totalBytes,
    'speedBytesPerSecond': speedBytesPerSecond,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'error': error,
    'gateway': gateway,
    'retryCount': retryCount,
    'isDirectoryArchive': isDirectoryArchive,
    'fileNameIsProvisional': fileNameIsProvisional,
  };
}

const Object _unset = Object();

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Ungültiges oder fehlendes Feld: $key');
}

int? _intValue(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  _ => null,
};
