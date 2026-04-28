import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../main.dart';
import 'timeloom_rich_note_line_widgets.dart';
import 'timeloom_rich_note_tokens.dart';
const String kFmtBold = 'bold';
const String kFmtItalic = 'italic';
const String kFmtStrike = 'strike';
const String kFmtHighlight = 'highlight';
const String kFmtUnderline = 'underline';
const String kFmtTextColor = 'textColor';
const String kFmtBullet = 'bullet';
const String kFmtOrdered = 'ordered';
const String kFmtTodo = 'todo';
const String kFmtQuote = 'quote';
const String kFmtH1 = 'h1';
const String kFmtH2 = 'h2';
const String kFmtH3 = 'h3';
const String kFmtLink = 'link';
const int kMaxRichNoteIndentLevel = 8;
class RichNoteTextController extends TextEditingController {
  RichNoteTextController({
    super.text,
    this.onImageTap,
    this.onFileTap,
    this.onVoiceTap,
  });
  final void Function(String path)? onImageTap;
  final void Function(String name, String path)? onFileTap;
  final void Function(String path)? onVoiceTap;
  double? _textContentWidth;
  double? get textContentWidth => _textContentWidth;
  void updateTextContentWidth(double w) {
    if (!w.isFinite || w <= 0) return;
    if (_textContentWidth != null &&
        (_textContentWidth! - w).abs() < 0.5) {
      return;
    }
    _textContentWidth = w;
    notifyListeners();
  }
  double _fallbackTextBodyWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width - 32;
  }
  static final reInlineBold = RegExp(r'\*\*(.*?)\*\*', dotAll: true);
  static final reInlineStrike = RegExp(r'~~(.*?)~~', dotAll: true);
  static final reInlineHighlight = RegExp(r'==(.*?)==', dotAll: true);
  static final reInlineItalic = RegExp(
    r'(?<!\*)\*([^*]+?)\*(?!\*)',
    dotAll: true,
  );
  static final reInlineUnderline = RegExp(r'%%(.*?)%%', dotAll: true);
  static final reInlineTextColor = RegExp(
    r'#C\[([0-9A-Fa-f]{6})\](.*?)#C',
    dotAll: true,
  );
  static final reInlineLink = RegExp(
    r'\[([^\]]*)\]\(([^)]+)\)',
  );
  static final _inlinePatterns = [
    _InlinePattern(kFmtBold, reInlineBold),
    _InlinePattern(kFmtStrike, reInlineStrike),
    _InlinePattern(kFmtHighlight, reInlineHighlight),
    _InlinePattern(kFmtUnderline, reInlineUnderline),
    _InlinePattern(kFmtTextColor, reInlineTextColor),
    _InlinePattern(kFmtItalic, reInlineItalic),
  ];
  static final _linePrefixes = [
    _LinePrefix(kFmtTodo, RegExp(r'^(- \[[ xX]\] )')),
    _LinePrefix(kFmtBullet, RegExp(r'^(- )')),
    _LinePrefix(kFmtOrdered, RegExp(r'^(\d+\. )')),
    _LinePrefix(kFmtQuote, RegExp(r'^(> )')),
    _LinePrefix(kFmtH1, RegExp(r'^(# )')),
    _LinePrefix(kFmtH2, RegExp(r'^(## )')),
    _LinePrefix(kFmtH3, RegExp(r'^(### )')),
  ];
  static String? semanticKeyForLineRest(String rest) {
    for (final lp in _linePrefixes) {
      if (lp.pattern.firstMatch(rest) != null) {
        return lp.key;
      }
    }
    return null;
  }
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final fullText = text;
    if (fullText.isEmpty) return TextSpan(style: baseStyle);
    final lines = fullText.split('\n');
    final spans = <InlineSpan>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      spans.addAll(_buildLineSpans(line, baseStyle, context));
      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: baseStyle));
      }
    }
    return TextSpan(style: baseStyle, children: spans);
  }
  List<InlineSpan> _buildLineSpans(
    String line,
    TextStyle baseStyle,
    BuildContext context,
  ) {
    if (line.isEmpty) return [TextSpan(text: '', style: baseStyle)];
    final iLen0 = richNoteLineIndentLength(line);
    final rest0 = line.substring(iLen0);
    final bodyW = _textContentWidth ?? _fallbackTextBodyWidth(context);
    if (RegExp(r'^---+$').hasMatch(rest0)) {
      final out = <InlineSpan>[];
      if (iLen0 > 0) {
        out.add(TextSpan(text: line.substring(0, iLen0), style: baseStyle));
      }
      out.addAll(_horizontalRuleSpans(rest0, baseStyle, bodyW));
      return out;
    }
    final imgPath = pathFromImageMarkdownLine(rest0);
    if (imgPath != null) {
      if (kIsWeb) {
        return [TextSpan(text: line, style: baseStyle)];
      }
      return _lineWithWidgetIndent(
        line,
        iLen0,
        baseStyle,
        RichNoteImagePlaceholder(
          filePath: imgPath,
          onTap: () => onImageTap?.call(imgPath),
        ),
      );
    }
    final fileData = parseRichNoteFileLine(rest0);
    if (fileData != null) {
      return _lineWithWidgetIndent(
        line,
        iLen0,
        baseStyle,
        RichNoteFilePlaceholder(
          displayName: fileData.name,
          path: fileData.path,
          onTap: () => onFileTap?.call(fileData.name, fileData.path),
        ),
      );
    }
    final voiceData = parseRichNoteVoiceLine(rest0);
    if (voiceData != null) {
      return _lineWithWidgetIndent(
        line,
        iLen0,
        baseStyle,
        RichNoteVoicePlaceholder(
          filePath: voiceData.path,
          onTap: () => onVoiceTap?.call(voiceData.path),
        ),
      );
    }
    final iLen = richNoteLineIndentLength(line);
    final indent = iLen > 0 ? line.substring(0, iLen) : '';
    final rest = line.substring(iLen);
    var prefix = '';
    var fmtKey = '';
    var content = rest;
    for (final lp in _linePrefixes) {
      final m = lp.pattern.firstMatch(rest);
      if (m != null) {
        prefix = m.group(1)!;
        fmtKey = lp.key;
        content = rest.substring(prefix.length);
        break;
      }
    }
    final lineStyle = _lineContentStyle(fmtKey, baseStyle);
    final prefixStyle = _linePrefixStyle(fmtKey, baseStyle);
    final spans = <InlineSpan>[];
    if (indent.isNotEmpty) {
      spans.add(TextSpan(text: indent, style: baseStyle));
    }
    if (prefix.isNotEmpty) {
      spans.add(TextSpan(text: prefix, style: prefixStyle));
    }
    spans.addAll(_buildInlineSpans(content, lineStyle));
    return spans;
  }
  List<InlineSpan> _horizontalRuleSpans(
    String line,
    TextStyle baseStyle,
    double targetBodyWidth,
  ) {
    if (line.isEmpty) return [TextSpan(text: '', style: baseStyle)];
    final tp = TextPainter(
      text: TextSpan(text: line, style: baseStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final w0 = tp.width;
    var ls = 0.0;
    if (line.length > 1) {
      final g = (targetBodyWidth - w0) / (line.length - 1);
      ls = g.isFinite ? g : 0.0;
    }
    if (ls < 0) ls = 0.0;
    if (ls > 500) ls = 500;
    return [
      TextSpan(
        text: line,
        style: baseStyle.copyWith(
          color: dividerColor,
          letterSpacing: ls,
        ),
      ),
    ];
  }
  TextStyle _widgetLineTextStyle(TextStyle baseStyle) {
    final h = baseStyle.height;
    if (h != null) return baseStyle;
    return baseStyle.copyWith(height: 1.7);
  }
  List<InlineSpan> _lineWithWidgetIndent(
    String line,
    int iLen0,
    TextStyle baseStyle,
    Widget child,
  ) {
    final strut = _widgetLineTextStyle(baseStyle);
    if (iLen0 > 0) {
      return [
        TextSpan(text: line.substring(0, iLen0), style: strut),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: child,
        ),
      ];
    }
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: child,
      ),
    ];
  }
  void _addMarkdownLinkSpans(
    RegExpMatch m,
    TextStyle baseStyle,
    List<InlineSpan> out,
  ) {
    final label = m.group(1) ?? '';
    final url = m.group(2) ?? '';
    final markerStyle = baseStyle.copyWith(
      color: textSecondaryColor.withValues(alpha: 0.35),
      fontSize: (baseStyle.fontSize ?? 15) * 0.7,
    );
    final linkStyle = baseStyle.copyWith(
      color: primaryColor,
      decoration: TextDecoration.underline,
      decorationColor: primaryColor,
    );
    out.addAll([
      TextSpan(text: '[', style: markerStyle),
      TextSpan(text: label, style: linkStyle),
      TextSpan(text: ']', style: markerStyle),
      TextSpan(text: '(', style: markerStyle),
      TextSpan(
        text: url,
        style: markerStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 15) * 0.75,
        ),
      ),
      TextSpan(text: ')', style: markerStyle),
    ]);
  }
  List<InlineSpan> _buildInlineSpans(String text, TextStyle baseStyle) {
    if (text.isEmpty) return [TextSpan(text: '', style: baseStyle)];
    final spans = <InlineSpan>[];
    int pos = 0;
    while (pos < text.length) {
      int nearestStart = text.length;
      _InlinePattern? nearestPattern;
      RegExpMatch? nearestMatch;
      for (final pattern in _inlinePatterns) {
        final m = pattern.regex.firstMatch(text.substring(pos));
        if (m != null) {
          final abs = pos + m.start;
          if (abs < nearestStart) {
            nearestStart = abs;
            nearestPattern = pattern;
            nearestMatch = m;
          }
        }
      }
      final mLink = reInlineLink.firstMatch(text.substring(pos));
      final useLink = mLink != null &&
          (nearestPattern == null || pos + mLink.start < nearestStart);
      if (nearestPattern == null && mLink == null) {
        spans.add(TextSpan(text: text.substring(pos), style: baseStyle));
        break;
      }
      if (useLink) {
        if (pos + mLink.start > pos) {
          spans.add(
            TextSpan(
              text: text.substring(pos, pos + mLink.start),
              style: baseStyle,
            ),
          );
        }
        _addMarkdownLinkSpans(mLink, baseStyle, spans);
        pos = pos + mLink.end;
        continue;
      }
      if (nearestPattern == null || nearestMatch == null) {
        spans.add(TextSpan(text: text.substring(pos), style: baseStyle));
        break;
      }
      if (nearestStart > pos) {
        spans.add(
          TextSpan(text: text.substring(pos, nearestStart), style: baseStyle),
        );
      }
      if (nearestPattern.key == kFmtTextColor) {
        final m = nearestMatch;
        final hex = m.group(1) ?? '000000';
        final inner2 = m.group(2) ?? '';
        final open = '#C[$hex]';
        const close = '#C';
        final col = Color(0xFF000000 | int.parse(hex, radix: 16));
        final markerStyle = baseStyle.copyWith(
          color: textSecondaryColor.withValues(alpha: 0.35),
          fontSize: (baseStyle.fontSize ?? 15) * 0.7,
        );
        final contentStyle = baseStyle.copyWith(color: col);
        spans.add(TextSpan(text: open, style: markerStyle));
        spans.add(TextSpan(text: inner2, style: contentStyle));
        spans.add(TextSpan(text: close, style: markerStyle));
        pos = nearestStart + m.group(0)!.length;
        continue;
      }
      final fullMatch = nearestMatch.group(0)!;
      final inner = nearestMatch.group(1)!;
      final markerLen = (fullMatch.length - inner.length) ~/ 2;
      final marker = fullMatch.substring(0, markerLen);
      final markerStyle = baseStyle.copyWith(
        color: textSecondaryColor.withValues(alpha: 0.35),
        fontSize: (baseStyle.fontSize ?? 15) * 0.7,
      );
      final contentStyle = _inlineContentStyle(nearestPattern.key, baseStyle);
      spans.add(TextSpan(text: marker, style: markerStyle));
      spans.add(TextSpan(text: inner, style: contentStyle));
      spans.add(TextSpan(text: marker, style: markerStyle));
      pos = nearestStart + fullMatch.length;
    }
    return spans;
  }
  TextStyle _inlineContentStyle(String key, TextStyle base) {
    switch (key) {
      case kFmtBold:
        return base.copyWith(fontWeight: FontWeight.w700, color: textColor);
      case kFmtItalic:
        return base.copyWith(fontStyle: FontStyle.italic);
      case kFmtStrike:
        return base.copyWith(
          decoration: TextDecoration.lineThrough,
          color: textSecondaryColor,
        );
      case kFmtHighlight:
        return base.copyWith(
          backgroundColor: const Color(0xFFFFE066),
          color: const Color(0xFF5A4500),
        );
      case kFmtUnderline:
        return base.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: textColor,
        );
      default:
        return base;
    }
  }
  TextStyle _linePrefixStyle(String key, TextStyle base) {
    switch (key) {
      case kFmtH1:
        return base.copyWith(
          color: primaryColor.withValues(alpha: 0.5),
          fontSize: (base.fontSize ?? 15) * 0.75,
        );
      case kFmtH2:
        return base.copyWith(
          color: primaryColor.withValues(alpha: 0.5),
          fontSize: (base.fontSize ?? 15) * 0.75,
        );
      case kFmtH3:
        return base.copyWith(
          color: primaryColor.withValues(alpha: 0.5),
          fontSize: (base.fontSize ?? 15) * 0.75,
        );
      case kFmtBullet:
      case kFmtOrdered:
        return base.copyWith(color: primaryColor, fontWeight: FontWeight.w600);
      case kFmtTodo:
        return base.copyWith(
          color: primaryColor.withValues(alpha: 0.7),
          fontFamily: 'monospace',
        );
      case kFmtQuote:
        return base.copyWith(color: textSecondaryColor.withValues(alpha: 0.5));
      default:
        return base;
    }
  }
  TextStyle _lineContentStyle(String key, TextStyle base) {
    switch (key) {
      case kFmtH1:
        return base.copyWith(
          fontSize: (base.fontSize ?? 15) * 1.4,
          fontWeight: FontWeight.w700,
          color: textColor,
        );
      case kFmtH2:
        return base.copyWith(
          fontSize: (base.fontSize ?? 15) * 1.2,
          fontWeight: FontWeight.w600,
          color: textColor,
        );
      case kFmtH3:
        return base.copyWith(
          fontSize: (base.fontSize ?? 15) * 1.05,
          fontWeight: FontWeight.w600,
          color: textColor,
        );
      case kFmtQuote:
        return base.copyWith(
          color: textSecondaryColor,
          fontStyle: FontStyle.italic,
        );
      case kFmtTodo:
        return base;
      default:
        return base;
    }
  }
  Set<String> getActiveFormats(int cursorOffset) {
    final result = <String>{};
    if (cursorOffset < 0 || cursorOffset > text.length) return result;
    final lineStart = _lineStartOf(cursorOffset);
    final lineEnd = _lineEndOf(cursorOffset);
    final line = text.substring(lineStart, lineEnd);
    final posInLine = cursorOffset - lineStart;
    if (line.isEmpty) return result;
    if (RegExp(r'^---+$').hasMatch(line)) return result;
    final iLen = richNoteLineIndentLength(line);
    final rest = line.substring(iLen);
    var prefix = '';
    for (final lp in _linePrefixes) {
      final m = lp.pattern.firstMatch(rest);
      if (m != null) {
        result.add(lp.key);
        prefix = m.group(1)!;
        break;
      }
    }
    final totalPrefixLen = iLen + prefix.length;
    if (posInLine < totalPrefixLen) return result;
    final content = line.substring(totalPrefixLen);
    final posInContent = posInLine - totalPrefixLen;
    for (final ip in _inlinePatterns) {
      for (final m in ip.regex.allMatches(content)) {
        if (ip.key == kFmtTextColor) {
          if (isCursorInTextColorInner(m, posInContent)) {
            result.add(kFmtTextColor);
            break;
          }
        } else {
          if (_isCursorInInner(m, posInContent)) {
            result.add(ip.key);
            break;
          }
        }
      }
    }
    for (final m in reInlineLink.allMatches(content)) {
      if (posInContent >= m.start && posInContent < m.end) {
        result.add(kFmtLink);
        break;
      }
    }
    return result;
  }
  static bool isCursorInTextColorInner(RegExpMatch m, int posInContent) {
    final g2 = m.group(2) ?? '';
    const openLen = 3 + 6 + 1;
    final innerStart = m.start + openLen;
    if (g2.isEmpty) {
      return posInContent == innerStart;
    }
    final innerEnd = innerStart + g2.length;
    return posInContent >= innerStart && posInContent < innerEnd;
  }
  static bool _isCursorInInner(RegExpMatch m, int posInContent) {
    if (m.groupCount < 1) return false;
    final g0 = m.group(0)!;
    final g1 = m.group(1) ?? '';
    final markLen = (g0.length - g1.length) ~/ 2;
    final innerStart = m.start + markLen;
    if (g1.isEmpty) {
      return posInContent == innerStart;
    }
    final innerEnd = innerStart + g1.length;
    return innerStart <= posInContent && posInContent < innerEnd;
  }
  int _lineStartOf(int offset) {
    final idx = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    return idx < 0 ? 0 : idx + 1;
  }
  int _lineEndOf(int offset) {
    final idx = text.indexOf('\n', offset);
    return idx < 0 ? text.length : idx;
  }
}
class _InlinePattern {
  const _InlinePattern(this.key, this.regex);
  final String key;
  final RegExp regex;
}
class _LinePrefix {
  const _LinePrefix(this.key, this.pattern);
  final String key;
  final RegExp pattern;
}
int richNoteLineStartInText(String text, int offset) {
  if (text.isEmpty) return 0;
  var o = offset;
  if (o < 0) o = 0;
  if (o > text.length) o = text.length;
  final idx = text.lastIndexOf('\n', o > 0 ? o - 1 : 0);
  return idx < 0 ? 0 : idx + 1;
}
int richNoteLineEndInText(String text, int offset) {
  if (text.isEmpty) return 0;
  var o = offset;
  if (o < 0) o = 0;
  if (o > text.length) o = text.length;
  final idx = text.indexOf('\n', o);
  return idx < 0 ? text.length : idx;
}
String? listBodyContinuationForRest(String rest) {
  if (RegExp(r'^- \[[ xX]\] ').hasMatch(rest)) {
    return '- [ ] ';
  }
  if (RegExp(r'^- ').hasMatch(rest)) {
    return '- ';
  }
  if (RegExp(r'^> ').hasMatch(rest)) {
    return '> ';
  }
  final m = RegExp(r'^(\d+)\. ').firstMatch(rest);
  if (m != null) {
    final n = int.parse(m.group(1)!);
    return '${n + 1}. ';
  }
  return null;
}
String? listContinuationForLine(String line) {
  final iLen = richNoteLineIndentLength(line);
  final rest = iLen == 0 ? line : line.substring(iLen);
  final cont = listBodyContinuationForRest(rest);
  if (cont == null) {
    return null;
  }
  if (iLen == 0) {
    return cont;
  }
  return '${line.substring(0, iLen)}$cont';
}
int richNoteLineIndentLength(String line) {
  var i = 0;
  while (i + 1 < line.length &&
      line.codeUnitAt(i) == 0x20 &&
      line.codeUnitAt(i + 1) == 0x20) {
    i += 2;
  }
  return i;
}
