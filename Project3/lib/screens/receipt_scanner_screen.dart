import 'dart:convert'; // For Base64 encoding
import 'dart:typed_data'; // For reading bytes
import 'package:flutter/foundation.dart' show kIsWeb; // To detect Web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For API calls
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:wolfbite/utils/nutritional_utils.dart';
import '../state/app_state.dart';
import '../services/apl_service.dart';
import 'dart:async'; // Add this at the top

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final _picker = ImagePicker();
  final _apl = AplService();

  bool _scanning = false;
  List<Map<String, dynamic>> _foundItems = [];
  String _status = "Tap button to upload receipt";

  /// 1. Pick Image & Send to API
  Future<void> _scanReceipt() async {
    // A. Ask user for source (Camera isn't great on Web, Gallery is safer)
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery / Upload"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() {
      _scanning = true;
      _status = "Uploading & Analyzing...";
      _foundItems.clear();
    });

    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) {
        setState(() => _scanning = false);
        return;
      }

      // B. Get the image bytes (Web-safe way)
      Uint8List imageBytes = await picked.readAsBytes();
      
      // C. Convert to Base64 for the API
      String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      // D. Send to Cloud API
      final text = await _fetchOcrText(base64Image);

      // E. Parse results
      await _parseUPCs(text);

    } catch (e) {
      setState(() {
        _status = "Error: $e";
        _scanning = false;
      });
    }
  }

  /// Sends the image to the free OCR.space API
Future<String> _fetchOcrText(String base64Image) async {
  // Use the public 'helloworld' key (limits: 25kb max size sometimes, mostly for testing).
  // For a smoother demo, get a free key at https://ocr.space/ocrapi/freekey
  const apiKey = 'helloworld'; 

  final uri = Uri.parse('https://api.ocr.space/parse/image');

  try {
    final response = await http.post(
      uri,
      body: {
        'apikey': apiKey,
        'base64Image': base64Image,
        'language': 'eng',
        'isOverlayRequired': 'false',
        'detectOrientation': 'true', // Added for better accuracy
        'scale': 'true',            // Added for better accuracy
      },
    ).timeout(const Duration(seconds: 15)); // <-- STOP WAITING AFTER 15 SECONDS

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check for API errors
      if (data['IsErroredOnProcessing'] == true) {
        throw Exception(data['ErrorMessage']?[0] ?? "API Processing Error");
      }

      final parsedResults = data['ParsedResults'] as List?;
      if (parsedResults != null && parsedResults.isNotEmpty) {
        return parsedResults[0]['ParsedText'] as String;
      }
      return "";
    } else {
      // 403 usually means the 'helloworld' key is banned/throttled
      if (response.statusCode == 403) {
        throw Exception("API Limit Reached. Try a new API Key.");
      }
      throw Exception("API Error: ${response.statusCode}");
    }
  } on TimeoutException catch (_) {
    throw Exception("Connection timed out. Check internet or API status.");
  }
}

  /// Find 12-digit numbers and lookup in APL
  Future<void> _parseUPCs(String fullText) async {
    print("🔎 Scanned Text:\n$fullText"); // Debug log

    // Regex for 12-digit UPCs
    final regex = RegExp(r'\b\d{12}\b');
    final matches = regex.allMatches(fullText);

    List<Map<String, dynamic>> validItems = [];
    int foundCount = 0;

    for (final match in matches) {
      final upc = match.group(0)!;
      foundCount++;
      
    final info = await _apl.findByUpc(upc);
    if (info != null) {
    final productWithUpc = Map<String, dynamic>.from(info);
    productWithUpc['upc'] = upc; 

    if (!validItems.any((item) => item['upc'] == upc)) {
        validItems.add(productWithUpc);
    }
    }    
}

    setState(() {
      _foundItems = validItems;
      _scanning = false;
      _status = matches.isEmpty 
          ? "No UPCs found.\n(Ensure image is clear & contains 12-digit codes)" 
          : "Found $foundCount codes, ${validItems.length} valid WIC items.";
    });
  }

  void _addAllToBasket() {
    final app = context.read<AppState>();
    int count = 0;
    for (final item in _foundItems) {
      if(app.addItem(
        upc: item['upc'], 
        name: item['name'], 
        category: item['category'],
        nutrition: NutritionalUtils.buildNutritionFromFoodNutrients(item),
      )) count++;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $count items')));
    context.go('/basket');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt (Web)')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Text(
              _status, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _foundItems.isEmpty && !_scanning
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Upload a receipt image"),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _scanReceipt,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Select Image"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _foundItems.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(_foundItems[i]['name']),
                    subtitle: Text("UPC: ${_foundItems[i]['upc']}"),
                  ),
                ),
          ),
          if (_foundItems.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _addAllToBasket,
                    child: const Text("Add to Basket"),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
