/// RFC 4180 style CSV options with spreadsheet-safety switches.
class CsvOptions {
  const CsvOptions({
    this.delimiter = ',',
    this.newline = '\r\n',
    this.includeHeader = true,
    this.utf8Bom = false,
    this.formulaGuard = true,
    this.quoteAll = false,
  });

  final String delimiter;
  final String newline;
  final bool includeHeader;
  final bool utf8Bom;

  /// Prefixes `'` to values starting with = + - @ so spreadsheets keep them as text.
  final bool formulaGuard;
  final bool quoteAll;

  CsvOptions withDelimiter(String d) => CsvOptions(
    delimiter: d,
    newline: newline,
    includeHeader: includeHeader,
    utf8Bom: utf8Bom,
    formulaGuard: formulaGuard,
    quoteAll: quoteAll,
  );
}

class CsvEncoder {
  const CsvEncoder([this.options = const CsvOptions()]);

  final CsvOptions options;

  static const _formulaStarts = {'=', '+', '-', '@', '\t', '\r'};

  String encodeCell(String value) {
    var v = value;
    if (options.formulaGuard && v.isNotEmpty && _formulaStarts.contains(v[0])) v = "'$v";
    final needsQuote = options.quoteAll ||
        v.contains(options.delimiter) ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r') ||
        v.startsWith(' ') ||
        v.endsWith(' ');
    return needsQuote ? '"${v.replaceAll('"', '""')}"' : v;
  }

  String encodeRow(List<String> cells) => cells.map(encodeCell).join(options.delimiter);

  String encode(List<String> header, Iterable<List<String>> rows) {
    final b = StringBuffer();
    if (options.utf8Bom) b.write('﻿');
    if (options.includeHeader) b..write(encodeRow(header))..write(options.newline);
    for (final r in rows) {
      b..write(encodeRow(r))..write(options.newline);
    }
    return b.toString();
  }
}
