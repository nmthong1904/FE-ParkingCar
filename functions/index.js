const {setGlobalOptions} = require("firebase-functions");

const {onRequest} = require("firebase-functions/https");

const logger = require("firebase-functions/logger");



// For cost control, you can set the maximum number of containers that can be

// running at the same time. This helps mitigate the impact of unexpected

// traffic spikes by instead downgrading performance. This limit is a

// per-function limit. You can override the limit for each function using the

// `maxInstances` option in the function's options, e.g.

// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.

// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1

// functions should each use functions.runWith({ maxInstances: 10 }) instead.

// In the v1 API, each function can only serve one request per container, so

// this will be the maximum concurrent request count.

setGlobalOptions({ maxInstances: 10 });

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Cấu hình Email (Sử dụng App Password 16 ký tự)
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'thongn1414@gmail.com',
        pass: 'psxe mjpy qngh qorg' // Đảm bảo đây là Mật khẩu ứng dụng, không phải mật khẩu Gmail
    }
});

// 1. Hàm tạo và gửi OTP
// exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
//   const email = data.email;

//   if (!email) {
//     throw new functions.https.HttpsError('invalid-argument', 'Email không được để trống');
//   }

//   const otp = Math.floor(100000 + Math.random() * 900000).toString();
//   const isEmulator = process.env.FUNCTIONS_EMULATOR === 'true';

//   try {
//     // 1. Lưu OTP vào Firestore (GIỮ NGUYÊN)
//     await admin.firestore().collection('otp_codes').doc(email).set({
//       code: otp,
//       expiresAt: admin.firestore.Timestamp.fromDate(
//         new Date(Date.now() + 5 * 60000)
//       )
//     });

//     // 2. NẾU LÀ EMULATOR → KHÔNG GỬI MAIL
//     if (isEmulator) {
//       console.log(`🔐 [DEV OTP] ${email}: ${otp}`);
//       return { success: true, devOtp: otp };
//     }

//     // 3. PRODUCTION → GỬI EMAIL THẬT
//     const mailOptions = {
//       from: '"Parking Car Support" <thongn1414@gmail.com>',
//       to: email,
//       subject: 'Mã OTP xác thực tài khoản',
//       html: `
//         <h3>Xác thực tài khoản Parking Car</h3>
//         <p>Mã OTP của bạn là: <b>${otp}</b></p>
//         <p>Mã này có hiệu lực trong 5 phút.</p>
//       `
//     };

//     await transporter.sendMail(mailOptions);

//     return { success: true };
//   } catch (error) {
//     console.error("Lỗi gửi mail:", error);
//     throw new functions.https.HttpsError('internal', error.message);
//   }
// });

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const isEmulator = process.env.FUNCTIONS_EMULATOR === 'true';

  // Lưu vào Firestore để verify sau này
  await admin.firestore().collection('otp_codes').doc(email).set({
    code: otp,
    expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 5 * 60000))
  });

  if (isEmulator) {
    // KHI DÙNG EMULATOR: Hiện mã cực to ở Terminal để copy
    console.log("\n--- [LOCAL DEBUG OTP] ---");
    console.log(`EMAIL: ${email}`);
    console.log(`CODE: ${otp}`);
    console.log("--------------------------\n");
    return { success: true, debugOtp: otp }; // Trả về luôn để app tự điền nếu muốn
  }

});

// 2. Hàm kiểm tra OTP
exports.verifyOtpCode = functions.https.onCall(async (data, context) => {
    const { email, otp } = data;

    if (!email || !otp) {
        return { success: false, message: 'Thiếu thông tin xác thực' };
    }

    try {
        const doc = await admin.firestore().collection('otp_codes').doc(email).get();

        if (!doc.exists) {
            return { success: false, message: 'Mã OTP không tồn tại hoặc đã hết hạn' };
        }

        const dataOtp = doc.data();
        const now = new Date();

        // Kiểm tra mã và thời gian hết hạn
        if (dataOtp.code === otp && dataOtp.expiresAt.toDate() > now) {
            // Xóa mã sau khi dùng thành công
            await admin.firestore().collection('otp_codes').doc(email).delete();
            return { success: true };
        }

        return { success: false, message: 'Mã OTP không chính xác hoặc đã hết hạn' };
    } catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
