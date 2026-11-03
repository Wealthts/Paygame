// ชิ้นส่วนที่ใช้ร่วมกัน เช่น ไอคอน ปุ่ม และเมนู
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function icon(name) {
  const paths = {
    home: '<path d="m3 10 9-7 9 7v10h-6v-7H9v7H3Z"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
    back: '<path d="m14 5-7 7 7 7"/>',
    next: '<path d="m9 5 7 7-7 7"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    gift: '<path d="M3 10h18v4H3zM5 14v7h14v-7M12 10v11"/><path d="M12 10C1 10 4 1 9 5l3 5Zm0 0c11 0 8-9 3-5l-3 5Z"/>',
    user: '<circle cx="12" cy="7" r="4"/><path d="M4 21v-3a8 8 0 0 1 16 0v3"/>',
    coin: '<circle cx="12" cy="12" r="9"/><path d="m12 6 1.7 3.5 3.8.5-2.7 2.7.7 3.8-3.5-1.8-3.5 1.8.7-3.8L6.5 10l3.8-.5Z"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    shield:
      '<path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6Z"/><path d="m8 12 3 3 5-6"/>',
    qr: '<path d="M3 3h6v6H3zM15 3h6v6h-6zM3 15h6v6H3zM15 15h3v3h3v3h-6zM21 12v3M12 3v3M12 12h3M12 18v3"/>',
    wallet:
      '<path d="M20 7H4V4h14v3M4 7a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16V7ZM16 12h6v5h-6z"/>',
    card: '<rect x="2" y="5" width="20" height="14" rx="3"/><path d="M2 10h20M6 15h4"/>',
    download: '<path d="M12 3v12m-5-5 5 5 5-5M4 17v4h16v-4"/>',
    edit: '<path d="m4 15 12-12 5 5L9 20l-6 1zM13 6l5 5"/>',
    box: '<path d="m12 2 9 5v10l-9 5-9-5V7Zm-9 5 9 5 9-5M12 12v10M7 4.8l10 5"/>',
    receipt: '<path d="M5 3h14v18l-3-2-4 2-4-2-3 2ZM8 8h8M8 12h8M8 16h4"/>',
    logout: '<path d="M9 4H4v16h5M9 12h12m-5-5 5 5-5 5"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 5 2c-2 1-2 2-2 3M12 17h.01"/>',
    lock: '<rect x="5" y="10" width="14" height="11" rx="3"/><path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v3"/>',
    close: '<path d="m6 6 12 12M6 18 18 6"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="m3 6 9 7 9-7"/>',
  };
  return (
    '<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">' +
    (paths[name] || paths.coin) +
    "</svg>"
  );
}

const brand = () =>
  '<span class="wordmark"><span class="brand-icon">+</span>Game<span>Pay</span></span>';

const mini = (id) =>
  '<span class="game-mini ' + id + '">' + getGame(id).mark + "</span>";

const badge = (status) =>
  '<span class="badge ' + status + '">' + labelStatus(status) + "</span>";

const goButton = (page, text, style = "text-button") =>
  '<button class="' + style + '" data-go="' + page + '">' + text + "</button>";

function topbar(title, back = "home", subtitle = "") {
  return (
    '<header class="topbar"><button class="icon-button" data-go="' +
    back +
    '" aria-label="ย้อนกลับ">' +
    icon("back") +
    "</button><div><h2>" +
    title +
    "</h2>" +
    (subtitle ? '<p class="subtitle">' + subtitle + "</p>" : "") +
    "</div></header>"
  );
}

function bottomNav(admin = false) {
  const items = admin
    ? [
        ["admin", "receipt", "คำสั่งซื้อ"],
        ["catalog", "box", "เกม/แพ็กเกจ"],
        ["users", "user", "ผู้ใช้/แต้ม"],
      ]
    : [
        ["home", "home", "หน้าแรก"],
        ["history", "clock", "ประวัติ"],
        ["rewards", "gift", "แลกรางวัล"],
        ["profile", "user", "โปรไฟล์"],
      ];
  return (
    '<nav class="bottom-nav" aria-label="เมนูหลัก">' +
    items
      .map(
        ([page, symbol, label]) =>
          '<button data-go="' +
          page +
          '" ' +
          (state.page === page ? 'class="active" aria-current="page"' : "") +
          ">" +
          icon(symbol) +
          "<span>" +
          label +
          "</span></button>",
      )
      .join("") +
    "</nav>"
  );
}

function steps(current) {
  return (
    '<div class="steps">' +
    ["แพ็กเกจ", "UID ผู้เล่น", "ชำระเงิน"]
      .map(
        (label, i) =>
          '<span class="' +
          (i < current ? "done" : "") +
          '"><b>' +
          (i + 1) +
          "</b>" +
          label +
          "</span>" +
          (i < 2 ? "<i></i>" : ""),
      )
      .join("") +
    "</div>"
  );
}

function searchBox(id, placeholder, value = "") {
  return (
    '<label class="search">' +
    icon("search") +
    '<input id="' +
    id +
    '" aria-label="' +
    placeholder +
    '" placeholder="' +
    placeholder +
    '" value="' +
    escapeText(value) +
    '" autocomplete="off"></label>'
  );
}
