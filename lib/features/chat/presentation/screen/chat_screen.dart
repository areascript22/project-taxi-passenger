import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../shared/chat_presence/service/chat_presence_tracker.dart';
import '../../domain/entity/chat_message_entity.dart';
import '../bloc/chat_bloc.dart';

// Args tipados para la ruta de go_router (evita pasar un Map suelto por
// `state.extra`) -- mismo espíritu que otras rutas del proyecto que reciben
// una entity tipada.
class ChatScreenArgs {
  const ChatScreenArgs({required this.rideId, required this.passengerId});

  final String rideId;
  final String passengerId;
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.rideId, required this.passengerId});

  final String rideId;
  final String passengerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<ChatBloc>(),
      child: _ChatView(rideId: rideId, passengerId: passengerId),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.rideId, required this.passengerId});

  final String rideId;
  final String passengerId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  late final ChatBloc _chatBloc;
  final TextEditingController _textController = TextEditingController();
  final ChatPresenceTracker _presenceTracker =
      GetIt.instance<ChatPresenceTracker>();

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _presenceTracker.markOpen(rideId: widget.rideId);
    _chatBloc.add(MarkMessagesRead());
  }

  @override
  void dispose() {
    _presenceTracker.markClosed(rideId: widget.rideId);
    _textController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _chatBloc.add(SendMessage(passengerId: widget.passengerId, text: text));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat con tu conductor')),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return const Center(child: Text('Todavía no hay mensajes'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        state.messages[state.messages.length - 1 - index];
                    return _MessageBubble(
                      message: message,
                      isMine: message.senderRole == 'passenger',
                    );
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.errorMessage == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      return IconButton.filled(
                        onPressed: state.isSending ? null : _onSend,
                        icon: const Icon(Icons.send_rounded),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessageEntity message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMine ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: (isMine ? colorScheme.onPrimary : colorScheme.onSurface)
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
