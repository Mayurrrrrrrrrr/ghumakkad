import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/trip.dart';
import '../../../models/ticket.dart';
import '../../../models/hotel.dart';
import '../../../providers/docs_provider.dart';
import 'add_ticket_screen.dart';
import 'add_hotel_screen.dart';

class DocsScreen extends ConsumerWidget {
  final Trip trip;
  
  const DocsScreen({Key? key, required this.trip}) : super(key: key);

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flight, color: AppColors.secondary, size: 28),
                title: Text('Add Ticket', style: AppTypography.heading.copyWith(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddTicketScreen(trip: trip)));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.hotel, color: AppColors.primary, size: 28),
                title: Text('Add Hotel', style: AppTypography.heading.copyWith(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddHotelScreen(trip: trip)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(docsProvider(trip.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Documents & Bookings', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(docsProvider(trip.id)),
          )
        ],
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: \$err')),
        data: (docs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTicketsSection(docs.tickets),
              const SizedBox(height: 24),
              _buildHotelsSection(docs.hotels),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTicketsSection(List<Ticket> tickets) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            const Icon(Icons.confirmation_num, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text('Tickets (\${tickets.length})', style: AppTypography.heading.copyWith(fontSize: 18)),
          ],
        ),
        children: tickets.isEmpty 
            ? [const Padding(padding: EdgeInsets.all(16.0), child: Text("No tickets added yet."))]
            : tickets.map((t) => _buildTicketCard(t)).toList(),
      ),
    );
  }

  Widget _buildHotelsSection(List<Hotel> hotels) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            const Icon(Icons.hotel, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Hotels (\${hotels.length})', style: AppTypography.heading.copyWith(fontSize: 18)),
          ],
        ),
        children: hotels.isEmpty 
            ? [const Padding(padding: EdgeInsets.all(16.0), child: Text("No hotels added yet."))]
            : hotels.map((h) => _buildHotelCard(h)).toList(),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    IconData getIcon() {
      if (ticket.ticketType.toLowerCase().contains('flight')) return Icons.flight;
      if (ticket.ticketType.toLowerCase().contains('train')) return Icons.train;
      return Icons.directions_bus;
    }

    String dateStr = ticket.travelDate != null 
        ? DateFormat('MMM dd, yyyy').format(ticket.travelDate!) 
        : 'Date TBA';

    return ExpansionTile(
      title: Row(
        children: [
          Icon(getIcon(), size: 20, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text("\${ticket.fromPlace} → \${ticket.toPlace}", style: AppTypography.body.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
      subtitle: Text("\$dateStr | PNR: \${ticket.pnrNumber ?? 'N/A'}", style: AppTypography.caption),
      trailing: Text("₹\${ticket.amount?.toStringAsFixed(0) ?? '0'}", style: AppTypography.heading.copyWith(color: AppColors.primary)),
      children: [
        if (ticket.ticketImageUrl != null && ticket.ticketImageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: ticket.ticketImageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (ticket.notes != null && ticket.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Notes: \${ticket.notes}", style: AppTypography.body),
            ),
          ),
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    String dateStr = 'Dates TBA';
    if (hotel.checkIn != null && hotel.checkOut != null) {
      dateStr = "\${DateFormat('MMM dd').format(hotel.checkIn!)} - \${DateFormat('MMM dd').format(hotel.checkOut!)}";
    }

    return ExpansionTile(
      title: Text("\${hotel.hotelName}", style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text("\${hotel.city ?? 'Location TBA'} | \$dateStr", style: AppTypography.caption),
      trailing: Text("₹\${hotel.amount?.toStringAsFixed(0) ?? '0'}", style: AppTypography.heading.copyWith(color: AppColors.primary)),
      children: [
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
           child: Row(
             children: [
               const Icon(Icons.confirmation_number, size: 16, color: AppColors.textMuted),
               const SizedBox(width: 8),
               Text("Confirmation: \${hotel.confirmationNo ?? 'N/A'}", style: AppTypography.body),
             ],
           ),
         ),
        if (hotel.bookingImageUrl != null && hotel.bookingImageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: hotel.bookingImageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (hotel.notes != null && hotel.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Notes: \${hotel.notes}", style: AppTypography.body),
            ),
          ),
          const SizedBox(height: 8),
      ],
    );
  }
}
