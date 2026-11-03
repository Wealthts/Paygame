// ตัวช่วยจัดรูปแบบข้อมูลและแสดงข้อความ
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

const app = document.getElementById("app");

const modal = document.getElementById("modal");

const money = (value) =>
  "฿" +
  Number(value).toLocaleString("th-TH", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

const shortMoney = (value) =>
  "฿" + Number(value).toLocaleString("th-TH", { maximumFractionDigits: 2 });

const number = (value) => Number(value).toLocaleString("th-TH");

const escapeText = (value) =>
  String(value).replace(
    /[&<>"']/g,
    (char) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        char
      ],
  );

const getGame = (id = state.game) =>
  games.find((game) => game.id === id) || games[0];

const getPack = () => getGame().packs[state.package] || getGame().packs[0];

const labelStatus = (status) =>
  ({
    success: "สำเร็จ",
    pending: "รอชำระ",
    failed: "ล้มเหลว",
    cancelled: "ยกเลิกแล้ว",
    processing: "กำลังเติม",
  })[status];

// 2. ส่วนประกอบที่ใช้ซ้ำ (ไอคอน ปุ่ม เมนู และฟอร์ม)

let toastTimer;

function toast(message) {
  const element = document.getElementById("toast");
  element.textContent = message;
  element.classList.add("visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => element.classList.remove("visible"), 3200);
}

function showModal(html) {
  document.getElementById("modal-content").innerHTML = html;
  if (!modal.open) modal.showModal();
}

function info(title, message, showReceiptButton = false) {
  showModal(
    "<h2>" +
      title +
      "</h2><p>" +
      message +
      "</p>" +
      (showReceiptButton
        ? '<button class="secondary" data-action="receipt-placeholder">บันทึกใบเสร็จ</button>'
        : "") +
      '<button class="primary" data-action="close-modal">เข้าใจแล้ว</button>',
  );
}
