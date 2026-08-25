(function () {
  "use strict";

  var D = window.Dokon;
  var $ = D.$, api = D.api, escapeHtml = D.escapeHtml, formatSom = D.formatSom,
      minutesAgo = D.minutesAgo, showToast = D.showToast, showScreen = D.showScreen,
      categoryIconSvg = D.categoryIconSvg;

  var state = {
    categories: [],
    products: [],
    productSearch: "",
    productCategoryFilter: "",
    productsPollTimer: null,
    categoriesPollTimer: null,
    // mahsulot formasi
    editingProductId: null,   // null = yangi mahsulot
    productDetail: null,      // to'liq obyekt (tahrirlashda), rev shu yerdan
    formImages: [],           // {source:"queued", file, previewUrl} | {source:"saved", id, image_url, thumb_url, is_main}
    formParams: [],           // [{name, values:[...]}]
    formVariants: null,       // tahrirlashda mavjud variantlar ro'yxati (backenddan)
    // kategoriya formasi
    editingCategoryId: null,
    categoryFormImage: null,  // {source:"queued", file, previewUrl} | null
    hiddenInputHandler: null,
  };

  async function rawGet(path) {
    var res = await fetch(path, { credentials: "same-origin" });
    if (!res.ok) throw { status: res.status };
    return res.json();
  }

  function noImageIconSvg() {
    return '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16v14H4zM4 15l4.5-5 4 4 2.5-2.5L19 15"/><circle cx="9" cy="9" r="1.3" fill="currentColor" stroke="none"/></svg>';
  }

  function metaLine(obj) {
    if (!obj.created_by) return "";
    var parts = [];
    parts.push(escapeHtml(obj.created_by) + " qo'shdi");
    if (obj.updated_by && obj.updated_by !== obj.created_by) {
      parts.push(escapeHtml(obj.updated_by) + " oxirgi tahrirladi");
    }
    if (obj.updated_at) parts.push(minutesAgo(obj.updated_at));
    return parts.join(" · ");
  }

  function slugify(s) {
    return String(s || "")
      .toLowerCase()
      .replace(/[ʻʼ'’‘`]/g, "")
      .replace(/[^a-z0-9а-яё]+/gi, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 140) || "kategoriya";
  }

  // ================= MAHSULOTLAR RO'YXATI =================

  async function showProducts() {
    D.stopPolling();
    stopCategoriesPolling();
    showScreen("screenProducts");
    D.renderAllSectionNavs("products");
    await loadCategories();
    fillCategoryFilterSelect();
    await loadProducts();
    startProductsPolling();
  }

  async function loadCategories() {
    try { state.categories = await rawGet("/categories"); } catch (e) { state.categories = state.categories || []; }
  }

  function fillCategoryFilterSelect() {
    var sel = $("productCategoryFilter");
    var current = sel.value;
    sel.innerHTML = '<option value="">Barcha kategoriya</option>' +
      state.categories.map(function (c) {
        return '<option value="' + c.id + '">' + escapeHtml(c.name) + '</option>';
      }).join("");
    sel.value = current;
  }

  function startProductsPolling() {
    if (state.productsPollTimer) return;
    state.productsPollTimer = setInterval(loadProducts, 12000);
  }
  function stopProductsPolling() {
    if (state.productsPollTimer) clearInterval(state.productsPollTimer);
    state.productsPollTimer = null;
  }

  var searchDebounce = null;
  $("productSearch").addEventListener("input", function () {
    clearTimeout(searchDebounce);
    var v = $("productSearch").value;
    searchDebounce = setTimeout(function () {
      state.productSearch = v.trim();
      loadProducts();
    }, 350);
  });
  $("productCategoryFilter").addEventListener("change", function () {
    state.productCategoryFilter = $("productCategoryFilter").value;
    loadProducts();
  });

  async function loadProducts() {
    var qs = new URLSearchParams();
    if (state.productSearch) qs.set("q", state.productSearch);
    if (state.productCategoryFilter) qs.set("category_id", state.productCategoryFilter);
    var items;
    try { items = await api("/products?" + qs.toString()); } catch (e) { return; }
    // Tahrirlanayotgan/band inputga fokus bo'lsa, poll uni bezovta qilmasin
    if (document.activeElement && document.activeElement.closest(".catalog-card")) return;
    state.products = items;
    renderProductsList();
  }

  function priceRangeText(p) {
    if (p.min_price == null) return "Narx kiritilmagan";
    if (p.min_price === p.max_price) return formatSom(p.min_price);
    return formatSom(p.min_price) + " – " + formatSom(p.max_price);
  }

  function renderProductsList() {
    var host = $("productsList");
    if (!state.products.length) {
      host.innerHTML = '<div class="empty-state"><div class="big">Mahsulot topilmadi</div><div class="small">Pastdagi + tugmasi bilan qo\'shing</div></div>';
      return;
    }
    host.innerHTML = "";
    state.products.forEach(function (p) { host.appendChild(renderProductCard(p)); });
  }

  function renderProductCard(p) {
    var card = document.createElement("div");
    card.className = "catalog-card";

    var thumb = document.createElement("div");
    thumb.className = "catalog-thumb";
    thumb.innerHTML = p.thumb_url ? '<img src="' + escapeHtml(p.thumb_url) + '">' : noImageIconSvg();

    var body = document.createElement("div");
    body.className = "catalog-body";
    var statusPill = "";
    if (p.status === "pending") statusPill = '<span class="status-pill pending">Ko\'rib chiqilmoqda</span>';
    if (!p.is_active) statusPill += '<span class="status-pill hidden-pill">Yashirilgan</span>';
    var name = document.createElement("div");
    name.className = "catalog-name";
    name.innerHTML = escapeHtml(p.name) + statusPill;
    var meta = document.createElement("div");
    meta.className = "catalog-meta";
    meta.textContent = (p.category_name || "Kategoriyasiz") + (p.variant_count > 1 ? " · " + p.variant_count + " variant" : "") +
      (metaLine(p) ? " · " + metaLine(p) : "");
    var price = document.createElement("div");
    price.className = "catalog-price";
    price.textContent = priceRangeText(p) + " · Zaxira: " + p.total_stock;

    body.appendChild(name);
    body.appendChild(meta);
    body.appendChild(price);

    if (p.variant_count === 1) {
      var quick = document.createElement("div");
      quick.className = "quick-row";
      quick.innerHTML =
        '<span class="quick-label">Tez zaxira:</span>' +
        '<input type="number" min="0" class="quick-input" value="' + p.total_stock + '">';
      var input = quick.querySelector("input");
      input.addEventListener("click", function (e) { e.stopPropagation(); });
      input.addEventListener("change", async function (e) {
        e.stopPropagation();
        var v = parseInt(input.value, 10);
        if (isNaN(v) || v < 0) { input.value = p.total_stock; return; }
        try {
          await api("/products/" + p.id + "/variants/" + p.single_variant_id, {
            method: "PATCH", body: JSON.stringify({ stock: v }),
          });
          showToast("Zaxira yangilandi");
          loadProducts();
        } catch (err) {
          showToast(err.detail || "Saqlanmadi");
        }
      });
      body.appendChild(quick);
    }

    var actions = document.createElement("div");
    actions.className = "quick-row";
    actions.style.marginTop = "10px";
    var editBtn = document.createElement("button");
    editBtn.className = "btn btn-secondary";
    editBtn.style.height = "38px";
    editBtn.style.flex = "1";
    editBtn.style.fontSize = "13px";
    editBtn.textContent = "Tahrirlash";
    editBtn.addEventListener("click", function (e) { e.stopPropagation(); openProductForm(p.id); });

    var visBtn = document.createElement("div");
    visBtn.className = "icon-link";
    visBtn.title = p.is_active ? "Yashirish" : "Ko'rsatish";
    visBtn.innerHTML = p.is_active
      ? '<svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/></svg>'
      : '<svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M17.94 17.94A10.94 10.94 0 0 1 12 19c-7 0-11-7-11-7a21.6 21.6 0 0 1 5.06-5.94M9.9 4.24A10.94 10.94 0 0 1 12 5c7 0 11 7 11 7a21.6 21.6 0 0 1-2.16 3.19M14.12 14.12a3 3 0 1 1-4.24-4.24M1 1l22 22"/></svg>';
    visBtn.addEventListener("click", async function (e) {
      e.stopPropagation();
      try {
        await api("/products/" + p.id, { method: "PATCH", body: JSON.stringify({ is_active: !p.is_active }) });
        loadProducts();
      } catch (err) { showToast(err.detail || "Xato"); }
    });

    var delBtn = document.createElement("div");
    delBtn.className = "icon-link";
    delBtn.title = "O'chirish";
    delBtn.innerHTML = '<svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="var(--danger)" stroke-width="1.8"><path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14"/></svg>';
    delBtn.addEventListener("click", async function (e) {
      e.stopPropagation();
      if (!confirm('"' + p.name + '" mahsulotini o\'chirmoqchimisiz?')) return;
      try {
        await api("/products/" + p.id, { method: "DELETE" });
        showToast("O'chirildi");
        loadProducts();
      } catch (err) { showToast(err.detail || "O'chirib bo'lmadi"); }
    });

    actions.appendChild(editBtn);
    actions.appendChild(visBtn);
    actions.appendChild(delBtn);
    body.appendChild(actions);

    card.appendChild(thumb);
    card.appendChild(body);
    return card;
  }

  $("addProductBtn").addEventListener("click", function () { openProductForm(null); });

  // ================= KATEGORIYALAR RO'YXATI =================

  async function showCategories() {
    D.stopPolling();
    stopProductsPolling();
    showScreen("screenCategories");
    D.renderAllSectionNavs("categories");
    await loadCategories();
    renderCategoriesList();
    startCategoriesPolling();
  }

  function startCategoriesPolling() {
    if (state.categoriesPollTimer) return;
    state.categoriesPollTimer = setInterval(async function () {
      await loadCategories();
      renderCategoriesList();
    }, 12000);
  }
  function stopCategoriesPolling() {
    if (state.categoriesPollTimer) clearInterval(state.categoriesPollTimer);
    state.categoriesPollTimer = null;
  }

  function renderCategoriesList() {
    var host = $("categoriesList");
    if (!state.categories.length) {
      host.innerHTML = '<div class="empty-state"><div class="big">Kategoriya yo\'q</div></div>';
      return;
    }
    host.innerHTML = "";
    state.categories.slice().sort(function (a, b) { return a.sort_order - b.sort_order; }).forEach(function (c) {
      host.appendChild(renderCategoryCard(c));
    });
  }

  function renderCategoryCard(c) {
    var card = document.createElement("div");
    card.className = "catalog-card";
    var thumb = document.createElement("div");
    thumb.className = "catalog-thumb";
    thumb.innerHTML = c.thumb_url ? '<img src="' + escapeHtml(c.thumb_url) + '">' : categoryIconSvg(c.slug, "");
    var body = document.createElement("div");
    body.className = "catalog-body";
    body.innerHTML =
      '<div class="catalog-name">' + escapeHtml(c.name) + '</div>' +
      '<div class="catalog-meta">' + (c.product_count || 0) + ' ta mahsulot</div>';
    var actions = document.createElement("div");
    actions.className = "quick-row";
    actions.style.marginTop = "10px";
    var editBtn = document.createElement("button");
    editBtn.className = "btn btn-secondary";
    editBtn.style.height = "38px"; editBtn.style.flex = "1"; editBtn.style.fontSize = "13px";
    editBtn.textContent = "Tahrirlash";
    editBtn.addEventListener("click", function () { openCategoryForm(c.id); });
    var delBtn = document.createElement("div");
    delBtn.className = "icon-link";
    delBtn.title = "O'chirish";
    delBtn.innerHTML = '<svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="var(--danger)" stroke-width="1.8"><path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14"/></svg>';
    delBtn.addEventListener("click", async function () {
      if (!confirm('"' + c.name + '" kategoriyasini o\'chirmoqchimisiz?')) return;
      try {
        await api("/categories/" + c.id, { method: "DELETE" });
        showToast("O'chirildi");
        await loadCategories();
        renderCategoriesList();
      } catch (err) { showToast(err.detail || "O'chirib bo'lmadi"); }
    });
    actions.appendChild(editBtn);
    actions.appendChild(delBtn);
    body.appendChild(actions);
    card.appendChild(thumb);
    card.appendChild(body);
    return card;
  }

  $("addCategoryBtn").addEventListener("click", function () { openCategoryForm(null); });

  function closeCategoryForm() {
    $("categoryFormOverlay").classList.add("hidden");
    if (state.categoryFormImage && state.categoryFormImage.previewUrl) {
      URL.revokeObjectURL(state.categoryFormImage.previewUrl);
    }
    state.categoryFormImage = null;
    state.editingCategoryId = null;
  }

  function openCategoryForm(categoryId) {
    state.editingCategoryId = categoryId;
    state.categoryFormImage = null;
    var cat = categoryId ? state.categories.find(function (c) { return c.id === categoryId; }) : null;
    var sheet = $("categoryFormSheet");
    sheet.innerHTML =
      '<h2>' + (cat ? "Kategoriyani tahrirlash" : "Yangi kategoriya") + '</h2>' +
      '<div class="field" style="margin-top:14px">' +
      '  <div class="image-tile" id="catFormImageTile" style="width:100%;height:120px;border-radius:16px;margin-bottom:12px">' +
      (cat && cat.thumb_url ? '<img src="' + escapeHtml(cat.thumb_url) + '">' : '<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;color:var(--text-muted)">' + noImageIconSvg() + '</div>') +
      '  </div>' +
      '  <button type="button" class="btn btn-secondary" id="catFormPickImage" style="width:100%;height:44px;font-size:13.5px;margin-bottom:14px">Rasm tanlash</button>' +
      '</div>' +
      '<div class="field">' +
      '  <label>Nomi</label>' +
      '  <input type="text" id="catFormName" value="' + (cat ? escapeHtml(cat.name) : "") + '">' +
      '</div>' +
      '<div class="field">' +
      '  <label>Slug</label>' +
      '  <input type="text" id="catFormSlug" value="' + (cat ? escapeHtml(cat.slug) : "") + '">' +
      '</div>' +
      '<div id="catFormError" class="error-box hidden"></div>' +
      '<div class="modal-actions">' +
      '  <button type="button" class="btn btn-secondary" id="catFormCancel">Bekor qilish</button>' +
      '  <button type="button" class="btn btn-primary" id="catFormSave">Saqlash</button>' +
      '</div>';
    $("categoryFormOverlay").classList.remove("hidden");

    var nameInput = $("catFormName"), slugInput = $("catFormSlug");
    var slugTouched = !!cat;
    nameInput.addEventListener("input", function () {
      if (!slugTouched) slugInput.value = slugify(nameInput.value);
    });
    slugInput.addEventListener("input", function () { slugTouched = true; });

    $("catFormPickImage").addEventListener("click", function () {
      openHiddenFilePicker(function (file) {
        if (state.categoryFormImage && state.categoryFormImage.previewUrl) URL.revokeObjectURL(state.categoryFormImage.previewUrl);
        var url = URL.createObjectURL(file);
        state.categoryFormImage = { file: file, previewUrl: url };
        $("catFormImageTile").innerHTML = '<img src="' + url + '">';
      });
    });

    $("catFormCancel").addEventListener("click", closeCategoryForm);
    $("catFormSave").addEventListener("click", saveCategoryForm);
  }

  async function saveCategoryForm() {
    var name = $("catFormName").value.trim();
    var slug = $("catFormSlug").value.trim();
    var errBox = $("catFormError");
    errBox.classList.add("hidden");
    if (!name || !slug) {
      errBox.textContent = "Nom va slug to'ldirilishi shart";
      errBox.classList.remove("hidden");
      return;
    }
    var btn = $("catFormSave");
    btn.disabled = true;
    try {
      var cat;
      if (state.editingCategoryId) {
        cat = await api("/categories/" + state.editingCategoryId, {
          method: "PATCH", body: JSON.stringify({ name: name, slug: slug }),
        });
      } else {
        cat = await api("/categories", { method: "POST", body: JSON.stringify({ name: name, slug: slug }) });
      }
      if (state.categoryFormImage) {
        var fd = new FormData();
        fd.append("file", state.categoryFormImage.file);
        await fetch("/dokon-api/categories/" + cat.id + "/image", { method: "POST", body: fd, credentials: "same-origin" });
      }
      showToast(state.editingCategoryId ? "Saqlandi" : "Kategoriya qo'shildi");
      closeCategoryForm();
      await loadCategories();
      renderCategoriesList();
      fillCategoryFilterSelect();
    } catch (err) {
      errBox.textContent = err.detail || "Saqlab bo'lmadi";
      errBox.classList.remove("hidden");
    } finally {
      btn.disabled = false;
    }
  }

  // ================= FAYL TANLASH (umumiy yashirin input) =================

  function openHiddenFilePicker(onPicked) {
    var input = $("hiddenFileInput");
    state.hiddenInputHandler = onPicked;
    input.value = "";
    input.click();
  }
  $("hiddenFileInput").addEventListener("change", function () {
    var file = $("hiddenFileInput").files[0];
    if (file && state.hiddenInputHandler) state.hiddenInputHandler(file);
    state.hiddenInputHandler = null;
  });

  // ================= MAHSULOT FORMASI =================

  function comboLabel(attrs) {
    var values = Object.keys(attrs || {}).map(function (k) { return attrs[k]; });
    return values.length ? values.join(" / ") : "Standart";
  }

  function cartesianCombos(params) {
    var clean = params
      .map(function (p) { return { name: p.name.trim(), values: p.values.map(function (v) { return v.trim(); }).filter(Boolean) }; })
      .filter(function (p) { return p.name && p.values.length; });
    if (!clean.length) return [{}];
    return clean.reduce(function (acc, param) {
      var next = [];
      acc.forEach(function (combo) {
        param.values.forEach(function (v) {
          var copy = Object.assign({}, combo);
          copy[param.name] = v;
          next.push(copy);
        });
      });
      return next;
    }, [{}]);
  }

  async function openProductForm(productId) {
    state.editingProductId = productId;
    state.formImages = [];
    state.formParams = [];
    state.formVariants = null;
    state.productDetail = null;
    state.skuValues = {};
    showScreen("screenProductForm");
    $("productFormTitle").textContent = productId ? "Mahsulotni tahrirlash" : "Yangi mahsulot";
    $("productFormContent").innerHTML = '<div class="empty-state"><div class="big">Yuklanmoqda…</div></div>';
    await loadCategories();

    if (productId) {
      try {
        state.productDetail = await api("/products/" + productId);
      } catch (e) {
        showToast("Mahsulot topilmadi");
        $("productFormBackBtn").click();
        return;
      }
      state.formImages = buildSavedImageList(state.productDetail);
      state.formVariants = state.productDetail.variants.slice();
    }
    renderProductForm();
  }

  function currentCombos() {
    if (state.editingProductId) return null; // tahrirlashda kombinatsiya qayta hisoblanmaydi
    return cartesianCombos(state.formParams);
  }

  function renderProductForm() {
    var d = state.productDetail;
    var main = $("productFormContent");
    var html = "";

    html += '<div class="form-field"><label>Rasmlar</label><div class="image-grid" id="imageGrid"></div>' +
      '<div class="form-hint">Birinchi rasm — asosiy (mahsulot kartochkasida ko\'rinadi). Boshqasini bosib "Asosiy qilish" tanlang.</div></div>';

    html += '<div class="form-field"><label>Nomi</label><input type="text" id="pfName" value="' + (d ? escapeHtml(d.name) : "") + '"></div>';
    html += '<div class="form-field"><label>Brend</label><input type="text" id="pfBrand" value="' + (d && d.brand ? escapeHtml(d.brand) : "") + '"></div>';
    html += '<div class="form-field"><label>Tavsif</label><textarea id="pfDescription" rows="3">' + (d && d.description ? escapeHtml(d.description) : "") + '</textarea></div>';
    html += '<div class="form-field"><label>Kategoriya</label><select id="pfCategory">' +
      '<option value="">— tanlanmagan —</option>' +
      state.categories.map(function (c) {
        var sel = d && d.category_id === c.id ? " selected" : "";
        return '<option value="' + c.id + '"' + sel + '>' + escapeHtml(c.name) + '</option>';
      }).join("") + '</select></div>';

    if (!state.editingProductId) {
      html += '<div class="form-field"><label>Parametrlar (ixtiyoriy)</label><div id="paramBlocks"></div>' +
        '<button type="button" class="add-param-btn" id="addParamBtn">+ Parametr</button></div>';
    }

    html += '<div class="form-field"><label>' + (state.editingProductId ? "Variantlar (narx / zaxira)" : "Narx / zaxira") + '</label>' +
      '<table class="sku-table" id="skuTable"><thead><tr><th>Variant</th><th>Narx (so\'m)</th><th>Zaxira</th><th></th></tr></thead><tbody id="skuTableBody"></tbody></table>';
    if (state.editingProductId) {
      html += '<button type="button" class="add-param-btn" id="addVariantBtn" style="margin-top:10px">+ Yangi variant</button>';
    }
    html += '</div>';

    html += '<div id="pfError" class="error-box hidden" style="margin-top:4px"></div>';

    html += '<div class="form-sticky-bar"><div class="row">' +
      '<button type="button" class="btn btn-secondary" id="pfCancelBtn">Bekor qilish</button>' +
      '<button type="button" class="btn btn-primary" id="pfSaveBtn">Saqlash</button>' +
      '</div></div>';

    main.innerHTML = html;

    renderImageGrid();
    if (!state.editingProductId) {
      renderParamBlocks();
      $("addParamBtn").addEventListener("click", function () {
        state.formParams.push({ name: "", values: [] });
        renderParamBlocks();
      });
    } else {
      $("addVariantBtn").addEventListener("click", addManualVariantPrompt);
    }
    renderSkuTable();

    $("pfCancelBtn").addEventListener("click", function () { $("productFormBackBtn").click(); });
    $("pfSaveBtn").addEventListener("click", saveProductForm);
  }

  $("productFormBackBtn").addEventListener("click", function () {
    state.formImages.forEach(function (im) { if (im.source === "queued") URL.revokeObjectURL(im.previewUrl); });
    showProducts();
  });

  // ---- rasmlar ----
  function renderImageGrid() {
    var grid = $("imageGrid");
    grid.innerHTML = "";
    state.formImages.forEach(function (im, idx) {
      var tile = document.createElement("div");
      tile.className = "image-tile" + (idx === 0 ? " is-main" : "");
      var src = im.source === "queued" ? im.previewUrl : (im.thumb_url || im.image_url);
      tile.innerHTML = '<img src="' + src + '">' +
        (idx === 0 ? '<div class="main-badge">Asosiy</div>' : '<div class="set-main-btn">Asosiy qilish</div>') +
        '<div class="rm-btn">&times;</div>';
      tile.querySelector(".rm-btn").addEventListener("click", async function (e) {
        e.stopPropagation();
        await removeFormImage(idx);
      });
      if (idx !== 0) {
        var setMainEl = tile.querySelector(".set-main-btn");
        setMainEl.addEventListener("click", async function (e) {
          e.stopPropagation();
          await setFormImageMain(idx);
        });
      }
      grid.appendChild(tile);
    });
    var add = document.createElement("div");
    add.className = "image-add-tile";
    add.innerHTML = noImageIconSvg() + '<span>Rasm qo\'shish</span>';
    add.addEventListener("click", function () {
      openHiddenFilePicker(addFormImage);
    });
    grid.appendChild(add);
  }

  async function addFormImage(file) {
    if (state.editingProductId) {
      // Mahsulot allaqachon mavjud — darhol yuklaymiz
      try {
        var isMain = state.formImages.length === 0;
        var fd = new FormData();
        fd.append("file", file);
        var path = isMain ? "/main-image" : "/images";
        var res = await fetch("/dokon-api/products/" + state.editingProductId + path, { method: "POST", body: fd, credentials: "same-origin" });
        var data = await res.json();
        if (!res.ok) throw { detail: data.detail };
        state.productDetail = data;
        state.formImages = data.images.slice(0, 0); // qayta quramiz pastda
        state.formImages = buildSavedImageList(data);
        renderImageGrid();
        showToast("Rasm qo'shildi");
      } catch (err) {
        showToast((err && err.detail) || "Rasm yuklanmadi");
      }
    } else {
      state.formImages.push({ source: "queued", file: file, previewUrl: URL.createObjectURL(file) });
      renderImageGrid();
    }
  }

  function buildSavedImageList(detail) {
    // Asosiy rasm (Product.image_url) + galereya (ProductImage) — asosiy birinchi bo'lib chiqadi
    var list = [];
    if (detail.image_url) list.push({ source: "saved", id: null, image_url: detail.image_url, thumb_url: detail.thumb_url, isPrimary: true });
    detail.images.forEach(function (im) {
      if (im.image_url === detail.image_url) return; // asosiy sifatida allaqachon qo'shilgan bo'lishi mumkin
      list.push({ source: "saved", id: im.id, image_url: im.image_url, thumb_url: im.thumb_url });
    });
    return list;
  }

  async function removeFormImage(idx) {
    var im = state.formImages[idx];
    if (im.source === "queued") {
      URL.revokeObjectURL(im.previewUrl);
      state.formImages.splice(idx, 1);
      renderImageGrid();
      return;
    }
    if (!im.id) {
      showToast("Asosiy rasmni o'chirib bo'lmaydi — o'rniga boshqasini \"Asosiy\" qiling");
      return;
    }
    try {
      var data = await api("/products/" + state.editingProductId + "/images/" + im.id, { method: "DELETE" });
      state.productDetail = data;
      state.formImages = buildSavedImageList(data);
      renderImageGrid();
    } catch (err) { showToast(err.detail || "O'chirib bo'lmadi"); }
  }

  async function setFormImageMain(idx) {
    var im = state.formImages[idx];
    if (im.source === "queued" || !im.id) { showToast("Avval rasmni saqlang"); return; }
    try {
      var data = await api("/products/" + state.editingProductId + "/images/" + im.id + "/set-main", { method: "POST" });
      state.productDetail = data;
      state.formImages = buildSavedImageList(data);
      renderImageGrid();
      showToast("Asosiy rasm o'zgartirildi");
    } catch (err) { showToast(err.detail || "Xato"); }
  }

  // ---- parametrlar (faqat yangi mahsulotda) ----
  function renderParamBlocks() {
    var host = $("paramBlocks");
    host.innerHTML = "";
    state.formParams.forEach(function (param, pIdx) {
      var block = document.createElement("div");
      block.className = "param-block";
      var head = document.createElement("div");
      head.className = "param-block-head";
      var nameInput = document.createElement("input");
      nameInput.type = "text";
      nameInput.placeholder = "Parametr nomi (masalan: Varaq soni)";
      nameInput.value = param.name;
      nameInput.addEventListener("input", function () { param.name = nameInput.value; renderSkuTable(); });
      var rm = document.createElement("div");
      rm.className = "icon-link";
      rm.innerHTML = "&times;";
      rm.style.fontSize = "20px";
      rm.addEventListener("click", function () { state.formParams.splice(pIdx, 1); renderParamBlocks(); renderSkuTable(); });
      head.appendChild(nameInput);
      head.appendChild(rm);
      block.appendChild(head);

      var chipRow = document.createElement("div");
      chipRow.className = "chip-row";
      function renderChips() {
        chipRow.querySelectorAll(".value-chip").forEach(function (c) { c.remove(); });
        param.values.forEach(function (v, vIdx) {
          var chip = document.createElement("span");
          chip.className = "value-chip";
          chip.innerHTML = escapeHtml(v) + '<span class="x">&times;</span>';
          chip.querySelector(".x").addEventListener("click", function () {
            param.values.splice(vIdx, 1);
            renderChips();
            renderSkuTable();
          });
          chipRow.insertBefore(chip, chipInput);
        });
      }
      var chipInput = document.createElement("input");
      chipInput.className = "chip-input";
      chipInput.placeholder = "Qiymat qo'shish, Enter bosing";
      chipInput.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === ",") {
          e.preventDefault();
          var v = chipInput.value.trim();
          if (v) { param.values.push(v); chipInput.value = ""; renderChips(); renderSkuTable(); }
        }
      });
      chipInput.addEventListener("blur", function () {
        var v = chipInput.value.trim();
        if (v) { param.values.push(v); chipInput.value = ""; renderChips(); renderSkuTable(); }
      });
      chipRow.appendChild(chipInput);
      renderChips();
      block.appendChild(chipRow);
      host.appendChild(block);
    });
  }

  // ---- SKU jadvali ----
  function renderSkuTable() {
    var body = $("skuTableBody");
    if (!body) return;
    body.innerHTML = "";

    if (state.editingProductId) {
      state.formVariants.forEach(function (v) {
        body.appendChild(skuRow(comboLabel(v.attributes), v.price, v.stock, function (price, stock) {
          return saveExistingVariant(v.id, price, stock);
        }, function () { return deleteExistingVariant(v.id); }, state.formVariants.length > 1));
      });
      return;
    }

    var combos = currentCombos();
    // Oldingi qiymatlarni combo kaliti bo'yicha saqlab qolamiz (parametr o'zgarganda yo'qolib ketmasin)
    state.skuValues = state.skuValues || {};
    combos.forEach(function (combo) {
      var key = JSON.stringify(combo);
      if (!state.skuValues[key]) state.skuValues[key] = { price: "", stock: "0" };
      var v = state.skuValues[key];
      body.appendChild(skuRow(comboLabel(combo), v.price, v.stock, function (price, stock) {
        v.price = price; v.stock = stock;
      }, null, false));
    });
  }

  function skuRow(label, price, stock, onChange, onDelete, canDelete) {
    var tr = document.createElement("tr");
    var priceInput, stockInput;
    tr.innerHTML =
      '<td class="combo-label">' + escapeHtml(label) + '</td>' +
      '<td><input type="number" min="1" class="skuPrice" value="' + (price || "") + '"></td>' +
      '<td><input type="number" min="0" class="skuStock" value="' + (stock != null ? stock : 0) + '"></td>' +
      '<td></td>';
    priceInput = tr.querySelector(".skuPrice");
    stockInput = tr.querySelector(".skuStock");
    function commit() { onChange(priceInput.value, stockInput.value); }
    priceInput.addEventListener("change", commit);
    stockInput.addEventListener("change", commit);
    if (onDelete && canDelete) {
      var del = document.createElement("div");
      del.className = "icon-link";
      del.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="var(--danger)" stroke-width="1.8"><path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14"/></svg>';
      del.addEventListener("click", onDelete);
      tr.lastElementChild.appendChild(del);
    }
    return tr;
  }

  async function saveExistingVariant(variantId, price, stock) {
    try {
      var data = await api("/products/" + state.editingProductId + "/variants/" + variantId, {
        method: "PATCH",
        body: JSON.stringify({ price: parseInt(price, 10) || undefined, stock: parseInt(stock, 10) }),
      });
      state.productDetail = data;
      state.formVariants = data.variants.slice();
      showToast("Saqlandi");
    } catch (err) { showToast(err.detail || "Saqlanmadi"); }
  }

  async function deleteExistingVariant(variantId) {
    if (!confirm("Bu variantni o'chirmoqchimisiz?")) return;
    try {
      var data = await api("/products/" + state.editingProductId + "/variants/" + variantId, { method: "DELETE" });
      state.productDetail = data;
      state.formVariants = data.variants.slice();
      renderSkuTable();
    } catch (err) { showToast(err.detail || "O'chirib bo'lmadi"); }
  }

  function addManualVariantPrompt() {
    var name = prompt("Yangi variant nomi (masalan: 96 varoqli):");
    if (!name) return;
    var price = prompt("Narxi (so'm):");
    if (!price || isNaN(parseInt(price, 10))) { showToast("Narx noto'g'ri"); return; }
    var stock = prompt("Zaxira:", "0");
    (async function () {
      try {
        var data = await api("/products/" + state.editingProductId + "/variants", {
          method: "POST",
          body: JSON.stringify({ attributes: { "Variant": name }, price: parseInt(price, 10), stock: parseInt(stock, 10) || 0 }),
        });
        state.productDetail = data;
        state.formVariants = data.variants.slice();
        renderSkuTable();
        showToast("Variant qo'shildi");
      } catch (err) { showToast(err.detail || "Qo'shilmadi"); }
    })();
  }

  // ---- saqlash ----
  async function saveProductForm() {
    var errBox = $("pfError");
    errBox.classList.add("hidden");
    var name = $("pfName").value.trim();
    var brand = $("pfBrand").value.trim();
    var description = $("pfDescription").value.trim();
    var categoryId = $("pfCategory").value ? parseInt($("pfCategory").value, 10) : null;

    if (!name) {
      errBox.textContent = "Nomi kiritilishi shart";
      errBox.classList.remove("hidden");
      return;
    }

    var btn = $("pfSaveBtn");
    btn.disabled = true;
    try {
      if (!state.editingProductId) {
        var combos = currentCombos();
        var variants = combos.map(function (combo) {
          var v = state.skuValues[JSON.stringify(combo)] || { price: "", stock: "0" };
          return { attributes: combo, price: parseInt(v.price, 10), stock: parseInt(v.stock, 10) || 0 };
        });
        if (variants.some(function (v) { return !v.price || v.price <= 0; })) {
          throw { detail: "Har bir variant uchun narx kiritilishi shart" };
        }
        var created = await api("/products", {
          method: "POST",
          body: JSON.stringify({ name: name, brand: brand || null, description: description || null, category_id: categoryId, variants: variants }),
        });
        // navbat bilan rasm yuklash (birinchisi — asosiy)
        for (var i = 0; i < state.formImages.length; i++) {
          var im = state.formImages[i];
          var fd = new FormData();
          fd.append("file", im.file);
          var path = i === 0 ? "/main-image" : "/images";
          await fetch("/dokon-api/products/" + created.id + path, { method: "POST", body: fd, credentials: "same-origin" });
        }
        showToast("Qo'shildi, do'konda ko'rinmoqda");
      } else {
        var payload = {
          name: name, brand: brand || null, description: description || null, category_id: categoryId,
          known_rev: state.productDetail ? state.productDetail.rev : null,
        };
        var updated = await api("/products/" + state.editingProductId, { method: "PATCH", body: JSON.stringify(payload) });
        if (updated.conflict) {
          showToast("Diqqat: buni " + updated.conflict.conflict_by + " ham o'zgartirgan edi — sizniki saqlandi");
        } else {
          showToast("Saqlandi");
        }
      }
      state.formImages.forEach(function (im) { if (im.source === "queued") URL.revokeObjectURL(im.previewUrl); });
      showProducts();
    } catch (err) {
      errBox.textContent = err.detail || "Saqlab bo'lmadi";
      errBox.classList.remove("hidden");
    } finally {
      btn.disabled = false;
    }
  }

  window.DokonCatalog = { showProducts: showProducts, showCategories: showCategories };
})();
