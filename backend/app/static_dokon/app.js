(function () {
  "use strict";

  var API = "/dokon-api";
  var TABS = [
    { key: "pending", label: "Yangi" },
    { key: "preparing", label: "Tayyorlanmoqda" },
    { key: "ready", label: "Tayyor" },
    { key: "delivered", label: "Yetkazildi" },
    { key: "all", label: "Barchasi" },
  ];
  var STATUS_LABELS = {
    pending: "Yangi", preparing: "Tayyorlanmoqda", ready: "Tayyor",
    shipped: "Kuryerda", delivered: "Yetkazildi", cancelled: "Bekor qilindi",
    // "paid" — eski oqimdan qolgan holat, yangi buyurtmalarda chiqmaydi,
    // faqat eski test yozuvlarida ko'rinishi mumkin.
    paid: "Tasdiqlandi",
  };
  var STATUS_COLORS = {
    pending: ["#E3ECFA", "#14243F"], preparing: ["#FEF3C7", "#92400E"],
    ready: ["#DCFCE7", "#16A34A"], shipped: ["#E3ECFA", "#2F5FB3"],
    delivered: ["#DCFCE7", "#16A34A"], cancelled: ["#FEE2E2", "#DC2626"],
    paid: ["#E3ECFA", "#2F5FB3"],
  };
  // Kategoriya ikonkalari (chiziq uslubi) — real mahsulot rasmi bo'lmaganda
  // ko'rsatiladi. Yo'l (path) ma'lumotlari handoff/...dc.html'dagi icon(catId)
  // funksiyasidan, kategoriya.slug bo'yicha kalitlangan.
  var CATEGORY_ICON_PATHS = {
    ruchka: "M5 19l1-4L16.5 4.5a2 2 0 0 1 3 3L9 18l-4 1M14 7l3 3",
    daftar: "M6 3.5h12v17H6zM6 3.5v17M9.5 8h5M9.5 11.5h5",
    qalam: "M5 19l1.5-5L16 4.5l3.5 3.5L10 17.5 5 19M13 7.5l3.5 3.5",
    "rangli-qalam": "M7 20V8l2.5-4L12 8v12M12 20V10l2.5-4L17 10v10",
    a4: "M7 3h7l4 4v14H7zM14 3v4h4",
    "rangli-qogoz": "M5 8h10v13H5zM8 5h10v13",
    flomaster: "M9 3h6v7H9zM9 10l-1.5 11h9L15 10",
    marker: "M8 4h8v6H8zM9 10v10h6V10",
    ochirgich: "M5 14 12 7l6 6-7 7H7l-2-2v-4M9 10l6 6",
    lineyka: "M3 15 15 3l6 6L9 21zM8 12l2 2M12 8l2 2M16 4l2 2",
    yelim: "M10 3h4v4h-4zM8 7h8l1 4v10H7V11zM7 14h10",
    qaychi: "M9 9 19 19M19 5 9 15M4 7.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0M4 16.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0",
    albom: "M4 5h16v14H4zM7 15l3.5-4 3 3 2-2 2.5 3",
    papka: "M3 6h6l2 2.5h10V19H3zM3 6v13",
    kundalik: "M6 3h13v18H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2M9 3v18",
    qalamdon: "M4 10h16v9H4zM4 13h16M9 10V7h6v3",
    shtrix: "M9 3h6v5H9zM8 8h8v13H8zM8 14h8",
    skotch: "M4 12a8 8 0 1 0 16 0a8 8 0 1 0-16 0M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0M14 20h6",
  };
  function categoryIconSvg(slug, cssClass) {
    var d = CATEGORY_ICON_PATHS[slug] || "M3 7l9-4 9 4v10l-9 4-9-4zM3 7l9 4 9-4M12 11v10";
    return '<svg class="' + cssClass + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
      'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="' + d + '"/></svg>';
  }

  var state = {
    activeTab: "pending",
    counts: {},
    orders: [],
    prevPendingCount: null,
    pollTimer: null,
    connOk: true,
    view: "list",       // "list" | "detail"
    detailOrderId: null,
    detailOrder: null,
  };

  // Ism/telefon/manzil/izoh maydonlarida real ma'lumot bormi tekshiradi —
  // bo'sh yoki faqat tinish belgisidan iborat qiymatlar ("." , "-") "hali
  // kiritilmagan" deb hisoblanadi (profilni to'ldirmagan xaridorlarda uchraydi).
  function cleanField(v) {
    if (v === null || v === undefined) return null;
    var s = String(v).trim();
    if (!s) return null;
    if (!/[0-9a-zA-Zа-яА-ЯёЁʻʼ'’‘`]/.test(s)) return null;
    return s;
  }
  function fieldOrMuted(v) {
    var c = cleanField(v);
    return c ? escapeHtml(c) : '<span class="muted-val">Kiritilmagan</span>';
  }

  // ---------- yordamchi ----------
  function $(id) { return document.getElementById(id); }
  function escapeHtml(s) {
    if (s === null || s === undefined) return "";
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function formatSom(n) {
    var v = Math.round(Number(n) || 0);
    var s = v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    return s + " so’m";
  }
  function minutesAgo(iso) {
    var diffMs = Date.now() - new Date(iso).getTime();
    var mins = Math.max(0, Math.round(diffMs / 60000));
    if (mins < 1) return "hozir";
    if (mins < 60) return mins + " daqiqa oldin";
    var hrs = Math.floor(mins / 60);
    if (hrs < 24) return hrs + " soat oldin";
    return Math.floor(hrs / 24) + " kun oldin";
  }
  function showToast(msg) {
    var el = document.createElement("div");
    el.className = "toast";
    el.textContent = msg;
    $("toastHost").appendChild(el);
    setTimeout(function () { el.remove(); }, 3200);
  }
  function beep() {
    try {
      var ctx = new (window.AudioContext || window.webkitAudioContext)();
      var o = ctx.createOscillator();
      var g = ctx.createGain();
      o.type = "sine";
      o.frequency.value = 880;
      g.gain.setValueAtTime(0.0001, ctx.currentTime);
      g.gain.exponentialRampToValueAtTime(0.25, ctx.currentTime + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.5);
      o.connect(g); g.connect(ctx.destination);
      o.start(); o.stop(ctx.currentTime + 0.55);
    } catch (e) { /* audio ishlamasa jim o'tkazamiz */ }
  }

  async function api(path, opts) {
    opts = opts || {};
    var res;
    try {
      res = await fetch(API + path, Object.assign({
        credentials: "same-origin",
        headers: opts.body ? { "Content-Type": "application/json" } : undefined,
      }, opts));
    } catch (e) {
      setConn(false);
      throw { network: true };
    }
    setConn(true);
    var data = null;
    try { data = await res.json(); } catch (e) { /* body yo'q bo'lishi mumkin */ }
    if (!res.ok) {
      throw { status: res.status, detail: (data && data.detail) || "Xato yuz berdi" };
    }
    return data;
  }

  function setConn(ok) {
    if (state.connOk === ok) return;
    state.connOk = ok;
    $("connBanner").classList.toggle("hidden", ok);
  }

  // ---------- ekranlar ----------
  function showScreen(id) {
    ["screenLogin", "screenName", "screenMain", "screenDetail"].forEach(function (s) {
      $(s).classList.toggle("hidden", s !== id);
    });
  }

  // ---------- marshrutlash (/dokon yoki /dokon/FN-<id>) ----------
  function parseOrderIdFromPath() {
    var m = /\/dokon\/FN-(\d+)\/?$/.exec(location.pathname);
    return m ? parseInt(m[1], 10) : null;
  }
  function routeFromLocation() {
    var orderId = parseOrderIdFromPath();
    if (orderId) { showDetail(orderId); } else { showList(); }
  }
  function navigateToOrder(id) {
    history.pushState({}, "", "/dokon/FN-" + id);
    showDetail(id);
  }
  function navigateToList() {
    history.pushState({}, "", "/dokon");
    showList();
  }
  window.addEventListener("popstate", function () {
    if (!$("screenMain").classList.contains("hidden") || !$("screenDetail").classList.contains("hidden")) {
      routeFromLocation();
    }
  });

  function showList() {
    state.view = "list";
    state.detailOrderId = null;
    showScreen("screenMain");
    renderTabs();
    loadOrders();
    if (!state.pollTimer) startPolling();
  }

  async function showDetail(id) {
    state.view = "detail";
    state.detailOrderId = id;
    showScreen("screenDetail");
    $("detailContent").innerHTML = '<div class="empty-state"><div class="big">Yuklanmoqda…</div></div>';
    if (!state.pollTimer) startPolling();
    await loadDetail(id);
  }

  async function loadDetail(id) {
    try {
      var order = await api("/orders/" + id);
      state.detailOrder = order;
      if (state.view === "detail" && state.detailOrderId === id) renderDetail(order);
    } catch (e) {
      if (state.view === "detail" && state.detailOrderId === id && e.status === 404) {
        showToast("Bu buyurtma topilmadi");
        navigateToList();
      }
    }
  }

  $("backBtn").addEventListener("click", navigateToList);

  async function boot() {
    try {
      var me = await api("/me");
      if (!me.name) {
        showScreen("screenName");
      } else {
        $("whoamiLabel").textContent = me.name + " sifatida kirdingiz";
        routeFromLocation();
      }
    } catch (e) {
      showScreen("screenLogin");
    }
  }

  $("loginForm").addEventListener("submit", async function (e) {
    e.preventDefault();
    $("loginError").classList.add("hidden");
    var btn = $("loginBtn");
    btn.disabled = true;
    try {
      await api("/login", {
        method: "POST",
        body: JSON.stringify({ login: $("loginInput").value.trim(), password: $("passwordInput").value }),
      });
      await boot();
    } catch (err) {
      $("loginError").textContent = err.network
        ? "Ulanish yo'q. Internetni tekshirib, qayta urining."
        : (err.status === 401 ? "Login yoki parol noto'g'ri." : "Xato yuz berdi, qayta urining.");
      $("loginError").classList.remove("hidden");
    } finally {
      btn.disabled = false;
    }
  });

  $("nameForm").addEventListener("submit", async function (e) {
    e.preventDefault();
    $("nameError").classList.add("hidden");
    var name = $("nameInput").value.trim();
    if (!name) return;
    try {
      await api("/name", { method: "POST", body: JSON.stringify({ name: name }) });
      await boot();
    } catch (err) {
      $("nameError").textContent = "Saqlab bo'lmadi, qayta urining.";
      $("nameError").classList.remove("hidden");
    }
  });

  $("logoutBtn").addEventListener("click", async function () {
    if (!confirm("Chiqmoqchimisiz?")) return;
    stopPolling();
    try { await api("/logout", { method: "POST" }); } catch (e) {}
    showScreen("screenLogin");
  });

  // ---------- tab/ro'yxat ----------
  function renderTabs() {
    var host = $("tabs");
    host.innerHTML = "";
    TABS.forEach(function (t) {
      var el = document.createElement("div");
      el.className = "tab" + (t.key === state.activeTab ? " active" : "");
      el.dataset.key = t.key;
      el.innerHTML = '<span>' + escapeHtml(t.label) + '</span><span class="count">' + (state.counts[t.key] || 0) + '</span>';
      el.addEventListener("click", function () {
        if (state.activeTab === t.key) return;
        state.activeTab = t.key;
        renderTabs();
        loadOrders();
      });
      host.appendChild(el);
    });
  }

  function startPolling() {
    loadCountsAndOrders();
    state.pollTimer = setInterval(loadCountsAndOrders, 12000);
  }
  function stopPolling() {
    if (state.pollTimer) clearInterval(state.pollTimer);
    state.pollTimer = null;
  }

  async function loadCountsAndOrders() {
    try {
      var counts = await api("/orders/counts");
      var newPending = counts.pending || 0;
      if (state.prevPendingCount !== null && newPending > state.prevPendingCount) {
        beep();
        showToast("Yangi buyurtma keldi!");
      }
      state.prevPendingCount = newPending;
      state.counts = counts;
      if (state.view === "detail") {
        if (state.detailOrderId) await loadDetail(state.detailOrderId);
        return;
      }
      renderTabs();
      await loadOrders();
    } catch (e) {
      // setConn(false) allaqachon api() ichida bajarildi
    }
  }

  async function loadOrders() {
    try {
      var orders = await api("/orders?status_filter=" + state.activeTab);
      var prevIds = state.orders.map(function (o) { return o.id; });
      state.orders = orders;
      renderOrders(prevIds);
    } catch (e) { /* keyingi pollda qayta urinamiz */ }
  }

  function renderOrders(prevIds) {
    var host = $("ordersList");
    if (!state.orders.length) {
      host.innerHTML = '<div class="empty-state"><div class="big">Bu bo’limda buyurtma yo’q</div><div class="small">Yangi buyurtma kelsa shu yerda ko’rinadi</div></div>';
      return;
    }
    host.innerHTML = "";
    state.orders.forEach(function (o) {
      host.appendChild(renderCard(o, prevIds.indexOf(o.id) === -1 && prevIds.length > 0));
    });
  }

  // Telefon havolasi — mijoz raqami real bo'lsagina (fieldOrMuted natijasidan
  // farqli, tel: href uchun tozalangan qiymatning o'zi kerak).
  function phoneBlockHtml(o) {
    var clean = cleanField(o.customer_phone);
    if (!clean) return '<div class="customer-phone muted-val">Kiritilmagan</div>';
    return '<a class="customer-phone" href="tel:' + escapeHtml(clean) + '"><svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>' + escapeHtml(clean) + "</a>";
  }
  function addressBlockHtml(o) {
    if (o.delivery_type === "pickup") {
      return '<div class="label">Do’kondan olib ketadi</div>' + (o.pickup_code ? "Kod: " + escapeHtml(o.pickup_code) : "");
    }
    return '<div class="label">Manzil</div>' + fieldOrMuted(o.delivery_address);
  }
  function noteBlockHtml(o) {
    return '<div class="label" style="text-transform:uppercase;font-size:11.5px;font-weight:600;color:var(--text-muted);letter-spacing:.5px;margin-bottom:2px">Izoh</div>' + fieldOrMuted(o.note);
  }

  function renderCard(o, isNew) {
    var card = document.createElement("div");
    card.className = "order-card" + (isNew ? " flash" : "");
    card.style.cursor = "pointer";
    card.addEventListener("click", function (e) {
      if (e.target.closest("button, a")) return;
      navigateToOrder(o.id);
    });

    var colors = STATUS_COLORS[o.status] || ["#E3ECFA", "#14243F"];
    var head = document.createElement("div");
    head.className = "order-head";
    head.innerHTML =
      '<div><div class="num">FN-' + o.id + '</div><div class="time">' + escapeHtml(minutesAgo(o.created_at)) + '</div></div>' +
      '<div class="status-badge" style="background:' + colors[0] + ';color:' + colors[1] + '">' + escapeHtml(STATUS_LABELS[o.status] || o.status) + '</div>';
    card.appendChild(head);

    if (o.claimed_by && o.status !== "pending" && o.status !== "delivered" && o.status !== "cancelled") {
      var claim = document.createElement("div");
      claim.className = "claimed-badge";
      claim.textContent = "Tayyorlayapti: " + o.claimed_by;
      card.appendChild(claim);
    }

    card.appendChild(divider());

    var customer = document.createElement("div");
    customer.className = "customer-block";
    customer.innerHTML = '<div class="customer-name">' + fieldOrMuted(o.customer_name) + '</div>' + phoneBlockHtml(o);
    card.appendChild(customer);

    var addr = document.createElement("div");
    addr.className = "address-block";
    addr.innerHTML = addressBlockHtml(o);
    card.appendChild(addr);

    var note = document.createElement("div");
    note.className = "note-block";
    note.innerHTML = noteBlockHtml(o);
    card.appendChild(note);

    card.appendChild(divider());

    var items = document.createElement("div");
    items.className = "items-list";
    (o.items || []).forEach(function (it) {
      var row = document.createElement("div");
      row.className = "item-row";
      var name = it.product_name || "Mahsulot";
      row.innerHTML =
        '<span class="item-name">' + escapeHtml(name) + ' × ' + it.quantity + '</span>' +
        '<span class="item-price">' + formatSom(it.price_at_purchase * it.quantity) + '</span>';
      items.appendChild(row);
    });
    card.appendChild(items);

    var total = document.createElement("div");
    total.className = "total-row";
    total.innerHTML = '<span class="label">Jami</span><span class="value">' + formatSom(o.total) + '</span>';
    card.appendChild(total);

    if (o.status === "cancelled" && o.cancel_reason) {
      var reason = document.createElement("div");
      reason.className = "cancel-reason";
      reason.textContent = "Sabab: " + o.cancel_reason;
      card.appendChild(reason);
    }

    var actions = actionsFor(o);
    if (actions) card.appendChild(actions);

    return card;
  }

  function divider() {
    var d = document.createElement("div");
    d.className = "row-line";
    return d;
  }

  // ---------- buyurtma ichi (detail) ----------
  function renderDetail(o) {
    var host = $("detailContent");
    host.innerHTML = "";

    var top = document.createElement("div");
    top.className = "detail-topline";
    var colors = STATUS_COLORS[o.status] || ["#E3ECFA", "#14243F"];
    top.innerHTML =
      '<div class="detail-num">FN-' + o.id + '</div>' +
      '<div class="status-badge" style="background:' + colors[0] + ';color:' + colors[1] + '">' + escapeHtml(STATUS_LABELS[o.status] || o.status) + '</div>';
    host.appendChild(top);

    if (o.claimed_by && o.status !== "pending" && o.status !== "delivered" && o.status !== "cancelled") {
      var claim = document.createElement("div");
      claim.className = "claimed-badge";
      claim.style.marginBottom = "14px";
      claim.textContent = "Tayyorlayapti: " + o.claimed_by;
      host.appendChild(claim);
    }

    (o.items || []).forEach(function (it) {
      host.appendChild(renderDetailItem(it));
    });

    var info = document.createElement("div");
    info.className = "info-card";
    info.innerHTML =
      '<div class="customer-block"><div class="customer-name">' + fieldOrMuted(o.customer_name) + '</div>' + phoneBlockHtml(o) + '</div>' +
      '<div class="row-line"></div>' +
      '<div class="address-block" style="margin-top:0">' + addressBlockHtml(o) + '</div>' +
      '<div class="row-line"></div>' +
      '<div class="note-block" style="margin-top:0">' + noteBlockHtml(o) + '</div>' +
      '<div class="total-row"><span class="label">Jami</span><span class="value">' + formatSom(o.total) + '</span></div>';
    host.appendChild(info);

    if (o.status === "cancelled" && o.cancel_reason) {
      var reason = document.createElement("div");
      reason.className = "cancel-reason";
      reason.textContent = "Sabab: " + o.cancel_reason;
      host.appendChild(reason);
    }

    var actions = actionsFor(o);
    if (actions) host.appendChild(actions);
  }

  function renderDetailItem(it) {
    var card = document.createElement("div");
    card.className = "item-card-big";

    var imgWrap = document.createElement("div");
    imgWrap.className = "img-wrap";
    if (it.product_image_url) {
      imgWrap.innerHTML = '<img src="' + escapeHtml(it.product_image_url) + '" alt="">';
      imgWrap.addEventListener("click", function () { openZoom(it.product_image_url, null); });
    } else {
      imgWrap.innerHTML = categoryIconSvg(it.category_slug, "cat-icon");
      imgWrap.addEventListener("click", function () { openZoom(null, it.category_slug); });
    }
    card.appendChild(imgWrap);

    var info = document.createElement("div");
    info.className = "info";
    info.innerHTML =
      '<div class="p-name">' + escapeHtml(it.product_name || "Mahsulot") + '</div>' +
      '<div class="qty-row">' +
      '<div><div class="qty-label">Soni</div><div class="qty-big">× ' + it.quantity + '</div></div>' +
      '<div><div class="price-label">Narxi</div><div class="price-val">' + formatSom(it.price_at_purchase) + '</div></div>' +
      '</div>';
    card.appendChild(info);

    return card;
  }

  function openZoom(imgUrl, categorySlug) {
    var overlay = $("zoomOverlay");
    overlay.innerHTML =
      '<div class="zoom-close" id="zoomCloseBtn"><svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></svg></div>' +
      (imgUrl ? '<img src="' + escapeHtml(imgUrl) + '" alt="">' : categoryIconSvg(categorySlug, "zoom-cat-icon"));
    overlay.classList.remove("hidden");
    overlay.addEventListener("click", function (e) {
      if (e.target === overlay || e.target.closest("#zoomCloseBtn")) closeZoom();
    });
  }
  function closeZoom() {
    $("zoomOverlay").classList.add("hidden");
    $("zoomOverlay").innerHTML = "";
  }

  function actionsFor(o) {
    var next = null, nextLabel = "";
    if (o.status === "pending") { next = "preparing"; nextLabel = "Qabul qildim"; }
    else if (o.status === "preparing") { next = "ready"; nextLabel = "Tayyor"; }
    else if (o.status === "ready") {
      if (o.delivery_type === "pickup") { next = "delivered"; nextLabel = "Mijozga topshirdim"; }
      else { next = "shipped"; nextLabel = "Kuryerga berdim"; }
    } else if (o.status === "shipped") { next = "delivered"; nextLabel = "Yetkazildi"; }

    if (!next) return null;

    var canCancel = o.status === "pending" || o.status === "preparing" || o.status === "ready";

    var wrap = document.createElement("div");
    wrap.className = "actions";

    var mainBtn = document.createElement("button");
    mainBtn.className = "btn btn-primary";
    mainBtn.textContent = nextLabel;
    mainBtn.addEventListener("click", function () { doStatusChange(o.id, next, mainBtn); });
    wrap.appendChild(mainBtn);

    if (canCancel) {
      var cancelBtn = document.createElement("button");
      cancelBtn.className = "btn btn-danger";
      cancelBtn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
      cancelBtn.title = "Bekor qilish";
      cancelBtn.addEventListener("click", function () { openCancelModal(o.id); });
      wrap.appendChild(cancelBtn);
    }
    return wrap;
  }

  async function doStatusChange(orderId, newStatus, btn) {
    btn.disabled = true;
    try {
      await api("/orders/" + orderId + "/status", {
        method: "POST",
        body: JSON.stringify({ new_status: newStatus }),
      });
      await loadCountsAndOrders();
    } catch (err) {
      showToast(err.network ? "Ulanish yo'q, qayta urining." : (err.detail || "Xato yuz berdi"));
      await loadCountsAndOrders();
    } finally {
      btn.disabled = false;
    }
  }

  // ---------- bekor qilish modal ----------
  var pendingCancelOrderId = null;
  function openCancelModal(orderId) {
    pendingCancelOrderId = orderId;
    var overlay = document.createElement("div");
    overlay.className = "modal-overlay";
    overlay.id = "cancelModal";
    overlay.innerHTML =
      '<div class="modal-sheet">' +
      '<h2>Buyurtmani bekor qilish</h2>' +
      '<p>Sababini yozing — mijozga shu ko’rinadi.</p>' +
      '<textarea id="cancelReasonInput" rows="3" placeholder="Masalan: mahsulot tugagan"></textarea>' +
      '<div class="modal-actions">' +
      '<button class="btn btn-secondary" id="cancelModalClose">Orqaga</button>' +
      '<button class="btn btn-danger" id="cancelModalConfirm" style="flex:1;color:#fff;background:var(--danger);border:none">Bekor qilish</button>' +
      '</div></div>';
    document.body.appendChild(overlay);
    $("cancelModalClose").addEventListener("click", closeCancelModal);
    overlay.addEventListener("click", function (e) { if (e.target === overlay) closeCancelModal(); });
    $("cancelModalConfirm").addEventListener("click", confirmCancel);
  }
  function closeCancelModal() {
    var m = $("cancelModal");
    if (m) m.remove();
    pendingCancelOrderId = null;
  }
  async function confirmCancel() {
    var reason = $("cancelReasonInput").value.trim();
    if (!reason) { $("cancelReasonInput").focus(); return; }
    var orderId = pendingCancelOrderId;
    var btn = $("cancelModalConfirm");
    btn.disabled = true;
    try {
      await api("/orders/" + orderId + "/cancel", {
        method: "POST",
        body: JSON.stringify({ reason: reason }),
      });
      closeCancelModal();
      await loadCountsAndOrders();
    } catch (err) {
      showToast(err.network ? "Ulanish yo'q, qayta urining." : (err.detail || "Xato yuz berdi"));
      btn.disabled = false;
    }
  }

  boot();
})();
