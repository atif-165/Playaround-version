import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/venue.dart';

class BookingSummary extends StatelessWidget {
  final Venue venue;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final int duration;
  final int participants;
  final double totalPrice;

  const BookingSummary({
    Key? key,
    required this.venue,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.duration,
    required this.participants,
    required this.totalPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final endTime = _calculateEndTime(selectedTimeSlot, duration);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Venue Info
          _buildSummaryRow(
            context,
            'Venue',
            venue.name,
            Icons.location_on,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            'Date',
            DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
            Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            'Time',
            '$selectedTimeSlot - $endTime',
            Icons.schedule,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            'Duration',
            '$duration hour${duration > 1 ? 's' : ''}',
            Icons.timer,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            'Participants',
            '$participants participant${participants > 1 ? 's' : ''}',
            Icons.people,
          ),
          const Divider(height: 24),
          // Pricing Breakdown
          _buildPricingBreakdown(context),
          const Divider(height: 24),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingBreakdown(BuildContext context) {
    final hourlyRate = venue.pricing.hourlyRate;
    final subtotal = hourlyRate * duration;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hourly Rate',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '\$${hourlyRate.toStringAsFixed(2)} × $duration',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\$${subtotal.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // Add tax if applicable
        if (totalPrice > subtotal) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\$${(totalPrice - subtotal).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _calculateEndTime(String startTime, int duration) {
    final timeParts = startTime.split(':');
    final startHour = int.parse(timeParts[0]);
    final startMinute = int.parse(timeParts[1]);
    
    final startDateTime = DateTime(2023, 1, 1, startHour, startMinute);
    final endDateTime = startDateTime.add(Duration(hours: duration));
    
    final endHour = endDateTime.hour.toString().padLeft(2, '0');
    final endMinute = endDateTime.minute.toString().padLeft(2, '0');
    
    return '$endHour:$endMinute';
  }
}
