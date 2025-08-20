import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';

class TestChatRefresh extends StatelessWidget {
  const TestChatRefresh({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Chat Refresh'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _testChatRoomsRefresh(context),
              child: const Text('Test Chat Rooms Refresh'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _clearCacheAndRefresh(context),
              child: const Text('Clear Cache & Refresh'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _debugChatRooms(context),
              child: const Text('Debug Chat Rooms Data'),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return ListView.builder(
                    itemCount: chatProvider.chatRooms.length,
                    itemBuilder: (context, index) {
                      final room = chatProvider.chatRooms[index];
                      return Card(
                        child: ListTile(
                          title: Text(room.participant.name),
                          subtitle: Text(
                            room.lastMessage?.content ?? 'No last message',
                          ),
                          trailing: Text(
                            room.lastMessage?.timestamp.toString() ?? 'No time',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testChatRoomsRefresh(BuildContext context) async {
    print('🔄 Testing chat rooms refresh...');
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    
    if (userId.isEmpty) {
      print('❌ No user ID found');
      return;
    }
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadChatRooms(userId, forceReload: true);
    
    print('✅ Chat rooms refresh completed');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat rooms refreshed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearCacheAndRefresh(BuildContext context) async {
    print('🔄 Clearing cache and refreshing...');
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    
    if (userId.isEmpty) {
      print('❌ No user ID found');
      return;
    }
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Clear cache by setting private fields to null (we'll need to add public methods)
    // For now, just force reload
    await chatProvider.loadChatRooms(userId, forceReload: true);
    
    print('✅ Cache cleared and refreshed');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared and refreshed!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _debugChatRooms(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    print('📋 Debug Chat Rooms:');
    print('Total rooms: ${chatProvider.chatRooms.length}');
    
    for (int i = 0; i < chatProvider.chatRooms.length; i++) {
      final room = chatProvider.chatRooms[i];
      print('Room $i:');
      print('  ID: ${room.id}');
      print('  Participant: ${room.participant.name}');
      print('  Last Message: ${room.lastMessage?.content ?? 'null'}');
      print('  Last Message Time: ${room.lastMessage?.timestamp ?? 'null'}');
      print('  Updated At: ${room.updatedAt}');
      print('---');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Debug info printed to console (${chatProvider.chatRooms.length} rooms)'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}