// คำนวณยอด หน้าชำระเงิน และผลชำระเงินจำลอง
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function totals() {
  const price = getPack()[1];
  const discount =
    state.discount && state.points >= 100 ? Math.min(10, price) : 0;
  const rate = { qr: 0, wallet: 0.01, card: 0.025 }[state.payment];
  const fee = Math.round((price - discount) * rate * 100) / 100;
  const total = Math.round((price - discount + fee) * 100) / 100;
  return {
    price,
    discount,
    fee,
    total,
    earned: Math.floor((price - discount) / 10),
  };
}

function bill(data) {
  return (
    '<div class="bill"><div><span>ราคาแพ็กเกจ</span><span>' +
    money(data.price) +
    '</span></div><div><span>ส่วนลดจากแต้ม</span><span class="red">−' +
    money(data.discount) +
    "</span></div><div><span>ค่าธรรมเนียม</span><span>" +
    money(data.fee) +
    '</span></div><div class="total"><span>ยอดสุทธิ</span><span>' +
    money(data.total) +
    "</span></div></div>"
  );
}

// 3. หน้าจอ — แต่ละฟังก์ชันคืน HTML ของหนึ่งหน้า

function checkoutPage() {
  const game = getGame(),
    pack = getPack(),
    data = totals();
  return (
    topbar("ตรวจสอบและชำระเงิน", "packages") +
    steps(3) +
    '<div class="screen"><div class="pad"><div class="card"><div class="row checkout-game">' +
    mini(state.game) +
    '<div class="grow"><strong>' +
    game.name +
    " · " +
    number(pack[0]) +
    " " +
    game.unit +
    '</strong><p class="tiny muted">UID: ' +
    escapeText(state.uid) +
    (game.server ? " / " + escapeText(state.server) : "") +
    "</p></div>" +
    goButton("packages", "แก้ไข") +
    '</div><label class="discount-row"><span class="discount-symbol">' +
    icon("coin") +
    '</span><span><strong class="tiny">ใช้ 100 แต้ม ลด ฿10</strong><br><small class="muted">มี ' +
    number(state.points) +
    ' แต้ม</small></span><input id="discount" type="checkbox" aria-label="ใช้ 100 แต้ม เป็นส่วนลด 10 บาท" ' +
    (state.discount ? "checked" : "") +
    " " +
    (state.points < 100 ? "disabled" : "") +
    '></label></div><div class="section-heading"><h3>ช่องทางชำระเงิน</h3></div>' +
    [
      ["qr", "qr", "ไม่มีค่าธรรมเนียม"],
      ["wallet", "wallet", "ค่าธรรมเนียม 1%"],
      ["card", "card", "ค่าธรรมเนียม 2.5%"],
    ]
      .map(
        ([id, symbol, fee]) =>
          '<label class="payment-option">' +
          icon(symbol) +
          '<span><strong class="tiny">' +
          paymentNames[id] +
          "</strong><small>" +
          fee +
          '</small></span><input type="radio" name="payment" value="' +
          id +
          '" ' +
          (state.payment === id ? "checked" : "") +
          "></label>",
      )
      .join("") +
    '<div class="card" style="margin-top:17px">' +
    bill(data) +
    '<div class="reward-inline">รับ +' +
    data.earned +
    ' แต้ม เมื่อเติมสำเร็จ</div></div><div class="notice" style="margin-top:13px">' +
    icon("lock") +
    '<span>นี่คือการชำระเงินจำลอง ไม่มีการหักเงินจริง</span></div></div></div><div class="bottom-action"><button class="primary full" data-action="pay">ยืนยันชำระเงิน ' +
    shortMoney(data.total) +
    "</button></div>"
  );
}

function createPendingOrder() {
  if (state.currentOrder?.status === "pending") return state.currentOrder;
  const data = totals();
  const order = {
    ...data,
    id:
      "GP-" +
      String(
        44 +
          state.orders.filter(
            (item) =>
              item.id.startsWith("GP-") && Number(item.id.slice(3)) >= 44,
          ).length,
      ).padStart(4, "0"),
    game: state.game,
    quantity: getPack()[0],
    uid: state.uid,
    server: state.server,
    payment: state.payment,
    status: "pending",
    date: new Intl.DateTimeFormat("th-TH", {
      timeZone: "Asia/Bangkok",
      day: "numeric",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(new Date()),
  };
  state.orders.unshift(order);
  state.currentOrder = order;
  return order;
}

function confirmPayment() {
  const data = totals();
  showModal(
    "<h2>ยืนยันบัญชีที่จะเติม</h2><p>" +
      getGame().name +
      " · " +
      number(getPack()[0]) +
      " " +
      getGame().unit +
      "<br>UID <b>" +
      escapeText(state.uid) +
      "</b><br>ยอดชำระ <b>" +
      money(data.total) +
      '</b></p><div class="notice">นี่คือการทดลองชำระเงิน เลือกผลลัพธ์เพื่อดูหน้าจอถัดไป</div><button class="primary" data-action="payment-success">จำลองชำระสำเร็จ</button><button class="secondary" data-action="payment-fail">จำลองชำระไม่สำเร็จ</button><button class="text-button full" data-action="close-modal">กลับไปตรวจสอบ</button>',
  );
}

function finishPayment(success) {
  const order = createPendingOrder();
  if (order.status !== "pending") return;
  const data = totals();
  Object.assign(order, data, { payment: state.payment });
  modal.close();
  if (!success) {
    order.status = "failed";
    navigate("history");
    info(
      "ชำระเงินไม่สำเร็จ",
      "ไม่มีการหักเงินหรือแต้ม คุณสามารถเลือกแพ็กเกจแล้วลองทำรายการใหม่ได้",
    );
    return;
  }
  order.status = "success";
  if (data.discount) {
    state.points -= 100;
    state.ledger.unshift({
      label: "ใช้แต้มเป็นส่วนลด",
      detail: order.id,
      value: -100,
    });
  }
  state.points += data.earned;
  order.balance = state.points;
  state.ledger.unshift({
    label: "เติม " + getGame().name,
    detail: order.id,
    value: data.earned,
  });
  state.currentOrder = order;
  navigate("history");
  info(
    "เติมเกมสำเร็จ!",
    "คำสั่งซื้อ " +
      order.id +
      "<br>เติมให้ UID " +
      escapeText(order.uid) +
      " แล้ว<br>ดูรายละเอียดได้ในประวัติการเติมเงิน",
    true,
  );
}
