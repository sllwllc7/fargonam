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

  var state = {
    activeTab: "pending",
    counts: {},
    orders: [],
    prevPendingCount: null,
    pollTimer: null,
    connOk: true,
  };

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
    ["screenLogin", "screenName", "screenMain"].forEach(function (s) {
      $(s).classList.toggle("hidden", s !== id);
    });
  }

  async function boot() {
    try {
      var me = await api("/me");
      if (!me.name) {
        showScreen("screenName");
      } else {
        $("whoamiLabel").textContent = me.name + " sifatida kirdingiz";
        showScreen("screenMain");
        renderTabs();
        startPolling();
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

  function renderCard(o, isNew) {
    var card = document.createElement("div");
    card.className = "order-card" + (isNew ? " flash" : "");

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
    var phone = o.customer_phone
      ? '<a class="customer-phone" href="tel:' + escapeHtml(o.customer_phone) + '"><svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>' + escapeHtml(o.customer_phone) + '</a>'
      : "";
    customer.innerHTML = '<div class="customer-name">' + escapeHtml(o.customer_name || "Mijoz") + '</div>' + phone;
    card.appendChild(customer);

    var addr = document.createElement("div");
    addr.className = "address-block";
    if (o.delivery_type === "pickup") {
      addr.innerHTML = '<div class="label">Do’kondan olib ketadi</div>' + (o.pickup_code ? "Kod: " + escapeHtml(o.pickup_code) : "");
    } else {
      addr.innerHTML = '<div class="label">Manzil</div>' + escapeHtml(o.delivery_address || "—");
    }
    card.appendChild(addr);

    if (o.note) {
      var note = document.createElement("div");
      note.className = "note-block";
      note.textContent = "Izoh: " + o.note;
      card.appendChild(note);
    }

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
