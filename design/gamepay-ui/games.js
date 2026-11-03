// หน้าแรก รายการเกม แพ็กเกจ และตรวจ UID
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function homePage() {
  return (
    '<div class="screen"><header class="home-header"><div class="row between"><div class="row"><span class="avatar">B</span><div><small class="muted">พร้อมเล่นเกมโปรดหรือยัง?</small><h2>สวัสดี, ' +
    escapeText(state.user) +
    ' <span class="red">✦</span></h2></div></div><button class="point-pill" data-go="rewards" aria-label="แต้มสะสมและรางวัล">' +
    icon("coin") +
    number(state.points) +
    "</button></div>" +
    searchBox("game-search", "ค้นหาเกมที่อยากเติม", state.query) +
    '</header><div class="pad"><div class="promo"><span class="tag">โปรโมชันตัวอย่าง</span><h2>เติมเกมที่ชอบ<br>รับแต้มเพิ่ม ×2</h2><p>เมื่อเติมครบ 300 บาท / ดูเงื่อนไข</p><button class="promo-art" data-action="promo" aria-label="ดูเงื่อนไขโปรโมชัน" style="cursor:pointer">×2</button></div><div class="promo-dots" aria-hidden="true"><i></i><i></i><i></i></div><div class="chip-row">' +
    ["ทั้งหมด", "มือถือ", "PC", "ยอดนิยม"]
      .map(
        (label) =>
          '<button class="chip ' +
          (state.category === label ? "selected" : "") +
          '" data-category="' +
          label +
          '" aria-pressed="' +
          (state.category === label) +
          '">' +
          label +
          "</button>",
      )
      .join("") +
    '</div><div class="section-heading"><h3>เลือกเกมที่ใช่</h3><span id="game-count" class="tiny muted"></span></div><div id="game-list" class="games">' +
    gameList() +
    '</div></div></div>' +
    bottomNav()
  );
}

function gameList() {
  const filtered = games.filter(
    (game) =>
      (state.category === "ทั้งหมด" ||
        (state.category === "ยอดนิยม" &&
          ["rov", "ff", "pubg"].includes(game.id)) ||
        game.category === state.category) &&
      (game.name + " " + game.sub)
        .toLowerCase()
        .includes(state.query.toLowerCase()),
  );
  if (!filtered.length)
    return (
      '<div class="empty" style="grid-column:1/-1">' +
      icon("search") +
      "<strong>ไม่พบเกมที่ค้นหา</strong><small>ลองใช้ชื่อเกมอื่น หรือเลือกหมวดทั้งหมด</small></div>"
    );
  return filtered
    .map(
      (game) =>
        '<button class="game" data-game="' +
        game.id +
        '" aria-label="เติม ' +
        game.name +
        '"><span class="game-art ' + game.id + '"><b>' + game.mark +
        '</b><small>' + game.tagline + '</small></span><strong>' +
        game.name +
        '</strong><small>' + game.category + '</small></button>',
    )
    .join("");
}

function packagePage() {
  const game = getGame(),
    pack = getPack();
  return (
    topbar(game.name, "home", "เลือกแพ็กเกจสำหรับบัญชีเกมของคุณ") +
    steps(2) +
    '<div class="screen"><div class="pad"><div class="row between"><h3>1. เลือกแพ็กเกจ</h3><span class="tiny muted">ราคาเป็นเงินบาท</span></div><div class="package-grid">' +
    game.packs
      .map(
        ([quantity, price], i) =>
          '<button class="package ' +
          (state.package === i ? "selected" : "") +
          '" data-package="' +
          i +
          '" aria-pressed="' +
          (state.package === i) +
          '" ' +
          (game.disabled?.includes(i) ? "disabled" : "") +
          ">" +
          (i === 3 ? '<span class="recommend">ยอดนิยม</span>' : "") +
          "<strong>" +
          number(quantity) +
          " " +
          game.unit +
          "</strong><small>+" +
          Math.floor(price / 10) +
          ' แต้ม</small><div class="amount">' +
          shortMoney(price) +
          "</div></button>",
      )
      .join("") +
    '</div><div class="uid-block"><h3>2. กรอก UID ผู้เล่น</h3><label class="field">Player UID<input id="uid" inputmode="numeric" autocomplete="off" placeholder="กรอก UID ตัวเลข 10–12 หลัก" value="' +
    escapeText(state.uid) +
    '" aria-describedby="uid-hint uid-error"></label><p id="uid-hint" class="hint">ตรวจ UID ให้ตรงกับบัญชีที่ต้องการเติม</p><p id="uid-error" class="error" role="alert"></p>' +
    (game.server
      ? '<label class="field">เซิร์ฟเวอร์<select id="server"><option>Asia</option><option>Europe</option><option>America</option></select></label>'
      : "") +
    '<button class="help-link" data-action="uid-help">' +
    icon("help") +
    ' ดูวิธีหา UID ในเกม</button></div><div class="notice">' +
    icon("shield") +
    '<span>ไม่ต้องใช้รหัสผ่านเกม<br>เติมให้บัญชีตาม UID ที่ระบุเท่านั้น</span></div></div></div><div class="bottom-action row between"><div><small class="muted">ยอดชำระ</small><div class="price">' +
    shortMoney(pack[1]) +
    '</div><small class="muted">รับ +' +
    Math.floor(pack[1] / 10) +
    ' แต้ม</small></div><button class="primary" data-action="checkout">ไปชำระเงิน ' +
    icon("next") +
    "</button></div>"
  );
}

function updateGameCount() {
  const count = document.querySelectorAll("#game-list .game").length;
  document.getElementById("game-count").textContent = count + " เกม";
}

function chooseGame(id) {
  state.game = id;
  state.package = getGame().packs.findIndex(
    (pack, i) => !getGame().disabled?.includes(i),
  );
  if (state.package < 0) {
    toast("เกมนี้ยังไม่มีแพ็กเกจที่เปิดขาย");
    return;
  }
  if (!getGame().disabled?.includes(3)) state.package = 3;
  state.uid = "";
  state.discount = false;
  state.payment = "qr";
  state.currentOrder = null;
  navigate("packages");
}

function validateUid() {
  const field = document.getElementById("uid"),
    valid = /^[0-9]{10,12}$/.test(state.uid);
  field.setAttribute("aria-invalid", String(!valid));
  document.getElementById("uid-error").textContent = valid
    ? ""
    : "กรอก UID เป็นตัวเลข 10–12 หลัก แล้วลองอีกครั้ง";
  if (!valid) field.focus();
  return valid;
}
