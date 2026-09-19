import 'package:flutter/material.dart';
import 'app_colors.dart';

enum OrderStatusType {
  placed,
  confirmed,
  sellerAssigned,
  packed,
  invoiceGenerated,
  manifested,
  dispatched,
  inTransit,
  outForDelivery,
  delivered,
  rto,
  returned,
  cancelled,
}

class OrderStatusHelper {
  static OrderStatusType parse(String? status) {
    if (status == null || status.isEmpty) return OrderStatusType.placed;
    final s = status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (s) {
      case 'placed':
        return OrderStatusType.placed;
      case 'confirmed':
        return OrderStatusType.confirmed;
      case 'seller_assigned':
      case 'sellerassigned':
        return OrderStatusType.sellerAssigned;
      case 'packed':
        return OrderStatusType.packed;
      case 'invoice_generated':
      case 'invoicegenerated':
        return OrderStatusType.invoiceGenerated;
      case 'manifested':
        return OrderStatusType.manifested;
      case 'dispatched':
        return OrderStatusType.dispatched;
      case 'in_transit':
      case 'intransit':
      case 'transit':
        return OrderStatusType.inTransit;
      case 'out_for_delivery':
      case 'outfordelivery':
        return OrderStatusType.outForDelivery;
      case 'delivered':
      case 'completed':
        return OrderStatusType.delivered;
      case 'rto':
      case 'return_to_origin':
        return OrderStatusType.rto;
      case 'returned':
        return OrderStatusType.returned;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return OrderStatusType.cancelled;
      default:
        return OrderStatusType.placed;
    }
  }

  static String getLabel(OrderStatusType type) {
    switch (type) {
      case OrderStatusType.placed:
        return 'Placed';
      case OrderStatusType.confirmed:
        return 'Confirmed';
      case OrderStatusType.sellerAssigned:
        return 'Seller Assigned';
      case OrderStatusType.packed:
        return 'Packed';
      case OrderStatusType.invoiceGenerated:
        return 'Invoice Generated';
      case OrderStatusType.manifested:
        return 'Manifested';
      case OrderStatusType.dispatched:
        return 'Dispatched';
      case OrderStatusType.inTransit:
        return 'In Transit';
      case OrderStatusType.outForDelivery:
        return 'Out For Delivery';
      case OrderStatusType.delivered:
        return 'Delivered';
      case OrderStatusType.rto:
        return 'RTO (Return to Origin)';
      case OrderStatusType.returned:
        return 'Returned';
      case OrderStatusType.cancelled:
        return 'Cancelled';
    }
  }

  static Color getColor(OrderStatusType type) {
    switch (type) {
      case OrderStatusType.placed:
        return AppColors.primary;
      case OrderStatusType.confirmed:
        return Colors.teal;
      case OrderStatusType.sellerAssigned:
        return Colors.indigo;
      case OrderStatusType.packed:
        return Colors.amber.shade800;
      case OrderStatusType.invoiceGenerated:
        return Colors.cyan.shade800;
      case OrderStatusType.manifested:
        return Colors.deepPurple;
      case OrderStatusType.dispatched:
        return Colors.purple;
      case OrderStatusType.inTransit:
        return Colors.blue.shade700;
      case OrderStatusType.outForDelivery:
        return Colors.deepOrange;
      case OrderStatusType.delivered:
        return Colors.green;
      case OrderStatusType.rto:
        return Colors.brown;
      case OrderStatusType.returned:
        return Colors.blueGrey;
      case OrderStatusType.cancelled:
        return Colors.red;
    }
  }

  static IconData getIcon(OrderStatusType type) {
    switch (type) {
      case OrderStatusType.placed:
        return Icons.shopping_bag_outlined;
      case OrderStatusType.confirmed:
        return Icons.check_circle_outline;
      case OrderStatusType.sellerAssigned:
        return Icons.storefront_outlined;
      case OrderStatusType.packed:
        return Icons.inventory_2_outlined;
      case OrderStatusType.invoiceGenerated:
        return Icons.receipt_long_outlined;
      case OrderStatusType.manifested:
        return Icons.assignment_turned_in_outlined;
      case OrderStatusType.dispatched:
        return Icons.local_shipping_outlined;
      case OrderStatusType.inTransit:
        return Icons.directions_bus_outlined;
      case OrderStatusType.outForDelivery:
        return Icons.delivery_dining_outlined;
      case OrderStatusType.delivered:
        return Icons.task_alt;
      case OrderStatusType.rto:
        return Icons.assignment_return_outlined;
      case OrderStatusType.returned:
        return Icons.replay;
      case OrderStatusType.cancelled:
        return Icons.cancel_outlined;
    }
  }

  static bool isActive(OrderStatusType type) {
    return type != OrderStatusType.delivered &&
        type != OrderStatusType.cancelled &&
        type != OrderStatusType.returned &&
        type != OrderStatusType.rto;
  }

  static int getStepIndex(OrderStatusType type) {
    switch (type) {
      case OrderStatusType.placed:
        return 0;
      case OrderStatusType.confirmed:
        return 1;
      case OrderStatusType.sellerAssigned:
        return 2;
      case OrderStatusType.packed:
        return 3;
      case OrderStatusType.invoiceGenerated:
        return 4;
      case OrderStatusType.manifested:
        return 5;
      case OrderStatusType.dispatched:
        return 6;
      case OrderStatusType.inTransit:
        return 7;
      case OrderStatusType.outForDelivery:
        return 8;
      case OrderStatusType.delivered:
        return 9;
      case OrderStatusType.rto:
      case OrderStatusType.returned:
      case OrderStatusType.cancelled:
        return -1;
    }
  }
}
