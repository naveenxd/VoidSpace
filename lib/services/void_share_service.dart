import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:void_space/app/secrets.dart';
import 'package:void_space/data/models/void_item.dart';

class VoidShareService {
  static const _xDevHUrl = 'https://x.devh.in';

  /// Posts an HTML to the paste endpoint, returns the URL.
  static Future<String> shareAsWebsite(VoidItem item) async {
    // 1. Generate HTML
    final String html = _generateHtml(item);

    // 2. Upload to Paste endpoint
    final response = await http.post(
      Uri.parse('$_xDevHUrl/api/tools/paste'),
      headers: {
        'Authorization': 'Bearer $xDevhToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': html, 'lang': 'html'}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to upload website to paste: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final slug = data['paste']['slug'];

    // 3. Return target URL
    return '$_xDevHUrl/view?t=p&i=$slug';
  }

  /// Generates a PDF and saves it to a temporary local file, returning the File.
  static Future<File> generatePdfFile(VoidItem item) async {
    // 1. Generate PDF
    final Uint8List pdfBytes = await _generatePdf(item);

    // 2. Save it to a temporary directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/void_space_export_${item.id}.pdf');
    await file.writeAsBytes(pdfBytes);

    return file;
  }

  static String _generateHtml(VoidItem item) {
    // Generate clean self contained html page.
    final String title = htmlEscape(item.title);
    final String contentLines = htmlEscape(
      item.content,
    ).replaceAll('\n', '<br>');
    final String summary = item.summary != null
        ? htmlEscape(item.summary!)
        : '';

    final tagsHtml = item.tags
        .map((tag) => '<span class="tag">#${htmlEscape(tag)}</span>')
        .join(' ');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>\$title - Void Space</title>
  <style>
    :root {
      --bg: #0A0A0A;
      --card-bg: #141414;
      --text: #EDEDED;
      --text-dim: #A1A1AA;
      --accent: #E5E5E5;
      --border: #262626;
    }
    body {
      font-family: 'Inter', system-ui, -apple-system, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      padding: 40px 20px;
    }
    .header {
      margin-bottom: 24px;
      border-bottom: 1px solid var(--border);
      padding-bottom: 24px;
    }
    .type-badge {
      display: inline-block;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 1px;
      font-weight: 600;
      color: var(--bg);
      background-color: var(--text);
      padding: 4px 10px;
      border-radius: 4px;
      margin-bottom: 12px;
    }
    h1 {
      margin: 0 0 16px 0;
      font-size: 32px;
      font-weight: 700;
      letter-spacing: -0.5px;
    }
    .tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .tag {
      font-size: 13px;
      color: var(--text-dim);
      background: var(--card-bg);
      border: 1px solid var(--border);
      padding: 4px 12px;
      border-radius: 16px;
    }
    .content-box {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 24px;
      margin-top: 32px;
    }
    .summary-box {
      font-size: 16px;
      color: var(--text-dim);
      border-left: 2px solid var(--accent);
      padding-left: 16px;
      margin: 24px 0;
    }
    .footer {
      margin-top: 60px;
      text-align: center;
      font-size: 13px;
      color: var(--text-dim);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="type-badge">${htmlEscape(item.type)}</div>
      <h1>$title</h1>
      <div class="tags">
        $tagsHtml
      </div>
    </div>
    
    ${summary.isNotEmpty ? '<div class="summary-box">$summary</div>' : ''}
    
    <div class="content-box">
      $contentLines
    </div>

    <div class="footer">
      Shared from VoidSpace
    </div>
  </div>
</body>
</html>
''';
  }

  static String htmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static Future<Uint8List> _generatePdf(VoidItem item) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              text: item.title,
              textStyle: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            if (item.tags.isNotEmpty)
              pw.Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.tags
                    .map(
                      (t) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          '#$t',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 20),
            if (item.summary != null && item.summary!.isNotEmpty) ...[
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                item.summary!,
                style: const pw.TextStyle(
                  fontSize: 12,
                  lineSpacing: 1.5,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Text(
              'Content',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              item.content,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Prepared via VoidSpace',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
