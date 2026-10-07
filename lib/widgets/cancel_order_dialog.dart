import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';

/// Shows a cancellation confirmation dialog with predefined reasons
/// and integrates directly with the cancel order API.
Future<bool> showCancelOrderDialog({
  required BuildContext context,
  required String orderId,
  String? orderNo,
  VoidCallback? onCancelled,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CancelOrderBottomSheet(
      orderId: orderId,
      orderNo: orderNo,
    ),
  );

  if (result == true && onCancelled != null) {
    onCancelled();
  }
  return result ?? false;
}

class _CancelOrderBottomSheet extends StatefulWidget {
  final String orderId;
  final String? orderNo;

  const _CancelOrderBottomSheet({
    required this.orderId,
    this.orderNo,
  });

  @override
  State<_CancelOrderBottomSheet> createState() => _CancelOrderBottomSheetState();
}

class _CancelOrderBottomSheetState extends State<_CancelOrderBottomSheet> {
  final List<String> _reasons = [
    'This is wrong product for me',
    'Ordered by mistake',
    'Found a better price elsewhere',
    'Expected delivery date is too late',
    'Need to change shipping address or phone',
    'Other reason',
  ];

  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    final effectiveReason = _selectedReason == 'Other reason'
        ? _customReasonController.text.trim()
        : _selectedReason;

    if (effectiveReason.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for cancellation';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final res = await AppState().cancelOrder(
      orderId: widget.orderId,
      reason: effectiveReason,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (res.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.message.isNotEmpty
                      ? res.message
                      : 'Order cancelled successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Failed to cancel order. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = AppState().isDoctorLoggedIn;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Order No
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (widget.orderNo != null && widget.orderNo!.isNotEmpty)
                          Text(
                            widget.orderNo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Please select a reason for cancelling this order:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // Reason Radio Options
              ..._reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      _errorMessage = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: reason,
                          groupValue: _selectedReason,
                          activeColor: isDoctor
                              ? const Color(0xFF0D9488)
                              : AppColors.primary,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedReason = val;
                                _errorMessage = null;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Custom reason text box if "Other reason" selected
              if (_selectedReason == 'Other reason') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customReasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter your cancellation reason...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDoctor
                            ? const Color(0xFF0D9488)
                            : AppColors.primary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],

              // Error display
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Keep Order',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
