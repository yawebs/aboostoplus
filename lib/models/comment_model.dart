class CommentModel {
  int id;
  int propertyId;
  String commenterId;
  String comment;
  String commenterName;
  var commenterImage;
  String dateCreated;

  CommentModel({
    required this.id,
    required this.propertyId,
    required this.commenterId,
    required this.comment,
    required this.commenterName,
    required this.dateCreated,
    this.commenterImage,
  });

  factory CommentModel.fromMap(var map) {
    return CommentModel(
      id: map['id'],
      propertyId: map['propertyId'],
      commenterId: map['commenterId'],
      comment: map['comment'],
      commenterName: map['commenterName'],
      dateCreated: map['dateCreated'],
      commenterImage: map['commenterImage'] ?? null,
    );
  }
}
