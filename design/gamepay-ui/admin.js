// หน้าผู้ดูแล คำสั่งซื้อ แพ็กเกจ และปรับแต้ม
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function adminHeader(title) {
  const successful = state.orders.filter((order) => order.status === "success");
  const stats =
    title === "รายการคำสั่งซื้อ"
      ? '<div class="stats"><div><small>ทั้งหมด</small><strong>' +
        state.orders.length +
        "</strong></div><div><small>สำเร็จ</small><strong>" +
        successful.length +
        "</strong></div><div><small>ยอดสำเร็จ</small><strong>" +
        shortMoney(successful.reduce((sum, order) => sum + order.total, 0)) +
        "</strong></div></div>"
      : "";
  return (
    '<header class="admin-header"><div class="row between"><div><small>GamePay Admin</small><h2>' +
    title +
    '</h2></div><button class="icon-button" data-go="home" aria-label="กลับหน้าลูกค้า">' +
    icon("logout") +
    "</button></div>" +
    stats +
    "</header>"
  );
}

function adminPage() {
  return (
    '<div class="screen">' +
    adminHeader("รายการคำสั่งซื้อ") +
    '<div class="pad">' +
    searchBox("admin-search", "ค้นหาเลขออร์เดอร์ หรือ UID") +
    '<div class="section-heading"><h3>คำสั่งซื้อทั้งหมด</h3><span class="tiny muted">' +
    state.orders.length +
    ' รายการ</span></div><div id="admin-orders">' +
    state.orders.map((order) => orderCard(order, true)).join("") +
    "</div></div></div>" +
    bottomNav(true)
  );
}

function catalogPage() {
  const game = getGame(state.adminGame);
  return (
    '<div class="screen">' +
    adminHeader("จัดการเกม & แพ็กเกจ") +
    '<div class="pad"><label class="field" style="margin-top:0">เลือกเกม<select id="admin-game">' +
    games
      .map(
        (item) =>
          '<option value="' +
          item.id +
          '" ' +
          (item.id === game.id ? "selected" : "") +
          ">" +
          item.name +
          "</option>",
      )
      .join("") +
    '</select></label><div class="section-heading"><h3>แพ็กเกจของ ' +
    game.name +
    '</h3><span class="tiny muted">' +
    game.packs.length +
    ' แพ็กเกจ</span></div><div class="card">' +
    game.packs
      .map(
        ([quantity, price], i) =>
          '<div class="admin-package row"><div class="grow"><strong>' +
          number(quantity) +
          " " +
          game.unit +
          "</strong><small>ราคา " +
          shortMoney(price) +
          " · +" +
          Math.floor(price / 10) +
          " แต้ม</small>" +
          (game.disabled?.includes(i)
            ? '<span class="badge cancelled">ปิดขาย</span>'
            : "") +
          '</div><button class="icon-button" data-edit-package="' +
          i +
          '" aria-label="แก้ไขแพ็กเกจ ' +
          quantity +
          '">' +
          icon("edit") +
          '</button><button class="icon-button" data-toggle-package="' +
          i +
          '" aria-label="' +
          (game.disabled?.includes(i) ? "เปิด" : "ปิด") +
          "ขายแพ็กเกจ " +
          quantity +
          '">' +
          icon(game.disabled?.includes(i) ? "check" : "close") +
          "</button></div>",
      )
      .join("") +
    '<button class="add-package" data-action="add-package">+ เพิ่มแพ็กเกจใหม่</button></div><p class="hint">ปิดขายเพื่อหยุดรับคำสั่งซื้อแพ็กเกจนั้น<br>รายการซื้อเดิมยังคงอยู่ในประวัติ</p></div></div>' +
    bottomNav(true)
  );
}

function usersPage() {
  return (
    '<div class="screen">' +
    adminHeader("ผู้ใช้ & แต้มสะสม") +
    '<div class="pad"><div class="card"><div class="row"><span class="avatar">B</span><div><h3>' +
    escapeText(state.user) +
    '</h3><small class="muted">bas@example.com</small></div></div><hr class="divider"><div class="row between"><span class="tiny">แต้มสะสมปัจจุบัน</span><strong class="red">' +
    number(state.points) +
    ' แต้ม</strong></div></div><form id="points-form"><label class="field">จำนวนแต้มที่ปรับ<input type="number" name="amount" step="1" placeholder="เช่น 100 หรือ -50" required></label><label class="field">เหตุผลในการปรับ<input name="reason" placeholder="ระบุเหตุผลที่ตรวจสอบได้" required minlength="3"></label><p class="hint">ค่าบวกคือเพิ่มแต้ม ค่าลบคือลดแต้ม</p><p id="points-error" class="error" role="alert"></p><button class="primary full" style="margin-top:20px" type="submit">ตรวจสอบการปรับแต้ม</button></form><div class="section-heading"><h3>ความเคลื่อนไหวล่าสุด</h3></div><div class="card ledger">' +
    state.ledger
      .slice(0, 5)
      .map(
        (item) =>
          '<div class="row"><span>' +
          escapeText(item.label) +
          "<small>" +
          escapeText(item.detail) +
          '</small></span><b class="value ' +
          (item.value > 0 ? "green" : "red") +
          '">' +
          (item.value > 0 ? "+" : "") +
          item.value +
          "</b></div>",
      )
      .join("") +
    "</div></div></div>" +
    bottomNav(true)
  );
}

// 4. การเปลี่ยนหน้าและการโต้ตอบ

function packageForm(index) {
  const game = getGame(state.adminGame),
    pack = index === null ? ["", ""] : game.packs[index];
  showModal(
    "<h2>" +
      (index === null ? "เพิ่ม" : "แก้ไข") +
      "แพ็กเกจ</h2><p>" +
      game.name +
      '</p><form id="package-form" data-index="' +
      (index === null ? "new" : index) +
      '"><label class="field">จำนวน ' +
      game.unit +
      '<input type="number" name="quantity" value="' +
      pack[0] +
      '" min="1" step="1" required></label><label class="field">ราคาขาย (บาท)<input type="number" name="price" value="' +
      pack[1] +
      '" min="1" step="0.01" required></label><button class="primary" type="submit">บันทึกแพ็กเกจ</button><button type="button" class="secondary" data-action="close-modal">ยกเลิก</button></form>',
  );
}
