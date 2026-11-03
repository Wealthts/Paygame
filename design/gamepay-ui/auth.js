// หน้าโปรไฟล์ เข้าสู่ระบบ และสมัครสมาชิก
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function profilePage() {
  return (
    '<div class="screen"><div class="profile-header"><span class="avatar">B</span><h2>' +
    escapeText(state.user) +
    '</h2><p class="tiny muted">bas@example.com</p><span class="tag">สมาชิก</span></div><div class="pad"><div class="card"><div class="row between"><span>แต้มสะสมของคุณ</span><strong class="red">' +
    number(state.points) +
    " แต้ม</strong></div></div>" +
    [
      ["history", "receipt", "ประวัติการเติมเงิน"],
      ["rewards", "gift", "แต้มและรางวัล"],
    ]
      .map(
        ([page, symbol, label]) =>
          '<button class="profile-item" data-go="' +
          page +
          '">' +
          icon(symbol) +
          label +
          icon("next") +
          "</button>",
      )
      .join("") +
    '<button class="profile-item" data-action="support">' +
    icon("help") +
    "ศูนย์ช่วยเหลือ" +
    icon("next") +
    '</button><button class="profile-item" data-action="logout">' +
    icon("logout") +
    "ออกจากระบบ" +
    icon("next") +
    '</button><div class="notice" style="margin-top:22px">' +
    icon("shield") +
    "<span>บัญชีตัวอย่างสำหรับทดลองใช้งาน<br>ข้อมูลจะเริ่มใหม่เมื่อรีเฟรชหน้า</span></div></div></div>" +
    bottomNav()
  );
}

function loginPage() {
  return (
    '<div class="screen"><div class="auth-hero"><small>เติมไว เล่นต่อได้เลย</small><br>' +
    brand() +
    '<h2>ทุกเกมโปรด<br>เริ่มความสนุกได้ที่นี่</h2></div><div class="auth-content"><h2>ยินดีต้อนรับกลับมา</h2><p class="hint">เข้าสู่ระบบเพื่อเติมเกมและสะสมแต้ม</p><form id="login-form"><label class="field">ชื่อผู้ใช้<input name="username" placeholder="ชื่อผู้ใช้ของคุณ" autocomplete="username" required></label><label class="field">รหัสผ่าน<input name="password" type="password" placeholder="กรอกรหัสผ่าน" autocomplete="current-password" required minlength="8"></label><div class="align-right"><button type="button" class="text-button" data-action="forgot">ลืมรหัสผ่าน?</button></div><button class="primary full" type="submit">เข้าสู่ระบบ ' +
    icon("next") +
    '</button></form><div class="auth-footer">ยังไม่มีบัญชี? ' +
    goButton("register", "สมัครสมาชิก") +
    '</div><p class="demo-note">โหมดตัวอย่าง: ใช้ชื่อใดก็ได้ และรหัสผ่าน 8 ตัวขึ้นไป<br>ไม่มีการส่งหรือบันทึกรหัสผ่าน</p>' +
    goButton("home", "ลองใช้งานก่อนเข้าสู่ระบบ", "text-button full") +
    "</div></div>"
  );
}

function registerPage() {
  return (
    topbar("สร้างบัญชีใหม่", "login") +
    '<div class="screen"><div class="auth-content"><h2>เริ่มสนุกกับ GamePay</h2><p class="hint">สร้างบัญชีเพื่อเก็บประวัติและสะสมแต้ม</p><form id="register-form"><label class="field">ชื่อผู้ใช้<input name="username" placeholder="ชื่อที่ต้องการใช้" required minlength="3" autocomplete="username"></label><label class="field">อีเมล<input name="email" type="email" placeholder="you@example.com" required autocomplete="email"></label><label class="field">เบอร์โทรศัพท์<input name="phone" type="tel" placeholder="08XXXXXXXX" pattern="0[0-9]{9}" required autocomplete="tel"></label><label class="field">รหัสผ่าน<input name="password" type="password" placeholder="อย่างน้อย 8 ตัวอักษร" minlength="8" required autocomplete="new-password"></label><label class="field">ยืนยันรหัสผ่าน<input name="confirm" type="password" placeholder="กรอกรหัสผ่านอีกครั้ง" required autocomplete="new-password"></label><p id="register-error" class="error" role="alert"></p><label class="auth-check"><input name="terms" type="checkbox" required><span>ยอมรับ <button type="button" class="text-button" data-action="terms">เงื่อนไขการใช้งาน</button></span></label><button class="primary full" type="submit">สมัครสมาชิก</button></form><div class="auth-footer">มีบัญชีแล้ว? ' +
    goButton("login", "เข้าสู่ระบบ") +
    '</div><p class="demo-note">ฟอร์มตัวอย่าง ไม่มีการสร้างบัญชีจริง</p></div></div>'
  );
}
