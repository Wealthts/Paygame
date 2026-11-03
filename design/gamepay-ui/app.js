// เริ่มต้นแอปและเปลี่ยนหน้าจอ โหลดไฟล์นี้เป็นลำดับสุดท้าย
// ใช้ร่วมกับไฟล์อื่นผ่าน script defer ใน index.html

function render() {
  const pages = {
    home: homePage,
    packages: packagePage,
    checkout: checkoutPage,
    history: historyPage,
    profile: profilePage,
    login: loginPage,
    register: registerPage,
    admin: adminPage,
    catalog: catalogPage,
    users: usersPage,
  };
  app.innerHTML = (pages[state.page] || homePage)();
  document.getElementById("screen-menu").innerHTML = screens
    .map(
      ([page, label], i) =>
        '<button data-preview="' +
        page +
        '" class="' +
        (state.page === page ? "active" : "") +
        '" ' +
        (state.page === page ? 'aria-current="page"' : "") +
        "><span>" +
        String(i + 1).padStart(2, "0") +
        "</span>" +
        label +
        "</button>",
    )
    .join("");
  document.getElementById("screen-label").textContent =
    screens.find((item) => item[0] === state.page)?.[1] || "GamePay";
  const note = notes[state.page] || notes.home;
  document.getElementById("note-title").innerHTML = note[0];
  document.getElementById("note-copy").textContent = note[1];
  document.title =
    "GamePay — " + document.getElementById("screen-label").textContent;
  if (state.page === "home") updateGameCount();
  if (state.page === "packages" && getGame().server)
    document.getElementById("server").value = state.server;
}

function navigate(page) {
  if (page === "rewards") {
    toast("หน้าสะสมแต้มยังไม่รวมในต้นแบบนี้");
    return;
  }
  state.page = page;
  if (location.hash !== "#" + page) history.replaceState(null, "", "#" + page);
  render();
}

function preview(page) {
  if (page === "checkout" && !state.uid) state.uid = "1234567890";
  navigate(page);
}

window.addEventListener("hashchange", () => {
  const page = location.hash.slice(1);
  if (screens.some((item) => item[0] === page)) preview(page);
});
if (new URLSearchParams(location.search).has("embed"))
  document.body.classList.add("embedded");
preview(
  screens.some((item) => item[0] === location.hash.slice(1))
    ? location.hash.slice(1)
    : "home",
);
