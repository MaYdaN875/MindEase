typedef JsonMap = Map<String, dynamic>;

JsonMap objectMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
int communityCount(dynamic value) => value is num ? value.toInt() : 0;

class CommunityCategory {
  final String id, name, slug;
  final String? description;
  CommunityCategory.fromJson(JsonMap json)
    : id = json['id'] ?? '',
      name = json['name'] ?? '',
      slug = json['slug'] ?? '',
      description = json['description'];
}

class CommunityChannel {
  final String id, name, description, psychologistName;
  final String? coverImageUrl, specialties;
  final CommunityCategory category;
  final int followersCount, postsCount;
  final bool isFollowing, isOwner, isActive;
  CommunityChannel.fromJson(JsonMap json)
    : id = json['id'] ?? '',
      name = json['name'] ?? '',
      description = json['description'] ?? '',
      psychologistName =
          objectMap(json['psychologist'])['name'] ??
          objectMap(objectMap(json['psychologist'])['user'])['name'] ??
          'Profesional',
      coverImageUrl = json['coverImageUrl'],
      specialties = json['specialties'],
      category = CommunityCategory.fromJson(objectMap(json['category'])),
      followersCount = communityCount(
        json['followersCount'] ?? objectMap(json['_count'])['followers'],
      ),
      postsCount = communityCount(
        json['postsCount'] ?? objectMap(json['_count'])['posts'],
      ),
      isFollowing = json['isFollowing'] == true,
      isOwner = json['isOwner'] == true,
      isActive = json['isActive'] != false;
}

class PostMedia {
  final String type, url;
  final String? id, caption, thumbnailUrl;
  final int? sizeBytes;
  const PostMedia({
    required this.type,
    required this.url,
    this.id,
    this.caption,
    this.thumbnailUrl,
    this.sizeBytes,
  });
  factory PostMedia.fromJson(JsonMap json) => PostMedia(
    id: json['id'],
    type: json['type'] ?? 'LINK',
    url: json['url'] ?? '',
    caption: json['caption'] ?? json['originalName'],
    thumbnailUrl: json['thumbnailUrl'],
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
  );
  JsonMap toJson() => {
    'type': type,
    'url': url,
    if (caption != null) 'caption': caption,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
  };
}

class CommunityPost {
  final String id, channelId, channelName, authorName, title, content, status;
  final List<String> tags;
  final List<PostMedia> media;
  final int likesCount, commentsCount;
  final bool isLiked, isAuthor;
  final DateTime? publishedAt;
  CommunityPost.fromJson(JsonMap json)
    : id = json['id'] ?? '',
      channelId = json['channelId'] ?? objectMap(json['channel'])['id'] ?? '',
      channelName = objectMap(json['channel'])['name'] ?? '',
      authorName = objectMap(json['author'])['name'] ?? 'Profesional',
      title = json['title'] ?? '',
      content = json['content'] ?? '',
      status = json['status'] ?? 'DRAFT',
      tags = (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      media = (json['media'] as List? ?? [])
          .map((e) => PostMedia.fromJson(objectMap(e)))
          .toList(),
      likesCount = communityCount(
        json['likesCount'] ?? objectMap(json['_count'])['likes'],
      ),
      commentsCount = communityCount(
        json['commentsCount'] ?? objectMap(json['_count'])['comments'],
      ),
      isLiked = json['isLiked'] == true,
      isAuthor = json['isAuthor'] == true,
      publishedAt = DateTime.tryParse(
        json['publishedAt'] ?? json['createdAt'] ?? '',
      );
}

class PostComment {
  final String id, postId, content, authorName;
  final bool isOwner, isHidden;
  final DateTime? createdAt;
  PostComment.fromJson(JsonMap json)
    : id = json['id'] ?? '',
      postId = json['postId'] ?? '',
      content = json['content'] ?? '',
      authorName =
          objectMap(json['author'])['name'] ??
          objectMap(json['user'])['name'] ??
          'Usuario',
      isOwner = json['isOwner'] == true,
      isHidden = json['isHidden'] == true,
      createdAt = DateTime.tryParse(json['createdAt'] ?? '');
}

class CommunityPage<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
  const CommunityPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
  factory CommunityPage.fromJson(JsonMap json, T Function(JsonMap) parse) =>
      CommunityPage(
        items: (json['items'] as List? ?? [])
            .map((e) => parse(objectMap(e)))
            .toList(),
        nextCursor: json['nextCursor'],
        hasMore: json['hasMore'] == true && json['nextCursor'] != null,
      );
}
