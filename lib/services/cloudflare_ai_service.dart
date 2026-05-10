import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

/// Result from Cloudflare AI analysis
class CloudflareAIResult {
  final String title;
  final String summary;
  final String tldr;
  final List<String> tags;
  
  CloudflareAIResult({
    required this.title,
    required this.summary,
    required this.tldr,
    required this.tags,
  });
}

/// Unified AI Service using Cloudflare Workers AI (Llama 3.2 Vision)
/// Replaces GroqService - handles both text and image analysis
class CloudflareAIService {
  static const String _endpoint = 'https://void.nxd2k26.workers.dev/';
  static const int _maxImageSize = 512; // Reduced for faster upload
  
  /// Compress image to reduce payload size (inline, no isolate)
  static Future<Uint8List?> _compressImage(Uint8List bytes) async {
    try {
      debugPrint('CloudflareAI: Starting compression...');
      // Do compression inline (no compute/isolate) for share activity compatibility
      final result = _compressImageSync(bytes);
      debugPrint('CloudflareAI: Compression complete');
      return result;
    } catch (e) {
      debugPrint('CloudflareAI: Image compression failed: $e');
      return bytes; // Return original if compression fails
    }
  }
  
  static Uint8List _compressImageSync(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    
    // Resize if larger than max size
    img.Image resized;
    if (image.width > _maxImageSize || image.height > _maxImageSize) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: _maxImageSize);
      } else {
        resized = img.copyResize(image, height: _maxImageSize);
      }
    } else {
      resized = image;
    }
    
    // Encode as JPEG with 75% quality for faster upload
    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }
  
  /// Analyze an image file and get AI-generated title, description + tags
  static Future<CloudflareAIResult?> analyzeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('CloudflareAI: File not found: $imagePath');
        return null;
      }

      // Read and compress image
      final bytes = await file.readAsBytes();
      debugPrint('CloudflareAI: Original size: ${bytes.length} bytes');
      
      final compressed = await _compressImage(bytes);
      if (compressed == null) return null;
      
      debugPrint('CloudflareAI: Compressed size: ${compressed.length} bytes');
      debugPrint('CloudflareAI: *** AFTER COMPRESSION - STARTING API CALL ***');

      final prompt = '''Analyze this image for a digital knowledge base.
You MUST respond with valid JSON in this exact format:
{
  "title": "A short descriptive title (3-5 words)",
  "summary": "5-7 detailed sentences providing a deep-dive analysis of the image content, technical details, and context.",
  "tldr": "One sentence summary",
  "tags": ["tag1", "tag2", "tag3"]
}

CRITICAL:
- Respond ONLY with the JSON object.
- Ensure "title" and "tags" are ALWAYS included.
- Be clinical, technical, and aesthetic.
- DO NOT use conversational filler.''';


      // Use multipart form data with actual file upload
      debugPrint('CloudflareAI: Building multipart request to $_endpoint');
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      
      // Add image as actual file (not as base64 string field)
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        compressed,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      
      request.fields['user_message'] = prompt;
      request.fields['system_prompt'] = 'Respond ONLY with valid JSON metadata. No conversational text.';
      
      debugPrint('CloudflareAI: Sending image request (${compressed.length} bytes)...');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      debugPrint('CloudflareAI: Got streamed response, reading body...');
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('CloudflareAI: Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('CloudflareAI Error: ${response.statusCode} - ${response.body}');
        return null;
      }

      debugPrint('CloudflareAI: Response body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      return _parseResponse(response);
    } catch (e, stack) {
      debugPrint('CloudflareAI image error: $e');
      debugPrint('CloudflareAI stack: $stack');
      return null;
    }
  }
  
  /// Analyze text content and get AI-generated title, summary + tags
  static Future<CloudflareAIResult?> analyzeText(String title, String content, {String? url}) async {
    try {
      debugPrint('CloudflareAI: Analyzing text (${content.length} chars)');
      
      final truncatedContent = content.length > 3000 ? content.substring(0, 3000) : content;

      final prompt = '''You are a Digital Archivist. Analyze this content for a personal knowledge base.

Context:
Title: $title
${url != null ? 'Source URL: $url' : ''}
Content: $truncatedContent

Provide:
1. A refined TITLE (keep original if good, improve if generic/filename-like)
2. A SUMMARY paragraph (3-5 sentences, clinical but aesthetic)
3. A one-line TLDR
4. 3-5 relevant TAGS

CRITICAL INSTRUCTIONS:
- NO AI-speak ("Discover", "Unlock", "Master")
- NO first person
- Tone: Clinical, aesthetic, like a museum plaque

Respond ONLY with valid JSON:
{
  "title": "Refined Title Here",
  "description": "Summary paragraph here...",
  "tldr": "One-line summary",
  "tags": ["tag1", "tag2", "tag3"]
}''';

      // Use multipart form data
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      request.fields['user_message'] = prompt;
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        debugPrint('CloudflareAI Error: ${response.statusCode} - ${response.body}');
        return null;
      }

      return _parseResponse(response);
    } catch (e) {
      debugPrint('CloudflareAI text error: $e');
      return null;
    }
  }
  
  /// Parse response from Cloudflare Workers AI
  static CloudflareAIResult? _parseResponse(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      String title = '';
      String description = '';
      String tldr = '';
      List<String> tags = [];
      
      // Handle direct JSON response
      if (data is Map) {
        title = data['title'] as String? ?? '';
        description = data['summary'] as String? ?? data['description'] as String? ?? '';
        tldr = data['tldr'] as String? ?? '';
        tags = (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
        
        // Handle Cloudflare's specific 'result' or 'response' wrappers
        final dynamic nested = data['result'] ?? data['response'];
        if (nested != null) {
          if (nested is Map) {
            title = nested['title'] as String? ?? title;
            description = nested['summary'] as String? ?? nested['description'] as String? ?? description;
            tldr = nested['tldr'] as String? ?? tldr;
            tags = (nested['tags'] as List?)?.map((e) => e.toString()).toList() ?? tags;
          } else if (nested is String) {
            try {
              // Extract JSON from string if AI added conversational filler
              final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(nested);
              if (jsonMatch != null) {
                final parsed = jsonDecode(jsonMatch.group(0)!);
                title = parsed['title'] as String? ?? title;
                description = parsed['summary'] as String? ?? parsed['description'] as String? ?? description;
                tldr = parsed['tldr'] as String? ?? tldr;
                tags = (parsed['tags'] as List?)?.map((e) => e.toString()).toList() ?? tags;
              } else {
                // FALLBACK: Parse as Markdown-style list if no JSON found
                title = _extractLabel(nested, 'TITLE') ?? title;
                description = _extractLabel(nested, 'SUMMARY') ?? 
                             _extractLabel(nested, 'DESCRIPTION') ?? 
                             _extractLabel(nested, 'DESC') ?? nested;
                tldr = _extractLabel(nested, 'TLDR') ?? tldr;
                
                final tagsStr = _extractLabel(nested, 'TAGS');
                if (tagsStr != null) {
                  tags = tagsStr.split(RegExp(r'[,#]')).map((e) => e.trim().replaceAll('#', '')).where((e) => e.isNotEmpty).toList();
                }
              }
            } catch (_) {
              if (description.isEmpty) description = nested;
            }
          }
        }
      }
      if (description.isEmpty && title.isEmpty) {
        debugPrint('CloudflareAI Error: Empty response from API. Body: ${response.body}');
        return null;
      }

      // Use first sentence of description as title if not provided
      if (title.isEmpty && description.isNotEmpty) {
        final sentences = description.split(RegExp(r'[.!?]'));
        title = sentences.first.trim();
        if (title.length > 50) title = '${title.substring(0, 47)}...';
      }

      // Final title fallback
      if (title.isEmpty) title = 'Image Analysis';

      // Use first sentence of description as tldr if not provided
      if (tldr.isEmpty && description.isNotEmpty) {
        tldr = description.split(RegExp(r'[.!?]')).first.trim();
      }
      
      // Default tags if none found or too few
      final finalTags = {...tags, 'ai-analyzed', 'shared'}.toList();

      debugPrint('CloudflareAI: Got title=$title, desc=${description.length} chars, ${tags.length} tags');
      return CloudflareAIResult(
        title: title,
        summary: description,
        tldr: tldr,
        tags: finalTags,
      );
    } catch (e) {
      debugPrint('CloudflareAI parse error: $e');
      return null;
    }
  }

  static String? _extractLabel(String text, String label) {
    final regExp = RegExp(
      r'(?:\*\*|#)?' + label + r'(?:\*\*|:)?\s*[:\-]?\s*(.*?)(?:\n|$|\*\*)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    return null;
  }
}
