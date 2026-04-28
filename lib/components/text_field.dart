import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
class MyTextField extends StatefulWidget {
  final String value;
  final TextInputType keyboardType;
  final bool isInteger;
  final bool isNumber;
  final double? maxValue;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final TextAlign? textAlign;
  final Function(String) onChange;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final EdgeInsetsGeometry? padding;
  final Color? bgColor;
  final TextStyle? textStyle;
  final bool? isEnabled;
  const MyTextField({
    super.key,
    required this.onChange,
    required this.value,
    this.keyboardType = TextInputType.text,
    this.isInteger = false,
    this.isNumber = false,
    this.maxValue,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.textAlign,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.border,
    this.focusedBorder,
    this.padding,
    this.bgColor,
    this.textStyle,
    this.isEnabled = true,
  });
  @override
  createState() => _MyTextFieldState();
}
class _MyTextFieldState extends State<MyTextField> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == "0" ? "" : widget.value,
    );
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }
  @override
  void didUpdateWidget(MyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      final currentSelection = _controller.selection;
      _controller.text = widget.value == "0" ? "" : widget.value;
      if (currentSelection.isValid &&
          currentSelection.baseOffset <= _controller.text.length) {
        _controller.selection = currentSelection;
      } else {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    List<TextInputFormatter> inputFormatters = [];
    if (widget.isInteger) {
      inputFormatters.add(
        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*$')),
      );
      if (widget.maxValue != null) {
        inputFormatters.add(_MaxValueInputFormatter(widget.maxValue!, true));
      }
    } else if (widget.isNumber) {
      inputFormatters.add(
        FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*$')),
      );
      inputFormatters.add(
        XNumberTextInputFormatter(maxIntegerLength: null, maxDecimalLength: 1),
      );
      if (widget.maxValue != null) {
        inputFormatters.add(_MaxValueInputFormatter(widget.maxValue!, true));
      }
    }
    return TextField(
      controller: _controller,
      textAlign: widget.textAlign ?? TextAlign.start,
      keyboardType: widget.keyboardType,
      inputFormatters: inputFormatters.isEmpty ? null : inputFormatters,
      maxLength: widget.maxLength,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style:
          widget.textStyle ??
          TextStyle(
            color: Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Input...',
        hintStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Color(0xFFCECECE),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20.sp, color: Colors.grey[600])
            : null,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                icon: Icon(
                  widget.suffixIcon,
                  size: 20.sp,
                  color: Colors.grey[600],
                ),
                onPressed: widget.onSuffixIconPressed,
              )
            : null,
        contentPadding: widget.padding ?? EdgeInsets.zero,
        border: widget.border ?? InputBorder.none,
        enabledBorder: widget.border ?? InputBorder.none,
        focusedBorder:
            widget.focusedBorder ?? widget.border ?? InputBorder.none,
        filled: widget.bgColor != null,
        fillColor: widget.bgColor ?? Colors.transparent,
      ),
      onChanged: (v) => widget.onChange.call(v),
      enabled: widget.isEnabled,
    );
  }
}
class _MaxValueInputFormatter extends TextInputFormatter {
  final double maxValue;
  final bool isInt;
  _MaxValueInputFormatter(this.maxValue, this.isInt);
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    try {
      final double value = double.parse(newValue.text);
      if (value > maxValue) {
        if (isInt) {
          return TextEditingValue(text: maxValue.toInt().toString());
        }
        return TextEditingValue(text: maxValue.toString());
      }
    } catch (e) {
      return oldValue;
    }
    return newValue;
  }
}
class XNumberTextInputFormatter extends TextInputFormatter {
  final int? maxIntegerLength;
  final int? maxDecimalLength;
  XNumberTextInputFormatter({this.maxIntegerLength, this.maxDecimalLength});
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.trim();
    int selectionOffset = newValue.selection.end;
    if (newText.isEmpty) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selectionOffset),
      );
    }
    if (newText == '.') {
      newText = '0.';
      selectionOffset = selectionOffset < 0 ? 2 : selectionOffset + 1;
    }
    String integerPart = newText;
    String decimalPart = '';
    if (newText.contains('.')) {
      final parts = newText.split('.');
      integerPart = parts[0].isEmpty ? '0' : parts[0];
      decimalPart = parts.length > 1 ? parts[1] : '';
    }
    if (maxIntegerLength != null &&
        integerPart.replaceFirst('-', '').length > maxIntegerLength!) {
      return oldValue;
    }
    if (maxDecimalLength != null &&
        decimalPart.isNotEmpty &&
        decimalPart.length > maxDecimalLength!) {
      return oldValue;
    }
    String finalText = newText;
    if (integerPart == '0' && newText.startsWith('.')) {
      finalText = '0.$decimalPart';
      if (newText != finalText && selectionOffset == 1) {
        selectionOffset = 2;
      }
    }
    try {
      if (finalText.isNotEmpty && finalText != '-' && finalText != '.') {
        double.parse(finalText);
      }
    } catch (e) {
      return oldValue;
    }
    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}
