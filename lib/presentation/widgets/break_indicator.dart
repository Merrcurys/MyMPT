import 'package:flutter/material.dart';
import 'package:my_mpt/data/services/calls_service.dart';

class BreakIndicator extends StatelessWidget {
  final String startTime;
  final String endTime;

  const BreakIndicator({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final String duration = CallsService.getBreakDuration(startTime, endTime);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0), // Added top padding (8.0) and removed bottom padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.directions_run,
          size: 16,
          color: Colors.white54,
        ),
        const SizedBox(width: 8),
        Text(
          'Перемена $duration',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          '$startTime - $endTime',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
      ),
    );
  }
}