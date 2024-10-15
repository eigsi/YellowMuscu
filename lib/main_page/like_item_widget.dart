import 'package:flutter/material.dart';

class LikeItem extends StatefulWidget {
  final String profileImage;
  final String description;

  const LikeItem({
    Key? key,
    required this.profileImage,
    required this.description,
  }) : super(key: key);

  @override
  _LikeItemState createState() => _LikeItemState();
}

class _LikeItemState extends State<LikeItem> {
  bool isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.profileImage),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.flash_on : Icons.flash_on,
              color: isFavorite ? Colors.yellow[700] : Colors.grey,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
    );
  }
}
