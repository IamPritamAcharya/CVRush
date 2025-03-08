import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;

  const RatingWidget({
    Key? key,
    required this.initialRating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  _RatingWidgetState createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  double rating = 0;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: index < rating ? Colors.orange : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              rating = index + 1.0;
            });
            widget.onRatingChanged(rating);
          },
        );
      }),
    );
  }
}
