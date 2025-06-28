// Script để tạo tài khoản admin
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

// User model
const userSchema = new mongoose.Schema({
  hoTen: { type: String, required: true },
  soDienThoai: { type: String, required: true, unique: true },
  matKhau: { type: String, required: true, select: false },
  vaiTro: { type: String, enum: ['user', 'admin'], default: 'user' },
}, { timestamps: true });

userSchema.pre('save', async function (next) {
  if (!this.isModified('matKhau')) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.matKhau = await bcrypt.hash(this.matKhau, salt);
});

const User = mongoose.model('User', userSchema);

const createAdmin = async () => {
  try {
    // Kết nối database
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Đã kết nối MongoDB');

    // Kiểm tra xem admin đã tồn tại chưa
    const existingAdmin = await User.findOne({ soDienThoai: '0123456789' });
    if (existingAdmin) {
      console.log('Tài khoản admin đã tồn tại');
      
      // Cập nhật vai trò thành admin nếu chưa phải
      if (existingAdmin.vaiTro !== 'admin') {
        existingAdmin.vaiTro = 'admin';
        await existingAdmin.save();
        console.log('Đã cập nhật vai trò thành admin');
      }
    } else {
      // Tạo tài khoản admin mới
      const admin = await User.create({
        hoTen: 'Admin Hà Phương',
        soDienThoai: '0123456789',
        matKhau: 'admin123',
        vaiTro: 'admin'
      });
      console.log('Đã tạo tài khoản admin:', admin.hoTen);
    }

    // Kiểm tra và tạo tài khoản user test
    const existingUser = await User.findOne({ soDienThoai: '0987654321' });
    if (!existingUser) {
      const user = await User.create({
        hoTen: 'User Test',
        soDienThoai: '0987654321',
        matKhau: 'user123',
        vaiTro: 'user'
      });
      console.log('Đã tạo tài khoản user test:', user.hoTen);
    } else {
      console.log('Tài khoản user test đã tồn tại');
    }

    console.log('\n=== THÔNG TIN TÀI KHOẢN TEST ===');
    console.log('ADMIN:');
    console.log('  Số điện thoại: 0123456789');
    console.log('  Mật khẩu: admin123');
    console.log('  Quyền: Tạo chuyến đi, quản lý hệ thống');
    console.log('\nUSER:');
    console.log('  Số điện thoại: 0987654321');
    console.log('  Mật khẩu: user123');
    console.log('  Quyền: Xem chuyến đi, đặt vé');

    process.exit(0);
  } catch (error) {
    console.error('Lỗi:', error.message);
    process.exit(1);
  }
};

createAdmin();
