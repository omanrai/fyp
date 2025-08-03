import 'package:flutter_fyp/core/utility/clear_focus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AIProvider { chatGPT, claude, gemini }

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AIProvider? aiProvider;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.aiProvider,
  });
}

class ChatAIController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<AIProvider> selectedProvider = AIProvider.chatGPT.obs;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Secure storage for API keys with better configuration
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _openAIKey;
  String? _claudeKey;
  String? _geminiKey;

  // Track which providers are available
  final RxList<AIProvider> availableProviders = <AIProvider>[].obs;
  final RxBool hasAnyApiKey = false.obs;
  final RxBool isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // Fixed _showApiKeySetupDialog method and related dialog handling methods

  Future<void> _initializeController() async {
    try {
      isInitializing.value = true;
      await _loadApiKeys();
    } catch (e) {
      print('Error during initialization: $e');
      _handleStorageError(e);
    } finally {
      isInitializing.value = false;
    }
  }

  // Load API keys from secure storage with error handling
  Future<void> _loadApiKeys() async {
    try {
      // Try to read API keys with timeout
      _openAIKey = await _storage
          .read(key: 'openai_api_key')
          .timeout(Duration(seconds: 5), onTimeout: () => null);
      _claudeKey = await _storage
          .read(key: 'claude_api_key')
          .timeout(Duration(seconds: 5), onTimeout: () => null);
      _geminiKey = await _storage
          .read(key: 'gemini_api_key')
          .timeout(Duration(seconds: 5), onTimeout: () => null);

      _updateAvailableProviders();

      // If no keys exist at all, show setup dialog
      if (!hasAnyApiKey.value) {
        Future.delayed(Duration(milliseconds: 500), () {
          _showApiKeySetupDialog();
        });
      } else {
        // Set default provider to first available one
        if (availableProviders.isNotEmpty) {
          selectedProvider.value = availableProviders.first;
        }
        _addWelcomeMessage();
      }
    } catch (e) {
      print('Error loading API keys: $e');
      _handleStorageError(e);
    }
  }

  void _handleStorageError(dynamic error) {
    print('Storage error: $error');

    // Show fallback dialog for manual key entry
    _showSnackbar(
      'Storage Issue',
      'Unable to access secure storage. You can still enter API keys manually.',
      backgroundColor: Colors.orange,
    );

    // Show setup dialog after a delay
    Future.delayed(Duration(seconds: 2), () {
      _showApiKeySetupDialog();
    });
  }

  // Update available providers based on existing API keys
  void _updateAvailableProviders() {
    availableProviders.clear();

    if (_openAIKey != null && _openAIKey!.isNotEmpty) {
      availableProviders.add(AIProvider.chatGPT);
    }
    if (_claudeKey != null && _claudeKey!.isNotEmpty) {
      availableProviders.add(AIProvider.claude);
    }
    if (_geminiKey != null && _geminiKey!.isNotEmpty) {
      availableProviders.add(AIProvider.gemini);
    }

    hasAnyApiKey.value = availableProviders.isNotEmpty;
  }

  void _showApiKeySetupDialog() {
    final openAIController = TextEditingController();
    final claudeController = TextEditingController();
    final geminiController = TextEditingController();

    // Pre-fill with existing keys if available
    if (_openAIKey != null) openAIController.text = _openAIKey!;
    if (_claudeKey != null) claudeController.text = _claudeKey!;
    if (_geminiKey != null) geminiController.text = _geminiKey!;

    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          return hasAnyApiKey.value; // Only allow back if keys exist
        },
        child: AlertDialog(
          title: Text('Setup API Keys'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter at least one API key to enable AI chat functionality:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 You only need one API key to get started. You can add more later.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: openAIController,
                  decoration: InputDecoration(
                    labelText: 'OpenAI API Key (Optional)',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.chat, color: Colors.green),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: claudeController,
                  decoration: InputDecoration(
                    labelText: 'Claude API Key (Optional)',
                    hintText: 'sk-ant-...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.psychology, color: Colors.orange),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: geminiController,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key (Optional)',
                    hintText: 'AIza...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.auto_awesome, color: Colors.blue),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasAnyApiKey.value) // Only show cancel if keys exist
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                if (hasAnyApiKey.value) SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final openAI = openAIController.text.trim();
                    final claude = claudeController.text.trim();
                    final gemini = geminiController.text.trim();

                    // Validate that at least one key is provided
                    if (openAI.isEmpty && claude.isEmpty && gemini.isEmpty) {
                      _showSnackbar(
                        'Error',
                        'Please provide at least one API key',
                        backgroundColor: Colors.red,
                      );
                      return;
                    }

                    // Close current dialog first
                    Get.back();

                    // Show loading dialog
                    _showLoadingDialog();

                    try {
                      await _storeApiKeys(
                        openAI.isEmpty ? null : openAI,
                        claude.isEmpty ? null : claude,
                        gemini.isEmpty ? null : gemini,
                      );
                    } catch (e) {
                      print('Error saving keys: $e');
                    } finally {
                      // Close loading dialog
                      if (Get.isDialogOpen ?? false) {
                        Get.back();
                      }
                    }
                  },
                  child: Text('Save Keys'),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: hasAnyApiKey.value,
    );
  }

  // Simplified loading dialog
  void _showLoadingDialog() {
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving API keys...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Simplified _storeApiKeys method - remove complex dialog closing
  Future<void> _storeApiKeys(
    String? openAI,
    String? claude,
    String? gemini,
  ) async {
    try {
      // Store non-empty keys with timeout
      if (openAI != null && openAI.isNotEmpty) {
        await _storage
            .write(key: 'openai_api_key', value: openAI)
            .timeout(Duration(seconds: 5));
        _openAIKey = openAI;
      }
      if (claude != null && claude.isNotEmpty) {
        await _storage
            .write(key: 'claude_api_key', value: claude)
            .timeout(Duration(seconds: 5));
        _claudeKey = claude;
      }
      if (gemini != null && gemini.isNotEmpty) {
        await _storage
            .write(key: 'gemini_api_key', value: gemini)
            .timeout(Duration(seconds: 5));
        _geminiKey = gemini;
      }

      _updateAvailableProviders();

      // Set default provider to first available one
      if (availableProviders.isNotEmpty) {
        selectedProvider.value = availableProviders.first;
      }

      // Add welcome message if this is the first time
      if (messages.isEmpty) {
        _addWelcomeMessage();
      }

      // Show success message after a delay to ensure dialog is closed
      Future.delayed(Duration(milliseconds: 300), () {
        _showSnackbar(
          'Success',
          'API keys saved successfully! Available providers: ${availableProviders.length}',
        );
      });
    } catch (e) {
      print('Error storing API keys: $e');
      // Show error message after a delay
      Future.delayed(Duration(milliseconds: 300), () {
        _showSnackbar(
          'Error',
          'Failed to save API keys. Please try again.',
          backgroundColor: Colors.red,
        );
      });
    }
  }

  // Simplified snackbar method
  void _showSnackbar(String title, String message, {Color? backgroundColor}) {
    // Close any existing snackbar first
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    // Small delay to ensure previous snackbar is fully closed
    Future.delayed(Duration(milliseconds: 200), () {
      if (Get.context != null) {
        // Check if context is still available
        Get.snackbar(
          title,
          message,
          backgroundColor: backgroundColor ?? Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    });
  }

  void _addWelcomeMessage() {
    messages.clear(); // Clear any existing messages
    messages.add(
      ChatMessage(
        content:
            "Hello! I'm your AI assistant using ${_getProviderName(selectedProvider.value)}. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: selectedProvider.value,
      ),
    );
  }

  void changeAIProvider(AIProvider provider) {
    // Check if provider is available
    if (!availableProviders.contains(provider)) {
      _showSnackbar(
        'Provider Unavailable',
        'API key for ${_getProviderName(provider)} is not configured. Please add it in settings.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    selectedProvider.value = provider;
    messages.add(
      ChatMessage(
        content:
            "Switched to ${_getProviderName(provider)}. How can I assist you?",
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: provider,
      ),
    );
    _scrollToBottom();
  }

  String _getProviderName(AIProvider provider) {
    switch (provider) {
      case AIProvider.chatGPT:
        return 'ChatGPT';
      case AIProvider.claude:
        return 'Claude';
      case AIProvider.gemini:
        return 'Gemini';
    }
  }

  Color _getProviderColor(AIProvider provider) {
    switch (provider) {
      case AIProvider.chatGPT:
        return Colors.green;
      case AIProvider.claude:
        return Colors.orange;
      case AIProvider.gemini:
        return Colors.blue;
    }
  }

  Color get currentProviderColor => _getProviderColor(selectedProvider.value);
  String get currentProviderName => _getProviderName(selectedProvider.value);

  void sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty || isLoading.value) return;

    // Check if current provider is available
    if (!availableProviders.contains(selectedProvider.value)) {
      _showSnackbar(
        'Error',
        'API key not found for ${_getProviderName(selectedProvider.value)}. Please configure it first.',
        backgroundColor: Colors.red,
      );
      return;
    }

    String? apiKey = _getApiKeyForProvider(selectedProvider.value);
    if (apiKey == null || apiKey.isEmpty) {
      _showSnackbar(
        'Error',
        'API key not found for ${_getProviderName(selectedProvider.value)}',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Add user message
    messages.add(
      ChatMessage(
        content: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    messageController.clear();
    isLoading.value = true;
    _scrollToBottom();

    try {
      String response;
      switch (selectedProvider.value) {
        case AIProvider.chatGPT:
          response = await _sendToChatGPT(messageText, apiKey);
          break;
        case AIProvider.claude:
          response = await _sendToClaude(messageText, apiKey);
          break;
        case AIProvider.gemini:
          response = await _sendToGemini(messageText, apiKey);
          break;
      }

      // Add AI response
      messages.add(
        ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
          aiProvider: selectedProvider.value,
        ),
      );
    } catch (e) {
      // Add error message
      messages.add(
        ChatMessage(
          content: "Sorry, I encountered an error: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
          aiProvider: selectedProvider.value,
        ),
      );
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  String? _getApiKeyForProvider(AIProvider provider) {
    switch (provider) {
      case AIProvider.chatGPT:
        return _openAIKey;
      case AIProvider.claude:
        return _claudeKey;
      case AIProvider.gemini:
        return _geminiKey;
    }
  }

  Future<String> _sendToChatGPT(String message, String apiKey) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful AI assistant for students and educators. Provide clear, educational responses.',
          },
          {'role': 'user', 'content': message},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      final errorData = json.decode(response.body);
      throw Exception('OpenAI Error: ${errorData['error']['message']}');
    }
  }

  Future<String> _sendToClaude(String message, String apiKey) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 500,
        'messages': [
          {
            'role': 'user',
            'content':
                'You are a helpful AI assistant for students and educators. Provide clear, educational responses. User question: $message',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'][0]['text'].toString().trim();
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Claude Error: ${errorData['error']['message']}');
    }
  }

  Future<String> _sendToGemini(String message, String apiKey) async {
    // Use the current supported model name
    const String modelName =
        'gemini-1.5-flash'; // or 'gemini-2.5-flash' for newer version

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'You are a helpful AI assistant for students and educators. Provide clear, educational responses. User question: $message',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 500,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Check if the response has candidates
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final candidate = data['candidates'][0];

        // Check if content exists and has parts
        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            candidate['content']['parts'].isNotEmpty) {
          return candidate['content']['parts'][0]['text'].toString().trim();
        } else {
          throw Exception('Gemini Error: No content in response');
        }
      } else {
        throw Exception('Gemini Error: No candidates in response');
      }
    } else {
      final errorData = json.decode(response.body);
      String errorMessage = 'Unknown error';

      // Better error handling for different error types
      if (errorData['error'] != null) {
        if (errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];
        } else if (errorData['error']['details'] != null) {
          errorMessage = errorData['error']['details'].toString();
        }
      }

      // Provide more user-friendly error messages
      if (response.statusCode == 400) {
        if (errorMessage.contains('models/gemini-pro')) {
          errorMessage =
              'Model not found. Please check your API configuration.';
        } else if (errorMessage.contains('API key')) {
          errorMessage = 'Invalid API key. Please check your Gemini API key.';
        }
      } else if (response.statusCode == 403) {
        errorMessage = 'Access denied. Please check your API key permissions.';
      } else if (response.statusCode == 429) {
        errorMessage = 'Rate limit exceeded. Please try again later.';
      }

      throw Exception('Gemini Error (${response.statusCode}): $errorMessage');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearChat() {
    messages.clear();
    _addWelcomeMessage();
  }

  void deleteMessage(int index) {
    if (index >= 0 && index < messages.length) {
      messages.removeAt(index);
    }
  }

  // Method to update API keys if needed
  void showUpdateKeysDialog() {
    _showApiKeySetupDialog();
  }

  // Check if a provider is available
  bool isProviderAvailable(AIProvider provider) {
    return availableProviders.contains(provider);
  }

  // Get list of available providers for UI
  List<AIProvider> getAvailableProviders() {
    return availableProviders.toList();
  }
}
