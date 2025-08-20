// File: scripts/createSampleChats.js

const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');

async function createSampleChats() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    // Get all users
    const users = await User.find({}).select('_id hoTen vaiTro');
    console.log(`📋 Found ${users.length} users`);
    
    if (users.length < 2) {
      console.log('❌ Need at least 2 users to create chats');
      return;
    }

    // Find admin user (current user)
    const adminUser = users.find(u => u.vaiTro === 'admin');
    if (!adminUser) {
      console.log('❌ No admin user found');
      return;
    }

    console.log(`👤 Admin user: ${adminUser.hoTen} (${adminUser._id})`);

    // Create chats between admin and other users
    for (const otherUser of users) {
      if (otherUser._id.toString() === adminUser._id.toString()) {
        continue; // Skip self
      }

      console.log(`\n🔄 Creating chat between ${adminUser.hoTen} and ${otherUser.hoTen}...`);

      // Check if chat already exists
      const existingChat = await Chat.findOne({
        'participants.userId': { $all: [adminUser._id, otherUser._id] },
        isActive: true
      });

      if (existingChat) {
        console.log(`⚠️ Chat already exists: ${existingChat._id}`);
        continue;
      }

      // Create new chat
      const newChat = new Chat({
        participants: [
          {
            userId: adminUser._id,
            name: adminUser.hoTen,
            role: adminUser.vaiTro
          },
          {
            userId: otherUser._id,
            name: otherUser.hoTen,
            role: otherUser.vaiTro
          }
        ],
        unreadCount: new Map([
          [adminUser._id.toString(), 0],
          [otherUser._id.toString(), 0]
        ]),
        isActive: true
      });

      await newChat.save();
      console.log(`✅ Created chat: ${newChat._id}`);

      // Create sample messages
      const sampleMessages = [
        {
          senderId: adminUser._id,
          senderName: adminUser.hoTen,
          senderRole: adminUser.vaiTro,
          content: `Xin chào ${otherUser.hoTen}! Tôi là ${adminUser.hoTen}.`,
        },
        {
          senderId: otherUser._id,
          senderName: otherUser.hoTen,
          senderRole: otherUser.vaiTro,
          content: `Chào ${adminUser.hoTen}! Rất vui được nói chuyện với bạn.`,
        },
        {
          senderId: adminUser._id,
          senderName: adminUser.hoTen,
          senderRole: adminUser.vaiTro,
          content: 'Có gì cần hỗ trợ không?',
        }
      ];

      for (let i = 0; i < sampleMessages.length; i++) {
        const msgData = sampleMessages[i];
        const message = new Message({
          chatId: newChat._id,
          senderId: msgData.senderId,
          senderName: msgData.senderName,
          senderRole: msgData.senderRole,
          content: msgData.content,
          messageType: 'text',
          readBy: [{
            userId: msgData.senderId,
            readAt: new Date()
          }],
          createdAt: new Date(Date.now() + i * 60000) // 1 minute apart
        });

        await message.save();
        console.log(`  💬 Created message: "${msgData.content}"`);
      }

      // Update chat with last message
      const lastMessage = sampleMessages[sampleMessages.length - 1];
      await Chat.updateOne(
        { _id: newChat._id },
        {
          $set: {
            lastMessage: {
              content: lastMessage.content,
              senderId: lastMessage.senderId,
              senderName: lastMessage.senderName,
              timestamp: new Date(),
              messageType: 'text'
            },
            updatedAt: new Date()
          }
        }
      );

      console.log(`✅ Updated chat with last message`);
    }

    // Show summary
    const totalChats = await Chat.countDocuments({ isActive: true });
    const totalMessages = await Message.countDocuments({});
    
    console.log(`\n📊 Summary:`);
    console.log(`  - Total chats: ${totalChats}`);
    console.log(`  - Total messages: ${totalMessages}`);
    console.log(`\n🎉 Sample chats created successfully!`);

  } catch (error) {
    console.error('❌ Error creating sample chats:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the script
createSampleChats();
