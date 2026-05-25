import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressor {
  /// Compresses [imageFile] to target a size between 300 KB and 500 KB,
  /// and a maximum resolution of 1080p (width/height max 1920).
  /// Outputs a compressed JPEG image file.
  static Future<File> compress({
    required File imageFile,
    int maxDimension = 1920,
    int initialQuality = 80,
  }) async {
    final originalPath = imageFile.absolute.path;
    final originalSize = await imageFile.length();
    
    debugPrint('[ImageCompressor] Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

    // If already small enough (under 300 KB), just skip compression
    if (originalSize <= 300 * 1024) {
      debugPrint('[ImageCompressor] File is already smaller than 300 KB, skipping compression.');
      return imageFile;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = p.join(tempDir.path, 'receipt_${timestamp}_compressed.jpg');

      debugPrint('[ImageCompressor] Compressing image to: $targetPath');

      // First pass compression
      XFile? resultFile = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
        quality: initialQuality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        format: CompressFormat.jpeg,
      );

      if (resultFile == null) {
        debugPrint('[ImageCompressor] Compression failed (null result), returning original.');
        return imageFile;
      }

      File compressedFile = File(resultFile.path);
      int compressedSize = await compressedFile.length();
      debugPrint('[ImageCompressor] First pass size: ${(compressedSize / 1024).toStringAsFixed(2)} KB at quality $initialQuality');

      // Dynamic adjustment loop if file is still larger than 500 KB
      int currentQuality = initialQuality;
      while (compressedSize > 500 * 1024 && currentQuality > 35) {
        currentQuality -= 15;
        debugPrint('[ImageCompressor] File still too large. Re-compressing with quality $currentQuality...');

        // Delete old temp file to be clean
        if (await compressedFile.exists()) {
          try {
            await compressedFile.delete();
          } catch (_) {}
        }

        resultFile = await FlutterImageCompress.compressAndGetFile(
          originalPath,
          targetPath,
          quality: currentQuality,
          minWidth: maxDimension,
          minHeight: maxDimension,
          format: CompressFormat.jpeg,
        );

        if (resultFile == null) {
          debugPrint('[ImageCompressor] Re-compression returned null, using previous or original.');
          break;
        }

        compressedFile = File(resultFile.path);
        compressedSize = await compressedFile.length();
        debugPrint('[ImageCompressor] Re-compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB at quality $currentQuality');
      }

      final savings = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      debugPrint('[ImageCompressor] Successfully compressed from ${(originalSize / 1024).toStringAsFixed(1)} KB to ${(compressedSize / 1024).toStringAsFixed(1)} KB (Saved $savings%)');
      
      return compressedFile;
    } catch (e, stack) {
      // Robust error fallback
      debugPrint('[ImageCompressor] Error during compression: $e');
      debugPrint(stack.toString());
      debugPrint('[ImageCompressor] Falling back to original uncompressed file.');
      return imageFile;
    }
  }
}
