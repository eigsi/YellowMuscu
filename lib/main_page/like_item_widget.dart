// like_item_widget.dart

import 'package:flutter/material.dart';

class LikeItem extends StatelessWidget {
  final String profileImage;
  final String description;
  final VoidCallback onLike;

  const LikeItem({
    super.key,
    required this.profileImage,
    required this.description,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    bool isLiked = false; // Vous pouvez gérer l'état du like ici

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profileImage),
      ),
      title: Text(description),
      trailing: IconButton(
        // ignore: dead_code
        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : null),
        onPressed: onLike,
      ),
    );
  }
}
