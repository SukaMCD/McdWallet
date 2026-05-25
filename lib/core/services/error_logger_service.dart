import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ErrorLoggerService {
  static final ErrorLoggerService _instance = ErrorLoggerService._internal();
  factory ErrorLoggerService() => _instance;
  ErrorLoggerService._internal();

  File? _logFile;

  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/errors.log');
      
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }

      // Beritahu lokasi file log di terminal saat development
      debugPrint('==================================================');
      debugPrint('File Log Error disimpan di: ${_logFile!.path}');
      debugPrint('==================================================');

      _setupErrorHandlers();
      
      // Log application start
      _logMessage('Application Started');
    } catch (e) {
      // Fallback if directory access fails
      debugPrint('ErrorLoggerService init failed: $e');
    }
  }

  void _setupErrorHandlers() {
    // Suppress and log Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError('Flutter Error', details.exception, details.stack);
    };

    // Suppress and log async Dart errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Async Dart Error', error, stack);
      return true; // Return true to prevent default console logging
    };

    // Replace the red error screen with a subtle blank box to avoid breaking the UI flow entirely
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _logError('UI Build Error', details.exception, details.stack);
      // We return an empty box instead of the red screen of death
      return const SizedBox.shrink(); 
    };
  }

  Future<void> _logError(String type, dynamic error, StackTrace? stack) async {
    if (_logFile == null) return;

    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final logEntry = StringBuffer()
        ..writeln('=== [$timestamp] $type ===')
        ..writeln('Error: $error')
        ..writeln('Stacktrace:')
        ..writeln(stack?.toString() ?? 'No stacktrace available')
        ..writeln('=====================================\n');

      await _logFile!.writeAsString(logEntry.toString(), mode: FileMode.append);
    } catch (e) {
      // Safely ignore logging failures
    }
  }
  
  Future<void> _logMessage(String message) async {
    if (_logFile == null) return;
    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await _logFile!.writeAsString('[$timestamp] INFO: $message\n', mode: FileMode.append);
    } catch (e) {}
  }
}
