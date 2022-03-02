class Post {
  final int? id;
  final String title;
  final String content;
  final String created_at;
  final String updated_at;
  final String status;
  final int post_order;

  Post(
      {this.id,
      required this.title,
      required this.content,
      required this.created_at,
      required this.updated_at,
      required this.status,
      required this.post_order});

  factory Post.fromMap(Map<String, dynamic> json) => new Post(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
        status: json['status'],
        post_order: json['post_order'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': created_at,
      'updated_at': updated_at,
      'status': status,
      'post_order': post_order
    };
  }
}
