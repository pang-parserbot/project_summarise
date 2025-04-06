class RecentPath {
  final String path;
  final DateTime accessTime;
  final bool isFavorite;

  const RecentPath({
    required this.path,
    required this.accessTime,
    this.isFavorite = false,
  });

  RecentPath copyWith({
    String? path,
    DateTime? accessTime,
    bool? isFavorite,
  }) {
    return RecentPath(
      path: path ?? this.path,
      accessTime: accessTime ?? this.accessTime,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'accessTime': accessTime.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory RecentPath.fromJson(Map<String, dynamic> json) {
    return RecentPath(
      path: json['path'],
      accessTime: DateTime.parse(json['accessTime']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}