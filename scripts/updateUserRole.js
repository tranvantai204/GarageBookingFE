// Script để cập nhật vai trò user trong database production
const mongoose = require('mongoose');

// Kết nối tới database production (MongoDB Atlas)
const MONGO_URI = 'mongodb+srv://ryan24:ryan24@cluster0.z0zba9e.mongodb.net/haphuonggarage?retryWrites=true&w=majority';

// User schema
const userSchema = new mongoose.Schema({
  hoTen: { type: String, required: true },
  soDienThoai: { type: String, required: true, unique: true },
  matKhau: { type: String, required: true, select: false },
  vaiTro: { type: String, enum: ['user', 'admin'], default: 'user' },
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

const updateUserRole = async () => {
  try {
    // Kết nối database
    await mongoose.connect(MONGO_URI);
    console.log('Đã kết nối MongoDB Atlas');

    // Tìm user với số điện thoại admin
    const adminPhone = '0123456789';
    const user = await User.findOne({ soDienThoai: adminPhone });
    
    if (user) {
      console.log('Tìm thấy user:', user.hoTen, user.soDienThoai);
      console.log('Vai trò hiện tại:', user.vaiTro);
      
      // Cập nhật vai trò thành admin
      user.vaiTro = 'admin';
      await user.save();
      
      console.log('✅ Đã cập nhật vai trò thành admin');
    } else {
      console.log('❌ Không tìm thấy user với số điện thoại:', adminPhone);
      
      // Liệt kê tất cả users
      const allUsers = await User.find({}).select('hoTen soDienThoai vaiTro');
      console.log('\n📋 Danh sách tất cả users:');
      allUsers.forEach(u => {
        console.log(`- ${u.hoTen} (${u.soDienThoai}) - ${u.vaiTro}`);
      });
    }

    // Kiểm tra lại
    const updatedUser = await User.findOne({ soDienThoai: adminPhone });
    if (updatedUser) {
      console.log('\n🔍 Kiểm tra lại:');
      console.log(`User: ${updatedUser.hoTen}`);
      console.log(`Phone: ${updatedUser.soDienThoai}`);
      console.log(`Role: ${updatedUser.vaiTro}`);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    process.exit(1);
  }
};

updateUserRole();
