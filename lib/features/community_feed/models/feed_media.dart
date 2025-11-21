enum FeedMediaType {
  image,
  video,
  gif,
}

extension FeedMediaTypeX on FeedMediaType {
  bool get isImage => this == FeedMediaType.image;
  bool get isVideo => this == FeedMediaType.video;
  bool get isGif => this == FeedMediaType.gif;
}

class FeedMedia {
  const FeedMedia({
    this.type = FeedMediaType.image,
    required this.url,
    this.thumbnailUrl,
    this.width = 0,
    this.height = 0,
    this.durationSeconds = 0.0,
    this.blurHash,
    this.isUploaded = false,
    this.isUploading = false,
    this.uploadId,
  });

  final FeedMediaType type;
  final String url;
  final String? thumbnailUrl;
  final int width;
  final int height;
  final double durationSeconds;
  final String? blurHash;
  final bool isUploaded;
  final bool isUploading;
  final String? uploadId;

  bool get hasThumbnail =>
      thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty;

  FeedMedia copyWith({
    FeedMediaType? type,
    String? url,
    String? thumbnailUrl,
    int? width,
    int? height,
    double? durationSeconds,
    String? blurHash,
    bool? isUploaded,
    bool? isUploading,
    String? uploadId,
  }) {
    return FeedMedia(
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      blurHash: blurHash ?? this.blurHash,
      isUploaded: isUploaded ?? this.isUploaded,
      isUploading: isUploading ?? this.isUploading,
      uploadId: uploadId ?? this.uploadId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'width': width,
      'height': height,
      'durationSeconds': durationSeconds,
      'blurHash': blurHash,
      'isUploaded': isUploaded,
      'isUploading': isUploading,
      'uploadId': uploadId,
    };
  }

  factory FeedMedia.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'];
    final resolvedType = FeedMediaType.values.firstWhere(
      (value) => value.name == typeValue,
      orElse: () => FeedMediaType.image,
    );

    return FeedMedia(
      type: resolvedType,
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
      blurHash: json['blurHash'] as String?,
      isUploaded: json['isUploaded'] as bool? ?? false,
      isUploading: json['isUploading'] as bool? ?? false,
      uploadId: json['uploadId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedMedia &&
        other.type == type &&
        other.url == url &&
        other.thumbnailUrl == thumbnailUrl &&
        other.width == width &&
        other.height == height &&
        other.durationSeconds == durationSeconds &&
        other.blurHash == blurHash &&
        other.isUploaded == isUploaded &&
        other.isUploading == isUploading &&
        other.uploadId == uploadId;
  }

  @override
  int get hashCode => Object.hash(
        type,
        url,
        thumbnailUrl,
        width,
        height,
        durationSeconds,
        blurHash,
        isUploaded,
        isUploading,
        uploadId,
      );
}

