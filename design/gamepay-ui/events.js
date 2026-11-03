// รับการคลิก การกรอกข้อมูล และส่งฟอร์ม แล้วเรียกฟังก์ชันในไฟล์แต่ละส่วน

document.addEventListener("click", function (event) {
  const button = event.target.closest("button");
  if (!button) return;
  if (button.dataset.go) {
    navigate(button.dataset.go);
    return;
  }
  if (button.dataset.preview) {
    preview(button.dataset.preview);
    return;
  }
  if (button.dataset.game) {
    chooseGame(button.dataset.game);
    return;
  }
  if (button.dataset.category) {
    state.category = button.dataset.category;
    render();
    return;
  }
  if (button.dataset.package !== undefined) {
    state.package = Number(button.dataset.package);
    state.currentOrder = null;
    render();
    return;
  }
  if (button.dataset.filter) {
    state.historyFilter = button.dataset.filter;
    render();
    return;
  }
  if (button.dataset.order) {
    viewOrder(button.dataset.order);
    return;
  }
  if (button.dataset.resume) {
    resumeOrder(button.dataset.resume);
    return;
  }
  if (button.dataset.cancel) {
    showModal(
      "<h2>ยกเลิกคำสั่งซื้อนี้?</h2><p>" +
        button.dataset.cancel +
        ' ยังไม่ได้ชำระเงิน<br>หลังยกเลิกสามารถเริ่มคำสั่งซื้อใหม่ได้</p><button class="primary" data-confirm-cancel="' +
        button.dataset.cancel +
        '">ยืนยันยกเลิก</button><button class="secondary" data-action="close-modal">เก็บคำสั่งซื้อไว้</button>',
    );
    return;
  }
  if (button.dataset.confirmCancel) {
    const order = state.orders.find(
      (item) => item.id === button.dataset.confirmCancel,
    );
    if (order.status === "pending") order.status = "cancelled";
    modal.close();
    render();
    toast("ยกเลิกคำสั่งซื้อแล้ว");
    return;
  }
  if (button.dataset.editPackage !== undefined) {
    packageForm(Number(button.dataset.editPackage));
    return;
  }
  if (button.dataset.togglePackage !== undefined) {
    const game = getGame(state.adminGame),
      i = Number(button.dataset.togglePackage);
    game.disabled = game.disabled || [];
    if (game.disabled.includes(i))
      game.disabled = game.disabled.filter((value) => value !== i);
    else game.disabled.push(i);
    render();
    toast("อัปเดตสถานะแพ็กเกจแล้ว");
    return;
  }
  const action = button.dataset.action;
  if (action === "receipt-placeholder")
    toast("หน้าใบเสร็จยังไม่รวมในต้นแบบนี้");
  if (action === "close-modal") modal.close();
  if (action === "checkout" && validateUid()) navigate("checkout");
  if (action === "pay") confirmPayment();
  if (action === "payment-success") finishPayment(true);
  if (action === "payment-fail") finishPayment(false);
  if (action === "promo")
    info(
      "โปรโมชันตัวอย่าง",
      "ตัวอย่างพื้นที่สำหรับแคมเปญแต้ม ×2 เมื่อเติมครบ ฿300<br>แคมเปญนี้ยังไม่เปิดใช้งานในต้นแบบ การคำนวณใช้แต้มอัตราปกติ",
    );
  if (action === "uid-help")
    info(
      "หา UID ของคุณ",
      "เปิดเกม → ไปที่โปรไฟล์ผู้เล่น → คัดลอกหมายเลข UID<br><br>ต้นแบบนี้ใช้ UID ตัวเลข 10–12 หลักสำหรับทุกเกมเพื่อทดลองหน้าจอ กฎจริงต้องกำหนดแยกแต่ละเกม",
    );
  if (action === "support")
    info(
      "ศูนย์ช่วยเหลือ",
      "ตรวจสอบสถานะได้ที่หน้าประวัติการเติมเงิน<br>เมื่อขอความช่วยเหลือ ให้เตรียมหมายเลขคำสั่งซื้อและ UID<br><br>ช่องทางติดต่อจริงจะเพิ่มภายหลัง",
    );
  if (action === "terms")
    info(
      "เงื่อนไขตัวอย่าง",
      "หน้านี้ใช้ทดสอบ UX/UI เท่านั้น ไม่มีการสมัครบัญชีหรือรับชำระเงินจริง<br>ต้องเพิ่มเงื่อนไขบริการและความเป็นส่วนตัวฉบับจริงก่อนเปิดใช้งาน",
    );
  if (action === "logout")
    showModal(
      '<h2>ออกจากระบบ?</h2><p>คุณกลับมาเข้าสู่ระบบได้อีกครั้ง</p><button class="primary" data-action="confirm-logout">ออกจากระบบ</button><button class="secondary" data-action="close-modal">ยกเลิก</button>',
    );
  if (action === "confirm-logout") {
    modal.close();
    navigate("login");
  }
  if (action === "forgot")
    showModal(
      '<h2>ลืมรหัสผ่าน</h2><p>ระบุอีเมลที่ใช้สมัครบัญชี</p><form id="forgot-form"><label class="field">อีเมล<input type="email" name="email" required placeholder="you@example.com"></label><button class="primary" type="submit">ขอลิงก์ตั้งรหัสผ่านใหม่</button><button class="secondary" type="button" data-action="close-modal">ย้อนกลับ</button></form>',
    );
  if (action === "add-package") packageForm(null);
});
document.addEventListener("input", function (event) {
  if (event.target.id === "uid") {
    state.uid = event.target.value.trim();
    document.getElementById("uid-error").textContent = "";
    event.target.removeAttribute("aria-invalid");
    state.currentOrder = null;
  }
  if (event.target.id === "game-search") {
    state.query = event.target.value;
    document.getElementById("game-list").innerHTML = gameList();
    updateGameCount();
  }
  if (event.target.id === "admin-search") {
    const query = event.target.value.toLowerCase();
    const orders = state.orders.filter((order) =>
      (order.id + " " + order.uid + " " + getGame(order.game).name)
        .toLowerCase()
        .includes(query),
    );
    document.getElementById("admin-orders").innerHTML = orders.length
      ? orders.map((order) => orderCard(order, true)).join("")
      : '<div class="empty"><strong>ไม่พบคำสั่งซื้อ</strong><small>ลองค้นหาด้วยหมายเลขออร์เดอร์หรือ UID</small></div>';
  }
});
document.addEventListener("change", function (event) {
  if (event.target.id === "discount") {
    state.discount = event.target.checked;
    render();
    document.getElementById("discount").focus();
  }
  if (event.target.name === "payment") {
    state.payment = event.target.value;
    render();
    document.querySelector('input[name="payment"]:checked').focus();
  }
  if (event.target.id === "server") state.server = event.target.value;
  if (event.target.id === "admin-game") {
    state.adminGame = event.target.value;
    render();
  }
});
document.addEventListener("submit", function (event) {
  event.preventDefault();
  const form = event.target,
    data = new FormData(form);
  if (form.id === "login-form") {
    state.user = String(data.get("username"));
    navigate("home");
    toast("เข้าสู่ระบบตัวอย่างแล้ว");
  }
  if (form.id === "register-form") {
    if (data.get("password") !== data.get("confirm")) {
      document.getElementById("register-error").textContent =
        "รหัสผ่านทั้งสองช่องไม่ตรงกัน";
      form.elements.confirm.focus();
      return;
    }
    state.user = String(data.get("username"));
    navigate("home");
    toast("สร้างโปรไฟล์ตัวอย่างแล้ว");
  }
  if (form.id === "forgot-form") {
    modal.close();
    info(
      "คำขอรีเซ็ตรหัสผ่าน",
      "ในระบบจริง หากมีบัญชีนี้ ระบบจะส่งลิงก์ไปยังอีเมลที่ระบุ<br><br>ต้นแบบนี้ไม่ได้ส่งอีเมล",
    );
  }
  if (form.id === "package-form") {
    const game = getGame(state.adminGame),
      pack = [Number(data.get("quantity")), Number(data.get("price"))];
    if (form.dataset.index === "new") game.packs.push(pack);
    else game.packs[Number(form.dataset.index)] = pack;
    modal.close();
    render();
    toast("บันทึกแพ็กเกจตัวอย่างแล้ว");
  }
  if (form.id === "points-form") {
    const amount = Number(data.get("amount")),
      reason = String(data.get("reason")).trim();
    if (
      !Number.isInteger(amount) ||
      amount === 0 ||
      state.points + amount < 0
    ) {
      document.getElementById("points-error").textContent =
        "ระบุจำนวนเต็มที่ไม่ใช่ 0 และยอดคงเหลือต้องไม่ติดลบ";
      return;
    }
    showModal(
      "<h2>ยืนยันการปรับแต้ม</h2><p>จาก " +
        number(state.points) +
        " เป็น <b>" +
        number(state.points + amount) +
        " แต้ม</b><br>เหตุผล: " +
        escapeText(reason) +
        '</p><button class="primary" id="confirm-points">ยืนยันปรับแต้ม</button><button class="secondary" data-action="close-modal">ยกเลิก</button>',
    );
    document.getElementById("confirm-points").onclick = function () {
      state.points += amount;
      state.ledger.unshift({
        label: "แอดมินปรับแต้ม",
        detail: reason,
        value: amount,
      });
      modal.close();
      render();
      toast("บันทึกการปรับแต้มแล้ว");
    };
  }
});
