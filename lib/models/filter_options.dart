class FilterOptions {
  final List<String> includedExtensions; // 如果为空，表示包含所有
  final List<String> excludedExtensions;
  final List<String> excludedFolders;
  final String? searchText;
  final bool showHiddenFiles;
  final bool caseSensitive;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final int? minSize; // 以字节为单位
  final int? maxSize; // 以字节为单位

  const FilterOptions({
    this.includedExtensions = const [],
    this.excludedExtensions = const [],
    this.excludedFolders = const [],
    this.searchText,
    this.showHiddenFiles = false,
    this.caseSensitive = false,
    this.modifiedAfter,
    this.modifiedBefore,
    this.minSize,
    this.maxSize,
  });

  FilterOptions copyWith({
    List<String>? includedExtensions,
    List<String>? excludedExtensions,
    List<String>? excludedFolders,
    String? searchText,
    bool? showHiddenFiles,
    bool? caseSensitive,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    int? minSize,
    int? maxSize,
    bool clearSearchText = false,
    bool clearModifiedAfter = false,
    bool clearModifiedBefore = false,
    bool clearMinSize = false,
    bool clearMaxSize = false,
  }) {
    return FilterOptions(
      includedExtensions: includedExtensions ?? this.includedExtensions,
      excludedExtensions: excludedExtensions ?? this.excludedExtensions,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      modifiedAfter: clearModifiedAfter ? null : (modifiedAfter ?? this.modifiedAfter),
      modifiedBefore: clearModifiedBefore ? null : (modifiedBefore ?? this.modifiedBefore),
      minSize: clearMinSize ? null : (minSize ?? this.minSize),
      maxSize: clearMaxSize ? null : (maxSize ?? this.maxSize),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includedExtensions': includedExtensions,
      'excludedExtensions': excludedExtensions,
      'excludedFolders': excludedFolders,
      'searchText': searchText,
      'showHiddenFiles': showHiddenFiles,
      'caseSensitive': caseSensitive,
      'modifiedAfter': modifiedAfter?.toIso8601String(),
      'modifiedBefore': modifiedBefore?.toIso8601String(),
      'minSize': minSize,
      'maxSize': maxSize,
    };
  }

  factory FilterOptions.fromJson(Map<String, dynamic> json) {
    return FilterOptions(
      includedExtensions: List<String>.from(json['includedExtensions'] ?? []),
      excludedExtensions: List<String>.from(json['excludedExtensions'] ?? []),
      excludedFolders: List<String>.from(json['excludedFolders'] ?? []),
      searchText: json['searchText'],
      showHiddenFiles: json['showHiddenFiles'] ?? false,
      caseSensitive: json['caseSensitive'] ?? false,
      modifiedAfter: json['modifiedAfter'] != null ? DateTime.parse(json['modifiedAfter']) : null,
      modifiedBefore: json['modifiedBefore'] != null ? DateTime.parse(json['modifiedBefore']) : null,
      minSize: json['minSize'],
      maxSize: json['maxSize'],
    );
  }
}