// Script để tạo chuyến đi mẫu
require('dotenv').config();
const mongoose = require('mongoose');
const Trip = require('./models/Trip');

const createSampleTrip = async () => {
    try {
        // Kết nối MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB đã kết nối');

        // Tạo chuyến đi mẫu Hà Nội - Sapa
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(8, 0, 0, 0); // 8:00 AM

        const trip1 = await Trip.create({
            nhaXe: "Hà Phương",
            diemDi: "Hà Nội",
            diemDen: "Sapa",
            thoiGianKhoiHanh: tomorrow,
            soGhe: 16,
            danhSachGhe: Array.from({length: 16}, (_, i) => ({
                tenGhe: `A${i + 1}`,
                trangThai: 'trong',
                giaVe: 250000
            })),
            taiXe: "Nguyễn Văn Tài",
            bienSoXe: "30A-12345"
        });

        console.log('Đã tạo chuyến đi Hà Nội - Sapa:', trip1._id);

        // Tạo chuyến đi mẫu Hà Nội - Đà Nẵng
        const trip2 = await Trip.create({
            nhaXe: "Hà Phương", 
            diemDi: "Hà Nội",
            diemDen: "Đà Nẵng",
            thoiGianKhoiHanh: new Date(tomorrow.getTime() + 2 * 60 * 60 * 1000), // 10:00 AM
            soGhe: 20,
            danhSachGhe: Array.from({length: 20}, (_, i) => ({
                tenGhe: `B${i + 1}`,
                trangThai: 'trong',
                giaVe: 350000
            })),
            taiXe: "Trần Văn Nam",
            bienSoXe: "30A-67890"
        });

        console.log('Đã tạo chuyến đi Hà Nội - Đà Nẵng:', trip2._id);

        process.exit(0);
    } catch (error) {
        console.error('Lỗi:', error);
        process.exit(1);
    }
};

createSampleTrip();
