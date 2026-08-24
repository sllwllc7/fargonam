(function () {
  "use strict";

  var API = "";
  var TOKEN_KEY = "fargonam_miniapp_token";
  var CACHE_PREFIX = "fargonam_miniapp_cache_";
  var tg = window.Telegram && window.Telegram.WebApp ? window.Telegram.WebApp : null;

  if (tg) {
    try {
      tg.ready();
      tg.expand();
      if (tg.setHeaderColor) tg.setHeaderColor("#16294A");
      if (tg.setBackgroundColor) tg.setBackgroundColor("#EEF1F6");
      if (tg.setBottomBarColor) tg.setBottomBarColor("#EEF1F6");
      // Ro'yxatlarni tepadan-pastga surganda Mini App tasodifan yopilib
      // ketmasin (Telegram'ning o'zi vertikal swipe'ni yopish signali
      // sifatida talqin qilishi mumkin).
      if (tg.disableVerticalSwipes) tg.disableVerticalSwipes();
    } catch (e) { /* eski Telegram klient — e'tiborsiz qoldiriladi */ }
  }

  var STATUS_LABELS = {
    pending: "Qabul qilindi", preparing: "Tayyorlanmoqda", ready: "Tayyor",
    shipped: "Kuryerda", delivered: "Yetkazildi", cancelled: "Bekor qilindi",
    paid: "Tasdiqlandi",
  };
  var STATUS_COLORS = {
    pending: ["#E3ECFA", "#14243F"], preparing: ["#FEF3C7", "#92400E"],
    ready: ["#DCFCE7", "#16A34A"], shipped: ["#E3ECFA", "#2F5FB3"],
    delivered: ["#DCFCE7", "#16A34A"], cancelled: ["#FEE2E2", "#DC2626"],
    paid: ["#E3ECFA", "#2F5FB3"],
  };

  var state = {
    accessToken: null,
    categories: [],
    activeCategory: null,
    products: [],
    activeProduct: null,
    activeVariantId: null,
    qty: 1,
    cart: [],
    orders: [],
    lastOrder: null,
    checkoutDeliveryType: "delivery",
    activeTab: "catalog",
    currentScreen: "catalog",
  };

  // ---------- yordamchilar ----------

  function escapeHtml(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function formatPrice(n) {
    n = Math.round(Number(n) || 0);
    var s = String(Math.abs(n));
    var out = "";
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 === 0) out += " ";
      out += s[i];
    }
    return (n < 0 ? "-" : "") + out + " so'm";
  }

  function haptic(kind) {
    if (!tg || !tg.HapticFeedback) return;
    try {
      if (kind === "selection") tg.HapticFeedback.selectionChanged();
      else if (kind === "medium") tg.HapticFeedback.impactOccurred("medium");
      else tg.HapticFeedback.impactOccurred("light");
    } catch (e) { /* noop */ }
  }

  function showToast(text, duration) {
    var host = document.getElementById("toastHost");
    var el = document.createElement("div");
    el.className = "toast";
    el.textContent = text;
    host.innerHTML = "";
    host.appendChild(el);
    setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, duration || 2600);
  }

  function iconSvg(cssClass) {
    return '<svg class="' + cssClass + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
      'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' +
      '<path d="M3 7l9-4 9 4v10l-9 4-9-4zM3 7l9 4 9-4M12 11v10"/></svg>';
  }

  function catInitial(name) {
    return (name || "?").trim().charAt(0).toUpperCase();
  }

  // Rasm yuklanmasa (yo'q URL yoki tarmoq xatosi) o'rniga ikonka —
  // joy sakramasin, brauzerning "buzilgan rasm" belgisi chiqmasin.
  // Inline onerror="" emas — CSP script-src'da 'unsafe-inline' yo'q,
  // shuning uchun listener JS orqali (addEventListener) ulanadi.
  function wireImgFallback(root, selector, fallbackClass) {
    root.querySelectorAll(selector).forEach(function (img) {
      img.loading = "lazy";
      img.decoding = "async";
      img.addEventListener("error", function () {
        var parent = img.parentElement;
        img.remove();
        if (parent && !parent.querySelector("svg")) {
          parent.insertAdjacentHTML("afterbegin", iconSvg(fallbackClass));
        }
      }, { once: true });
    });
  }

  function cacheGet(key) {
    try {
      var raw = localStorage.getItem(CACHE_PREFIX + key);
      return raw ? JSON.parse(raw) : null;
    } catch (e) { return null; }
  }

  function cacheSet(key, data) {
    try { localStorage.setItem(CACHE_PREFIX + key, JSON.stringify(data)); } catch (e) { /* noop */ }
  }

  function renderLoadError(container, retryFn) {
    container.innerHTML = '<div class="empty-state">' +
      '<div class="big">Ulanish yo\'q</div>' +
      '<div class="small">Internetni tekshirib, qaytadan urinib ko\'ring</div>' +
      '<button class="btn btn-secondary" id="retryLoadBtn" style="margin-top:14px;max-width:220px;margin-left:auto;margin-right:auto">Qayta urinish</button>' +
      '</div>';
    document.getElementById("retryLoadBtn").addEventListener("click", retryFn);
  }

  function isNetworkError(err) {
    return err instanceof TypeError;
  }

  // ---------- API ----------

  function api(path, opts) {
    opts = opts || {};
    var headers = opts.headers || {};
    headers["Content-Type"] = "application/json";
    if (state.accessToken) headers["Authorization"] = "Bearer " + state.accessToken;
    if (opts.idempotencyKey) headers["Idempotency-Key"] = opts.idempotencyKey;
    return fetch(API + path, {
      method: opts.method || "GET",
      headers: headers,
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    }).then(function (res) {
      if (res.status === 401) {
        clearSession();
        throw new Error("SHU SESSIYA TUGADI");
      }
      if (!res.ok) {
        return res.json().catch(function () { return {}; }).then(function (data) {
          throw new Error(data.detail || ("Xatolik: " + res.status));
        });
      }
      if (res.status === 204) return null;
      return res.json();
    });
  }

  // ---------- auth ----------

  function clearSession() {
    state.accessToken = null;
    try { localStorage.removeItem(TOKEN_KEY); } catch (e) { /* noop */ }
    // Access token muddati qisqa (15 daqiqa) — Telegram ichida bo'lsa
    // initData hali amal qiladi, foydalanuvchiga bildirmasdan qayta kirish
    if (tg && tg.initData) {
      showScreen("loading");
      authWithInitData(tg.initData);
    } else {
      showScreen("telegramOnly");
    }
  }

  function boot() {
    var saved = null;
    try { saved = localStorage.getItem(TOKEN_KEY); } catch (e) { /* privacy mode */ }
    if (saved) {
      state.accessToken = saved;
      startApp();
      return;
    }
    if (tg && tg.initData) {
      showScreen("loading");
      authWithInitData(tg.initData);
    } else {
      showScreen("telegramOnly");
    }
  }

  function authWithInitData(initData) {
    api("/auth/telegram/webapp", { method: "POST", body: { init_data: initData } })
      .then(function (tokens) {
        onAuthSuccess(tokens);
      })
      .catch(function (err) {
        showScreen("authError");
        document.getElementById("authErrorText").textContent =
          isNetworkError(err) ? "Internet aloqasi yo'q. Ilovani qayta oching." : (err.message || "Kirishda xatolik yuz berdi");
      });
  }

  function onAuthSuccess(tokens) {
    state.accessToken = tokens.access_token;
    try { localStorage.setItem(TOKEN_KEY, tokens.access_token); } catch (e) { /* noop */ }
    startApp();
  }

  // ---------- ekranlar ----------

  function showScreen(name) {
    document.getElementById("screenLoading").classList.toggle("hidden", name !== "loading");
    document.getElementById("screenTelegramOnly").classList.toggle("hidden", name !== "telegramOnly");
    document.getElementById("screenAuthError").classList.toggle("hidden", name !== "authError");
    document.getElementById("app").classList.toggle("hidden", name !== "app");
  }

  function startApp() {
    showScreen("app");
    loadCategories();
    refreshCart();
    switchTab("catalog");
  }

  function showAppScreen(name) {
    ["screenCatalog", "screenProducts", "screenProduct", "screenCart", "screenCheckout", "screenSuccess", "screenOrders"]
      .forEach(function (id) { document.getElementById(id).classList.toggle("hidden", id !== name); });
  }

  function switchTab(tab) {
    state.activeTab = tab;
    state.currentScreen = tab;
    document.querySelectorAll(".tab-item").forEach(function (el) {
      el.classList.toggle("active", el.getAttribute("data-tab") === tab);
    });
    if (tab === "catalog") showAppScreen("screenCatalog");
    else if (tab === "cart") { showAppScreen("screenCart"); refreshCart(); }
    else if (tab === "orders") { showAppScreen("screenOrders"); loadOrders(); }
    updateBackButton();
    updateMainButton();
  }

  // ---------- Telegram BackButton / MainButton ----------

  function updateBackButton() {
    if (!tg || !tg.BackButton) return;
    var isRoot = state.currentScreen === "catalog" || state.currentScreen === "cart" || state.currentScreen === "orders";
    if (isRoot) tg.BackButton.hide(); else tg.BackButton.show();
  }

  function handleBackButton() {
    if (state.currentScreen === "products") switchTab("catalog");
    else if (state.currentScreen === "product") {
      showAppScreen("screenProducts");
      state.currentScreen = "products";
      updateBackButton();
      updateMainButton();
    } else if (state.currentScreen === "checkout") switchTab("cart");
    else if (state.currentScreen === "success") switchTab("catalog");
  }

  if (tg && tg.BackButton) {
    tg.onEvent("backButtonClicked", handleBackButton);
  }

  // Cart/checkout uchun Telegram'ning o'z MainButton'i ishlatiladi — pastda
  // muallaq turadigan sahifa ichi tugma emas.
  function updateMainButton() {
    if (!tg || !tg.MainButton) return;
    if (state.currentScreen === "cart") {
      if (state.cart.length) {
        tg.MainButton.setText("Buyurtma berish");
        tg.MainButton.show();
        tg.MainButton.enable();
      } else {
        tg.MainButton.hide();
      }
    } else if (state.currentScreen === "checkout") {
      tg.MainButton.setText("Tasdiqlash");
      tg.MainButton.show();
      var addressEl = document.getElementById("addressInput");
      var valid = state.checkoutDeliveryType === "pickup" || (addressEl && addressEl.value.trim());
      if (valid) tg.MainButton.enable(); else tg.MainButton.disable();
    } else {
      tg.MainButton.hide();
    }
  }

  if (tg && tg.MainButton) {
    tg.onEvent("mainButtonClicked", function () {
      if (state.currentScreen === "cart") openCheckout();
      else if (state.currentScreen === "checkout") submitOrder();
    });
  }

  // Savat bo'sh bo'lmasa, Mini App tasodifan yopilib buyurtma yo'qolib
  // ketmasin — Telegram yopishdan oldin tasdiq so'raydi.
  function updateClosingConfirmation() {
    if (!tg) return;
    if (state.cart.length && tg.enableClosingConfirmation) tg.enableClosingConfirmation();
    else if (tg.disableClosingConfirmation) tg.disableClosingConfirmation();
  }

  // ---------- katalog ----------

  function loadCategories(isRetry) {
    var grid = document.getElementById("catGrid");
    var cached = cacheGet("categories");
    if (cached && !isRetry) {
      state.categories = cached;
      renderCategories();
    } else if (!cached) {
      grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1"><div class="small">Yuklanmoqda...</div></div>';
    }
    api("/categories").then(function (cats) {
      state.categories = cats;
      cacheSet("categories", cats);
      renderCategories();
    }).catch(function (err) {
      if (!cached) {
        if (isNetworkError(err)) renderLoadError(grid, function () { loadCategories(true); });
        else showToast(err.message);
      }
    });
  }

  function renderCategories() {
    var grid = document.getElementById("catGrid");
    if (!state.categories.length) {
      grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1">' +
        '<div class="big">Hozircha kategoriya yo\'q</div>' +
        '<div class="small">Tez orada mahsulotlar qo\'shiladi</div></div>';
      return;
    }
    grid.innerHTML = state.categories.map(function (c) {
      var tint = c.color || "#E3ECFA";
      return '<div class="cat-card" data-id="' + c.id + '">' +
        '<div class="cat-badge" style="background:' + escapeHtml(tint) + '22;color:' + escapeHtml(tint) + '">' +
        (c.thumb_url
          ? '<img class="cat-thumb-img" src="' + escapeHtml(c.thumb_url) + '" style="width:100%;height:100%;object-fit:cover;border-radius:12px">'
          : escapeHtml(catInitial(c.name))) +
        '</div>' +
        '<div class="name">' + escapeHtml(c.name) + '</div>' +
        '<div class="count">' + (c.product_count || 0) + ' ta mahsulot</div>' +
        '</div>';
    }).join("");
    wireImgFallback(grid, ".cat-thumb-img", "ic");
    grid.querySelectorAll(".cat-card").forEach(function (el) {
      el.addEventListener("click", function () {
        haptic("selection");
        var cat = state.categories.filter(function (c) { return String(c.id) === el.getAttribute("data-id"); })[0];
        openCategory(cat);
      });
    });
  }

  function openCategory(cat, isRetry) {
    state.activeCategory = cat;
    state.currentScreen = "products";
    showAppScreen("screenProducts");
    updateBackButton();
    updateMainButton();
    document.getElementById("productsTitle").textContent = cat.name;
    var list = document.getElementById("productsList");
    var cacheKey = "products_" + cat.id;
    var cached = cacheGet(cacheKey);
    if (cached && !isRetry) {
      state.products = cached;
      renderProducts();
    } else if (!cached) {
      list.innerHTML = '<div class="empty-state"><div class="small">Yuklanmoqda...</div></div>';
    }
    api("/products?category_id=" + cat.id + "&limit=100").then(function (page) {
      state.products = page.items;
      cacheSet(cacheKey, page.items);
      if (state.activeCategory && state.activeCategory.id === cat.id) renderProducts();
    }).catch(function (err) {
      if (!cached) {
        if (isNetworkError(err)) renderLoadError(list, function () { openCategory(cat, true); });
        else showToast(err.message);
      }
    });
  }

  function renderProducts() {
    var list = document.getElementById("productsList");
    if (!state.products.length) {
      list.innerHTML = '<div class="empty-state">' +
        '<div class="big">Bu kategoriyada mahsulot yo\'q</div>' +
        '<div class="small">Tez orada qo\'shiladi</div></div>';
      return;
    }
    list.innerHTML = state.products.map(function (p) {
      var priceText = p.min_price != null
        ? (p.min_price === p.max_price ? formatPrice(p.min_price) : formatPrice(p.min_price) + " dan")
        : "";
      var out = (p.total_stock || 0) <= 0;
      return '<div class="prod-card" data-id="' + p.id + '">' +
        '<div class="prod-thumb">' +
        (p.thumb_url
          ? '<img class="prod-thumb-img" src="' + escapeHtml(p.thumb_url) + '">'
          : iconSvg("ic")) +
        '</div>' +
        '<div class="prod-info">' +
        '<div class="name">' + escapeHtml(p.name) + '</div>' +
        (out ? '<div class="stock-out">Tugagan</div>' : '<div class="price">' + priceText + '</div>') +
        '</div></div>';
    }).join("");
    wireImgFallback(list, ".prod-thumb-img", "ic");
    list.querySelectorAll(".prod-card").forEach(function (el) {
      el.addEventListener("click", function () {
        var p = state.products.filter(function (x) { return String(x.id) === el.getAttribute("data-id"); })[0];
        openProduct(p.id);
      });
    });
  }

  function openProduct(id) {
    state.currentScreen = "product";
    showAppScreen("screenProduct");
    updateBackButton();
    updateMainButton();
    var wrap = document.getElementById("productDetail");
    wrap.innerHTML = '<div class="empty-state"><div class="small">Yuklanmoqda...</div></div>';
    api("/products/" + id).then(function (p) {
      state.activeProduct = p;
      var activeVariants = p.variants.filter(function (v) { return v.is_active; });
      state.activeVariantId = activeVariants.length ? activeVariants[0].id : (p.variants[0] ? p.variants[0].id : null);
      state.qty = 1;
      renderProductDetail();
    }).catch(function (err) {
      if (isNetworkError(err)) renderLoadError(wrap, function () { openProduct(id); });
      else showToast(err.message);
    });
  }

  function activeVariant() {
    var p = state.activeProduct;
    if (!p) return null;
    return p.variants.filter(function (v) { return v.id === state.activeVariantId; })[0] || null;
  }

  function renderProductDetail() {
    var p = state.activeProduct;
    var v = activeVariant();
    var wrap = document.getElementById("productDetail");
    var stock = v ? v.stock : 0;
    var outOfStock = !v || stock <= 0;

    var variantsHtml = "";
    if (p.variants.length > 1) {
      variantsHtml = '<div class="variant-row">' + p.variants.map(function (vv) {
        var cls = "variant-chip" + (vv.id === state.activeVariantId ? " active" : "") + (vv.is_active ? "" : " disabled");
        return '<div class="' + cls + '" data-vid="' + vv.id + '">' + escapeHtml(vv.variant_name) + '</div>';
      }).join("") + '</div>';
    }

    wrap.innerHTML =
      '<div class="detail-img">' +
      (p.thumb_url || p.image_url
        ? '<img class="detail-img-el" src="' + escapeHtml(p.thumb_url || p.image_url) + '">'
        : iconSvg("ic")) +
      '</div>' +
      '<div class="detail-name">' + escapeHtml(p.name) + '</div>' +
      '<div class="detail-price">' + (v ? formatPrice(v.price) : "") + '</div>' +
      (p.description ? '<div class="detail-desc">' + escapeHtml(p.description) + '</div>' : "") +
      variantsHtml +
      (outOfStock
        ? '<div class="stock-note" style="color:#DC2626;font-weight:700">Tugagan</div>'
        : '<div class="qty-row"><div class="label">Miqdor</div><div class="qty-ctrl">' +
          '<div class="qty-btn" id="qtyMinus">-</div><div class="qty-val" id="qtyVal">' + state.qty + '</div>' +
          '<div class="qty-btn" id="qtyPlus">+</div></div></div>' +
          '<div class="stock-note">Omborda: ' + stock + ' ta</div>') +
      '<div class="cta-spacer"></div>' +
      '<div class="fixed-cta"><button class="btn btn-primary" id="addToCartBtn"' + (outOfStock ? " disabled" : "") + '>Savatga qo\'shish</button></div>';

    wireImgFallback(wrap, ".detail-img-el", "ic");
    wrap.querySelectorAll(".variant-chip").forEach(function (el) {
      el.addEventListener("click", function () {
        if (el.classList.contains("disabled")) return;
        haptic("selection");
        state.activeVariantId = parseInt(el.getAttribute("data-vid"), 10);
        state.qty = 1;
        renderProductDetail();
      });
    });
    var minus = document.getElementById("qtyMinus");
    var plus = document.getElementById("qtyPlus");
    if (minus) minus.addEventListener("click", function () {
      if (state.qty > 1) { state.qty--; haptic("selection"); updateQtyLabel(); }
    });
    if (plus) plus.addEventListener("click", function () {
      var v2 = activeVariant();
      if (v2 && state.qty < v2.stock) { state.qty++; haptic("selection"); updateQtyLabel(); }
    });
    var addBtn = document.getElementById("addToCartBtn");
    if (addBtn) addBtn.addEventListener("click", addActiveToCart);
  }

  function updateQtyLabel() {
    var el = document.getElementById("qtyVal");
    if (el) el.textContent = state.qty;
  }

  function addActiveToCart() {
    var v = activeVariant();
    if (!v) return;
    api("/cart", { method: "POST", body: { variant_id: v.id, quantity: state.qty } })
      .then(function () {
        haptic("light");
        showToast("Savatga qo'shildi", 1200);
        refreshCart();
      })
      .catch(function (err) {
        showToast(isNetworkError(err) ? "Internet aloqasi yo'q" : err.message);
      });
  }

  // ---------- savat ----------

  function refreshCart() {
    if (!state.accessToken) return;
    api("/cart").then(function (items) {
      state.cart = items;
      renderCartBadge();
      updateClosingConfirmation();
      if (state.activeTab === "cart") renderCart();
      updateMainButton();
    }).catch(function () { /* jim — badge yangilanmaydi */ });
  }

  function renderCartBadge() {
    // Miqdorlar yig'indisi emas — savatdagi TURLI mahsulot (qator) soni.
    // Masalan bitta ruchkadan 10 ta olingan bo'lsa ham badge "1" ko'rsatadi.
    var badge = document.getElementById("cartBadge");
    var lineCount = state.cart.length;
    if (lineCount > 0) { badge.textContent = lineCount; badge.classList.remove("hidden"); }
    else badge.classList.add("hidden");
  }

  var hasNativeMainButton = !!(tg && tg.MainButton);

  function renderCart() {
    var list = document.getElementById("cartList");
    if (!state.cart.length) {
      list.innerHTML = '<div class="empty-state">' +
        '<div class="big">Savat bo\'sh</div>' +
        '<div class="small">Katalogdan mahsulot qo\'shing</div></div>';
      updateMainButton();
      return;
    }
    var total = state.cart.reduce(function (s, i) { return s + (i.price || 0) * i.quantity; }, 0);
    list.innerHTML = state.cart.map(function (i) {
      return '<div class="cart-item" data-id="' + i.id + '">' +
        '<div style="flex:1;min-width:0">' +
        '<div class="name">' + escapeHtml(i.product_name || i.variant_name || "Mahsulot") + '</div>' +
        '<div class="price">' + formatPrice(i.price) + ' x ' + i.quantity + '</div>' +
        '<div class="row2">' +
        '<div class="qty-ctrl"><div class="qty-btn cart-minus">-</div>' +
        '<div class="qty-val">' + i.quantity + '</div><div class="qty-btn cart-plus">+</div></div>' +
        '<div class="line-total">' + formatPrice((i.price || 0) * i.quantity) + '</div>' +
        '</div></div>' +
        '<div class="cart-remove"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></div>' +
        '</div>';
    }).join("") +
      '<div class="cart-summary"><div class="row"><div class="label">Jami</div><div class="value">' + formatPrice(total) + '</div></div></div>' +
      // Tabbar har doim ko'rinadi (native MainButton bo'lsa ham) — shuning
      // uchun spacer shartsiz qo'shiladi, tugma esa faqat fallback rejimida.
      '<div class="cta-spacer"></div>' +
      (hasNativeMainButton ? "" : '<div class="fixed-cta"><button class="btn btn-primary" id="checkoutBtn">Buyurtma berish</button></div>');

    list.querySelectorAll(".cart-item").forEach(function (el) {
      var id = parseInt(el.getAttribute("data-id"), 10);
      var item = state.cart.filter(function (i) { return i.id === id; })[0];
      el.querySelector(".cart-minus").addEventListener("click", function () {
        var q = item.quantity - 1;
        if (q <= 0) removeCartItem(id); else updateCartQty(id, q);
      });
      el.querySelector(".cart-plus").addEventListener("click", function () {
        if (item.quantity < (item.stock || 999)) updateCartQty(id, item.quantity + 1);
        else showToast("Omborda shuncha qoldi");
      });
      el.querySelector(".cart-remove").addEventListener("click", function () { removeCartItem(id); });
    });
    var checkoutBtn = document.getElementById("checkoutBtn");
    if (checkoutBtn) checkoutBtn.addEventListener("click", openCheckout);
    updateMainButton();
  }

  function updateCartQty(id, qty) {
    api("/cart/" + id + "?quantity=" + qty, { method: "PATCH" })
      .then(function () { haptic("selection"); refreshCart(); })
      .catch(function (err) { showToast(isNetworkError(err) ? "Internet aloqasi yo'q" : err.message); });
  }

  function removeCartItem(id) {
    api("/cart/" + id, { method: "DELETE" })
      .then(function () { haptic("light"); refreshCart(); })
      .catch(function (err) { showToast(isNetworkError(err) ? "Internet aloqasi yo'q" : err.message); });
  }

  // ---------- checkout ----------

  function openCheckout() {
    if (!state.cart.length) return;
    state.currentScreen = "checkout";
    showAppScreen("screenCheckout");
    updateBackButton();
    state.checkoutDeliveryType = "delivery";
    renderCheckout();
  }

  function renderCheckout() {
    var form = document.getElementById("checkoutForm");
    var total = state.cart.reduce(function (s, i) { return s + (i.price || 0) * i.quantity; }, 0);
    form.innerHTML =
      '<div class="seg">' +
      '<button data-t="delivery" class="' + (state.checkoutDeliveryType === "delivery" ? "active" : "") + '">Yetkazib berish</button>' +
      '<button data-t="pickup" class="' + (state.checkoutDeliveryType === "pickup" ? "active" : "") + '">O\'zim olib ketaman</button>' +
      '</div>' +
      '<div class="field" id="addressField">' +
      '<label class="field-label">Manzil</label>' +
      '<textarea id="addressInput" rows="3" placeholder="Shahar, tuman, ko\'cha, uy..."></textarea>' +
      '</div>' +
      '<div class="field">' +
      '<label class="field-label">Izoh (ixtiyoriy)</label>' +
      '<textarea id="noteInput" rows="2" placeholder="Masalan: domofon kodi"></textarea>' +
      '</div>' +
      '<div class="cart-summary" style="margin-bottom:16px"><div class="row"><div class="label">Jami to\'lov</div><div class="value">' + formatPrice(total) + '</div></div></div>' +
      '<div style="font-size:12.5px;color:var(--text-muted);margin-bottom:16px;line-height:1.45">To\'lov naqd — kuryer POS terminali orqali yetkazib berishda amalga oshiriladi.</div>' +
      '<div class="cta-spacer"></div>' +
      (hasNativeMainButton ? "" : '<div class="fixed-cta"><button class="btn btn-primary" id="submitOrderBtn">Buyurtmani tasdiqlash</button></div>');

    form.querySelectorAll(".seg button").forEach(function (b) {
      b.addEventListener("click", function () {
        state.checkoutDeliveryType = b.getAttribute("data-t");
        renderCheckout();
      });
    });
    document.getElementById("addressField").classList.toggle("hidden", state.checkoutDeliveryType === "pickup");
    var addressInput = document.getElementById("addressInput");
    if (addressInput) addressInput.addEventListener("input", updateMainButton);
    var submitBtn = document.getElementById("submitOrderBtn");
    if (submitBtn) submitBtn.addEventListener("click", submitOrder);
    updateMainButton();
  }

  function submitOrder() {
    var deliveryType = state.checkoutDeliveryType;
    var address = document.getElementById("addressInput") ? document.getElementById("addressInput").value.trim() : "";
    var note = document.getElementById("noteInput").value.trim();
    if (deliveryType === "delivery" && !address) {
      showToast("Manzilni kiriting");
      return;
    }
    var submitBtn = document.getElementById("submitOrderBtn");
    if (submitBtn) submitBtn.disabled = true;
    if (tg && tg.MainButton) tg.MainButton.showProgress(false);
    var idemKey = "miniapp-" + Date.now() + "-" + Math.random().toString(36).slice(2);
    api("/orders", {
      method: "POST",
      idempotencyKey: idemKey,
      body: {
        payment_method: "cash",
        delivery_type: deliveryType,
        delivery_address: deliveryType === "delivery" ? address : null,
        note: note || null,
      },
    }).then(function (order) {
      haptic("medium");
      if (tg && tg.MainButton) tg.MainButton.hideProgress();
      state.lastOrder = order;
      state.currentScreen = "success";
      showAppScreen("screenSuccess");
      updateBackButton();
      updateMainButton();
      var text = deliveryType === "pickup"
        ? "Buyurtma #" + order.id + " tayyor bo'lishi bilan xabar beramiz. Do'kondan olib ketish kodi:"
        : "Buyurtma #" + order.id + " qabul qilindi. Kuryer yetkazib berganda naqd to'lov qilinadi.";
      document.getElementById("successText").textContent = text;
      var pickupEl = document.getElementById("successPickup");
      if (order.pickup_code) { pickupEl.textContent = order.pickup_code; pickupEl.classList.remove("hidden"); }
      else pickupEl.classList.add("hidden");
      refreshCart();
    }).catch(function (err) {
      if (tg && tg.MainButton) tg.MainButton.hideProgress();
      showToast(isNetworkError(err) ? "Internet aloqasi yo'q" : err.message);
      if (submitBtn) submitBtn.disabled = false;
      updateMainButton();
    });
  }

  // ---------- buyurtmalarim ----------

  function loadOrders(isRetry) {
    var list = document.getElementById("ordersList");
    if (!isRetry) list.innerHTML = '<div class="empty-state"><div class="small">Yuklanmoqda...</div></div>';
    api("/orders").then(function (orders) {
      state.orders = orders;
      renderOrders();
    }).catch(function (err) {
      if (isNetworkError(err)) renderLoadError(list, function () { loadOrders(true); });
      else showToast(err.message);
    });
  }

  function renderOrders() {
    var list = document.getElementById("ordersList");
    if (!state.orders.length) {
      list.innerHTML = '<div class="empty-state">' +
        '<div class="big">Hali buyurtma yo\'q</div>' +
        '<div class="small">Birinchi xaridingizni qiling</div></div>';
      return;
    }
    list.innerHTML = state.orders.map(function (o) {
      var colors = STATUS_COLORS[o.status] || ["#E3ECFA", "#14243F"];
      var itemsText = o.items.map(function (i) { return i.product_name + " x" + i.quantity; }).join(", ");
      return '<div class="order-card">' +
        '<div class="head"><div><div class="num">Buyurtma #' + o.id + '</div>' +
        '<div class="time">' + escapeHtml(new Date(o.created_at).toLocaleString("uz-UZ")) + '</div></div>' +
        '<div class="status-badge" style="background:' + colors[0] + ';color:' + colors[1] + '">' +
        (STATUS_LABELS[o.status] || o.status) + '</div></div>' +
        '<div class="items-summary">' + escapeHtml(itemsText) + '</div>' +
        '<div class="total">' + formatPrice(o.total) + '</div>' +
        '</div>';
    }).join("");
  }

  // ---------- ulash ----------

  document.getElementById("productsBack").addEventListener("click", function () { switchTab("catalog"); });
  document.getElementById("productBack").addEventListener("click", function () {
    showAppScreen("screenProducts");
    state.currentScreen = "products";
    updateBackButton();
    updateMainButton();
  });
  document.getElementById("checkoutBack").addEventListener("click", function () { switchTab("cart"); });
  document.getElementById("successContinueBtn").addEventListener("click", function () { switchTab("catalog"); });
  document.querySelectorAll(".tab-item").forEach(function (el) {
    el.addEventListener("click", function () { haptic("selection"); switchTab(el.getAttribute("data-tab")); });
  });

  window.addEventListener("offline", function () { showToast("Internet aloqasi yo'q"); });

  boot();
})();
