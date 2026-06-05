import 'package:flutter/material.dart';

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(label: Text('按时间'), onSelected: null),
          FilterChip(label: Text('按地区'), onSelected: null),
          FilterChip(label: Text('按种类'), onSelected: null),
        ],
      ),
    );
  }
}
