import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/colors.dart';
import '../providers/ai_advisor_provider.dart';

class AiAdvisorScreen extends ConsumerStatefulWidget {
  const AiAdvisorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends ConsumerState<AiAdvisorScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Bagaimana ringkasan kesehatan finansial saya saat ini?',
    'Berikan tips untuk memotong anggaran belanja jajan bulanan.',
    'Bantu saya membuat rencana menabung Rp 5 Juta untuk beli laptop.',
  ];

  @override
  void dispose() {
    // Auto-hapus riwayat chat saat screen ditutup/keluar dari tab AI
    // agar setiap sesi baru dimulai dari percakapan yang bersih
    ref.read(aiAdvisorMessagesProvider.notifier).clearChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref.read(aiAdvisorMessagesProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _handleSendSuggestion(String suggestionText) {
    ref.read(aiAdvisorMessagesProvider.notifier).sendMessage(suggestionText);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiAdvisorMessagesProvider);
    final isLoading = ref.watch(aiAdvisorLoadingProvider);

    // Otomatis scroll ke bawah saat pesan baru ditambahkan atau AI sedang berpikir
    ref.listen(aiAdvisorMessagesProvider, (_, __) => _scrollToBottom());
    ref.listen(aiAdvisorLoadingProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Tanya McdAI',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.textSecondary, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Hapus Riwayat Chat?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Seluruh riwayat percakapan dengan McdAI saat ini akan dihapus secara permanen dari perangkat lokal Anda. Lanjutkan?',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Batal', style: TextStyle(color: AppColors.textPrimary)),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ref.read(aiAdvisorMessagesProvider.notifier).clearChat();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Riwayat percakapan berhasil dihapus.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              tooltip: 'Reset Obrolan',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AREA PESAN OBROLAN
            Expanded(
              child: messages.isEmpty && !isLoading
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          // Premium Logo Container with Rippling Effect
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.18),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Halo! Saya McdAI',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'Tanyakan apa saja tentang kondisi finansial, sisa anggaran belanja, atau tips menabung berdasarkan dompet McdWallet Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'REKOMENDASI PERTANYAAN',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._suggestions.map((suggestion) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0, left: 20, right: 20),
                                child: InkWell(
                                  onTap: () => _handleSendSuggestion(suggestion),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border, width: 0.8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.01),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.messageCircle, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            suggestion,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20.0),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Tampilkan typing indicator jika di indeks terakhir saat loading
                        if (index == messages.length) {
                          return _buildTypingIndicator();
                        }

                        final msg = messages[index];
                        return _buildChatBubble(msg);
                      },
                    ),
            ),

            // INPUT BAR DI BAGIAN BAWAH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            maxLines: 4,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Tulis pesan atau pertanyaan finansial...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _handleSendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'McdAI dapat membuat kesalahan. Verifikasi informasi penting sebelum mengambil keputusan keuangan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuat visualisasi gelembung obrolan chat
  Widget _buildChatBubble(dynamic msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser ? Colors.transparent : AppColors.border,
                  width: 0.8,
                ),
                boxShadow: isUser
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: isUser
                  ? Text(
                      msg.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.45),
                        h1: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit', height: 1.4),
                        h2: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit', height: 1.4),
                        h3: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit', height: 1.4),
                        listBullet: const TextStyle(color: AppColors.primary, fontSize: 14),
                        blockquote: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                        strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        code: TextStyle(
                          backgroundColor: AppColors.background,
                          color: AppColors.danger,
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  /// Membuat visualisasi loading indikator AI sedang memikirkan jawaban
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8.0, top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoadingDot(0),
                const SizedBox(width: 4),
                _buildLoadingDot(150),
                const SizedBox(width: 4),
                _buildLoadingDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Animasi titik denyut linear pada loading indicator
  Widget _buildLoadingDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 0.8),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
