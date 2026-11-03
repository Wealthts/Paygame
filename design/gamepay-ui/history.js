// หน้าประวัติ รายละเอียดคำสั่งซื้อ และชำระต่อ
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function orderCard(order, admin = false) {
  const game = getGame(order.game);
  return (
    '<article class="order"><button class="order-link" data-order="' +
    order.id +
    '" aria-label="ดูคำสั่งซื้อ ' +
    order.id +
    '"><div class="row">' +
    mini(order.game) +
    '<div class="grow"><div class="order-title">' +
    game.name +
    " · " +
    number(order.quantity) +
    " " +
    game.unit +
    '</div><div class="order-meta">' +
    order.id +
    " · " +
    order.date.split(" · ")[0] +
    '</div></div><div class="align-right"><strong class="tiny">' +
    shortMoney(order.total) +
    "</strong><br>" +
    badge(order.status) +
    "</div></div></button>" +
    (order.status === "pending" && !admin
      ? '<div class="actions"><button class="secondary" data-cancel="' +
        order.id +
        '">ยกเลิก</button><button class="primary" data-resume="' +
        order.id +
        '">ชำระต่อ</button></div>'
      : "") +
    "</article>"
  );
}

function historyPage() {
  return (
    '<div class="screen"><header class="page-heading"><h2>ประวัติการเติมเงิน</h2><p>ดูสถานะและรายละเอียดคำสั่งซื้อได้ที่นี่</p><div class="stats"><div><small>ยอดเติมสำเร็จทั้งหมด</small><strong>' +
    shortMoney(
      state.orders
        .filter((item) => item.status === "success")
        .reduce((sum, item) => sum + item.total, 0),
    ) +
    "</strong></div><div><small>คำสั่งซื้อทั้งหมด</small><strong>" +
    state.orders.length +
    ' <span class="tiny">รายการ</span></strong></div></div></header><div class="pad"><div class="chip-row">' +
    ["ทั้งหมด", "สำเร็จ", "รอชำระ", "ล้มเหลว"]
      .map(
        (label) =>
          '<button class="chip ' +
          (state.historyFilter === label ? "selected" : "") +
          '" data-filter="' +
          label +
          '" aria-pressed="' +
          (state.historyFilter === label) +
          '">' +
          label +
          "</button>",
      )
      .join("") +
    "</div>" +
    historyList() +
    "</div></div>" +
    bottomNav()
  );
}

function historyList() {
  const orders = state.orders.filter(
    (order) =>
      state.historyFilter === "ทั้งหมด" ||
      labelStatus(order.status) === state.historyFilter,
  );
  return orders.length
    ? orders.map((order) => orderCard(order)).join("")
    : '<div class="empty">' +
        icon("receipt") +
        "<strong>ยังไม่มีประวัติในรายการนี้</strong><small>เมื่อทำรายการเติมเกม ประวัติจะแสดงที่นี่</small></div>";
}

function viewOrder(id) {
  const order = state.orders.find((item) => item.id === id);
  info(
    "คำสั่งซื้อ " + escapeText(order.id),
    getGame(order.game).name +
      " · " +
      number(order.quantity) +
      " " +
      getGame(order.game).unit +
      "<br>UID " +
      escapeText(order.uid) +
      "<br>ยอด " +
      money(order.total) +
      "<br>สถานะ: " +
      labelStatus(order.status),
    order.status === "success",
  );
}

function resumeOrder(id) {
  const order = state.orders.find((item) => item.id === id);
  state.game = order.game;
  state.package = getGame().packs.findIndex(
    (pack) => pack[0] === order.quantity,
  );
  if (state.package < 0 || getGame().disabled?.includes(state.package)) {
    info(
      "แพ็กเกจนี้ไม่เปิดขายแล้ว",
      "กรุณายกเลิกคำสั่งซื้อเดิม และเลือกแพ็กเกจใหม่",
    );
    return;
  }
  state.uid = order.uid;
  state.server = order.server || "Asia";
  state.payment = order.payment;
  state.discount = order.discount > 0 && state.points >= 100;
  state.currentOrder = order;
  navigate("checkout");
}
