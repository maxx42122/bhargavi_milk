import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colors.dart';
import '../core/text_styles.dart';

/// An interactive quantity stepper with a direct editable text bar and +/- buttons.
class QuantityStepper extends StatefulWidget {
  final int qty;
  final int? maxStock;
  final ValueChanged<int> onChanged;
  final String addLabel;
  final bool compact;
  final String? productName;

  const QuantityStepper({
    super.key,
    required this.qty,
    required this.onChanged,
    this.maxStock,
    this.addLabel = 'ADD',
    this.compact = false,
    this.productName,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.qty > 0 ? '${widget.qty}' : '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final currentParsed = int.tryParse(_controller.text) ?? 0;
      if (currentParsed != widget.qty) {
        _controller.text = widget.qty > 0 ? '${widget.qty}' : '';
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      // Auto-select text so typing replaces the current quantity immediately
      if (_controller.text.isNotEmpty) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    } else {
      final text = _controller.text.trim();
      if (text.isEmpty || text == '0') {
        _applyQuantity(0);
      } else {
        final val = int.tryParse(text);
        if (val != null) {
          _applyQuantity(val);
        } else {
          _controller.text = widget.qty > 0 ? '${widget.qty}' : '';
        }
      }
    }
  }

  void _applyQuantity(int quantity) {
    int target = quantity;
    if (widget.maxStock != null &&
        widget.maxStock! > 0 &&
        target > widget.maxStock!) {
      target = widget.maxStock!;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productName != null
                  ? 'Only ${widget.maxStock} available for ${widget.productName}'
                  : 'Only ${widget.maxStock} available in stock',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.amber600,
          ),
        );
      }
    }

    if (target < 0) target = 0;

    widget.onChanged(target);
    _controller.text = target > 0 ? '$target' : '';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.qty <= 0) {
      return GestureDetector(
        onTap: () => _applyQuantity(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.milkBlue600,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.milkBlue600.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 14),
              const SizedBox(width: 3),
              Text(
                widget.addLabel,
                style: (widget.compact
                        ? AppTextStyles.captionBold
                        : AppTextStyles.bodyBold)
                    .copyWith(
                  color: Colors.white,
                  fontSize: widget.compact ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final buttonSize = widget.compact ? 26.0 : 30.0;
    final iconSize = widget.compact ? 13.0 : 15.0;
    final inputWidth = widget.compact ? 42.0 : 48.0;
    final inputHeight = widget.compact ? 26.0 : 30.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button (-)
        GestureDetector(
          onTap: () {
            if (widget.qty > 1) {
              _applyQuantity(widget.qty - 1);
            } else {
              _applyQuantity(0);
            }
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.milkBlue100,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Icon(
                Icons.remove,
                color: AppColors.milkBlue700,
                size: iconSize,
              ),
            ),
          ),
        ),
        // Direct editable quantity text bar
        Container(
          width: inputWidth,
          height: inputHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.milkBlue50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.milkBlue600
                  : AppColors.border,
              width: _focusNode.hasFocus ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.milkBlue700,
              fontSize: widget.compact ? 12 : 13,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 2,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onSubmitted: (val) {
              final parsed = int.tryParse(val) ?? 0;
              _applyQuantity(parsed);
              _focusNode.unfocus();
            },
            onChanged: (val) {
              if (val.isNotEmpty) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed > 0) {
                  _applyQuantity(parsed);
                }
              }
            },
          ),
        ),
        // Increment button (+)
        GestureDetector(
          onTap: () {
            if (widget.maxStock != null &&
                widget.maxStock! > 0 &&
                widget.qty >= widget.maxStock!) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.productName != null
                        ? 'Only ${widget.maxStock} in stock for ${widget.productName}'
                        : 'Only ${widget.maxStock} in stock',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.amber600,
                ),
              );
              return;
            }
            _applyQuantity(widget.qty + 1);
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.milkBlue600,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.milkBlue600.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
