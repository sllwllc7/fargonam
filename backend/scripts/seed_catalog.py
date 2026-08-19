"""2-bosqich: `handoff/Fargonam User App v2.dc.html`dagi `buildData()`
(837-942-qatorlar) bilan bir xil katalog — 18 kategoriya, mahsulot/SKU
matritsalari, 1-11 sinf to'plamlari. Dev bazasi deyarli bo'sh edi
(`categories`=0, `products`=7 test-yozuv) — shu skript to'ldiradi.

Ishlatish:
    cd ~/fargonam/backend
    .venv/bin/python -m scripts.seed_catalog

Idempotent — mavjud slug/nomlarni qayta yaratmaydi, xavfsiz qayta ishga
tushiriladi.
"""
import asyncio

from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.models.category import Category
from app.models.product import Product
from app.models.product_set import ProductSet, ProductSetItem
from app.models.product_variant import ProductVariant

SHOP_ID = 1  # "Test Shop" — approved, mavjud

# dc.html `defs` (843-849-qatorlar) — (slug, nom). `count` maydoni faqat
# vizual mock (haqiqiy SKU soni emas) — PROGRESS.md'da izohlangan, bu yerda
# saqlanmaydi (real `product_count` backend'da so'rov vaqtida hisoblanadi).
CATEGORY_DEFS = [
    ("ruchka", "Ruchka"),
    ("daftar", "Daftar"),
    ("qalam", "Qalam"),
    ("rangli-qalam", "Rangli qalam"),
    ("a4", "A4 qog'ozi"),
    ("rangli-qogoz", "Rangli qog'oz"),
    ("flomaster", "Flomaster"),
    ("marker", "Marker"),
    ("ochirgich", "O'chirg'ich"),
    ("lineyka", "Lineyka"),
    ("yelim", "Yelim"),
    ("qaychi", "Qaychi"),
    ("albom", "Albom"),
    ("papka", "Papka"),
    ("kundalik", "Kundalik"),
    ("qalamdon", "Qalamdon"),
    ("shtrix", "Shtrix"),
    ("skotch", "Skotch"),
]
CATEGORY_NAMES = dict(CATEGORY_DEFS)

BRANDS = ["Deli", "Erich Krause", "Berlingo", "Attache", "Dolce", "Hatber"]
# dc.html `base` obyekti (898-qator) — 14 "generatsiya qilinadigan" kategoriya.
GENERATED_BASE = {
    "rangli-qalam": 18000,
    "rangli-qogoz": 12000,
    "flomaster": 16000,
    "marker": 7000,
    "ochirgich": 2500,
    "lineyka": 3500,
    "yelim": 6000,
    "qaychi": 9000,
    "albom": 15000,
    "papka": 8000,
    "kundalik": 22000,
    "qalamdon": 28000,
    "shtrix": 9500,
    "skotch": 5500,
}


def _variant_name(attrs: dict) -> str:
    return ", ".join(attrs.values()) if attrs else "Standart"


def explicit_products():
    """dc.html'da qo'lda yozilgan mahsulotlar (854-895-qatorlar): Daftar
    (4 ta), Ruchka (5 ta), Qalam (3 ta), A4 (2 ta) — aynan o'sha SKU
    matritsalari bilan."""
    P = []

    def daftar_matrix(sizes):
        variants = []
        for v, pr, st in sizes:
            for i, m in enumerate(["Klassik", "Geometrik", "Pastel"]):
                stock = 4 if (v == "96" and m == "Pastel") else max(3, round(st / (i + 1)))
                variants.append(({"Varaq soni": v, "Muqova": m}, pr, stock))
        return variants

    # Daftar
    P.append(("daftar", "Yozuvli daftar", "Hatber",
              "Sifatli oq qog'ozli yozuv daftari. Maktab va ofis uchun. Muqova dizaynini tanlash mumkin.",
              daftar_matrix([("12", 2000, 100), ("36", 4000, 80), ("48", 5500, 60), ("96", 9000, 30)])))
    P.append(("daftar", "Katak daftar", "BG", "Katak chizig'li daftar — matematika va chizmachilik darslari uchun qulay.",
              [({"Varaq soni": v}, pr, st) for v, pr, st in [("12", 1800, 140), ("36", 3800, 90), ("48", 5200, 55), ("96", 8500, 22)]]))
    P.append(("daftar", "Chiziqli daftar", "Brauberg", "Bir tekis chiziqli daftar, yumshoq muqova.",
              [({"Varaq soni": v}, pr, st) for v, pr, st in [("36", 4200, 70), ("48", 5800, 8)]]))
    P.append(("daftar", "Eskiz daftari A5", "Erich Krause", "Qalin qog'ozli eskiz daftari, rasm va chizma uchun.",
              [({}, 14500, 25)]))
    # Ruchka
    P.append(("ruchka", "Alfa ruchka", "Flair", "Silliq yozadigan sharikli ruchka. Maktab uchun eng ommabop tanlov.",
              [({"Siyoh rangi": v}, pr, st) for v, pr, st in [("Ko'k", 2500, 120), ("Qora", 2500, 80), ("Qizil", 2500, 35)]]))
    P.append(("ruchka", "Piano ruchka", "Piano", "Yumshoq tutqichli, uzoq xizmat qiladigan ruchka.",
              [({"Siyoh rangi": v}, pr, st) for v, pr, st in [("Ko'k", 3500, 95), ("Qora", 3500, 60)]]))
    P.append(("ruchka", "Gamma ruchka", "Gamma", "Arzon va ishonchli kundalik ruchka.",
              [({"Siyoh rangi": "Ko'k"}, 2000, 200)]))
    P.append(("ruchka", "Parker Jotter", "Parker", "Premium metall korpusli ruchka. Sovg'a uchun ajoyib tanlov.",
              [({"Siyoh rangi": "Ko'k"}, 185000, 6)]))
    P.append(("ruchka", "Cello Maxriter", "Cello", "Nozik uchli, aniq yozuvli ruchka.",
              [({"Siyoh rangi": v}, pr, st) for v, pr, st in [("Ko'k", 3000, 45), ("Qora", 3000, 0)]]))
    # Qalam
    P.append(("qalam", "Oddiy qalam HB", "KOH-I-NOOR", "Klassik yog'och qalam, HB qattiqlik.",
              [({"Qadoq": v}, pr, st) for v, pr, st in [("1 dona", 1500, 300), ("12 dona", 15000, 40)]]))
    P.append(("qalam", "Mexanik qalam 0.5", "Deli", "Mexanik qalam, 0.5 mm grafit bilan.", [({}, 8500, 32)]))
    P.append(("qalam", "Qalam to'plami 2B-8B", "Marco", "Rasm chizish uchun 6 xil qattiqlikdagi qalamlar.", [({}, 24000, 12)]))
    # A4
    P.append(("a4", "A4 qog'oz 500 varoq", "Snegurochka", "Ofis printerlari uchun standart A4 qog'oz, 80 g/m2.", [({}, 58000, 0)]))
    P.append(("a4", "A4 qog'oz 500 varoq", "SvetoCopy", "Sifatli A4 qog'oz, kseroks va printer uchun.", [({}, 52000, 44)]))
    return P


def generated_products():
    """dc.html "Generated for other categories" bloki (896-906-qatorlar)
    aynan — 14 kategoriya x 4 mahsulot, formula bo'yicha narx/zaxira."""
    P = []
    for cid, base in GENERATED_BASE.items():
        cname = CATEGORY_NAMES[cid]
        for i in range(4):
            brand = BRANDS[(len(cid) + i) % 6]
            stock = 6 if i == 3 else 20 + ((len(cid) * 7 + i * 13) % 90)
            price = base + i * round(base * 0.18 / 500) * 500
            P.append((cid, f"{cname} {brand}", brand, f"{cname} — {brand} brendidan sifatli mahsulot.", [({}, price, stock)]))
    return P


# dc.html `kits` (907-940-qatorlar) — 4 ta noyob tarkib (g<=2, g<=4, g<=8,
# else), har biri [nom, variant_yorlig'i, soni, narx]. Bu yorliqlar haqiqiy
# `P` mahsulotlariga bog'lanmagan flat mock (prototipning o'zida ham shunday —
# ProductSetItem'da alohida nom maydoni yo'q edi), shu sabab quyida narx (va
# mavjud bo'lsa variant matni) bo'yicha eng mos real variantga bog'lanadi.
TIER_LOW = [  # g 1-2
    ("Yozuvli daftar", "12 varoq", 10, 2000), ("Katak daftar", "12 varoq", 10, 1800),
    ("Alfa ruchka", "Ko'k siyoh", 4, 2500), ("Oddiy qalam HB", "1 dona", 4, 1500),
    ("O'chirg'ich", "Standart", 2, 2500), ("Lineyka", "Standart", 1, 3500),
    ("Rangli qalam", "12 rang", 1, 18000), ("Albom", "A4", 1, 15000),
    ("Qalamdon", "Standart", 1, 28000), ("Kundalik", "Standart", 1, 22000),
]
TIER_MID = [  # g 3-4
    ("Yozuvli daftar", "12 varoq", 6, 2000), ("Yozuvli daftar", "48 varoq", 6, 5500),
    ("Katak daftar", "12 varoq", 6, 1800), ("Alfa ruchka", "Ko'k siyoh", 5, 2500),
    ("Oddiy qalam HB", "1 dona", 3, 1500), ("O'chirg'ich", "Standart", 2, 2500),
    ("Lineyka", "Standart", 1, 3500), ("Rangli qalam", "12 rang", 1, 18000),
    ("Albom", "A4", 1, 15000), ("Kundalik", "Standart", 1, 22000),
]
TIER_HIGH = [  # g 5-8
    ("Yozuvli daftar", "48 varoq", 8, 5500), ("Katak daftar", "48 varoq", 8, 5200),
    ("Alfa ruchka", "Ko'k siyoh", 6, 2500), ("Oddiy qalam HB", "1 dona", 2, 1500),
    ("Lineyka", "Standart", 1, 4500), ("Flomaster", "6 rang", 1, 16000),
    ("Kundalik", "Standart", 1, 22000), ("Papka", "A4", 1, 8000),
]
TIER_TOP = [  # g 9-11
    ("Yozuvli daftar", "48 varoq", 6, 5500), ("Yozuvli daftar", "96 varoq", 6, 9000),
    ("Katak daftar", "48 varoq", 6, 5200), ("Alfa ruchka", "Ko'k siyoh", 8, 2500),
    ("Oddiy qalam HB", "1 dona", 2, 1500), ("Shtrix", "Standart", 1, 9500),
    ("Lineyka", "Standart", 1, 4500), ("Kundalik", "Standart", 1, 22000),
    ("Papka", "A4", 1, 8000),
]
TIER_BY_GRADE = {g: TIER_LOW for g in (1, 2)}
TIER_BY_GRADE.update({g: TIER_MID for g in (3, 4)})
TIER_BY_GRADE.update({g: TIER_HIGH for g in (5, 6, 7, 8)})
TIER_BY_GRADE.update({g: TIER_TOP for g in (9, 10, 11)})

# Kit item nomi -> shu nomdagi mahsulotni qidirishda ishlatiladigan asosiy
# so'z (generatsiya qilingan kategoriyalar uchun kategoriya nomi bilan mos
# kelishi uchun; "O'chirg'ich" kabi apostrof holatlari farq qilmasligi uchun).
KIT_ITEM_PRODUCT_HINT = {
    "O'chirg'ich": "O'chirg'ich",
    "Lineyka": "Lineyka",
    "Rangli qalam": "Rangli qalam",
    "Albom": "Albom",
    "Qalamdon": "Qalamdon",
    "Kundalik": "Kundalik",
    "Flomaster": "Flomaster",
    "Papka": "Papka",
    "Shtrix": "Shtrix",
}


async def main():
    async with AsyncSessionLocal() as db:
        # ── Kategoriyalar ──────────────────────────────────────
        existing_cats = {c.slug: c for c in (await db.scalars(select(Category))).all()}
        for slug, name in CATEGORY_DEFS:
            if slug not in existing_cats:
                cat = Category(name=name, slug=slug)
                db.add(cat)
                existing_cats[slug] = cat
        await db.flush()
        cat_id_by_slug = {slug: existing_cats[slug].id for slug, _ in CATEGORY_DEFS}

        # ── Mahsulotlar + variantlar ───────────────────────────
        existing_products = {
            (p.name, p.brand): p
            for p in (await db.scalars(select(Product).where(Product.shop_id == SHOP_ID))).all()
        }
        sku_counter = 0
        created_variants: list[tuple[str, str, dict, int, ProductVariant]] = []
        # (product_name, category_slug, attrs, price, variant) — kit-bog'lash uchun

        for cat_slug, name, brand, desc, variants in explicit_products() + generated_products():
            key = (name, brand)
            product = existing_products.get(key)
            is_new_product = product is None
            if is_new_product:
                product = Product(
                    shop_id=SHOP_ID,
                    category_id=cat_id_by_slug[cat_slug],
                    name=name,
                    brand=brand,
                    description=desc,
                    is_active=True,
                )
                db.add(product)
                await db.flush()
                existing_products[key] = product
            elif product.category_id is None:
                # Avval kategoriyasiz yaratilgan bo'lsa — endi to'g'irlanadi.
                product.category_id = cat_id_by_slug[cat_slug]

            existing_variant_names = set()
            if not is_new_product:
                existing_variant_names = {
                    v.variant_name
                    for v in (await db.scalars(select(ProductVariant).where(ProductVariant.product_id == product.id))).all()
                }

            for attrs, price, stock in variants:
                vname = _variant_name(attrs)
                if vname in existing_variant_names:
                    continue
                sku_counter += 1
                variant = ProductVariant(
                    product_id=product.id,
                    sku=f"{cat_slug.upper()}-{product.id}-{sku_counter}",
                    variant_name=vname,
                    price=price,
                    stock=stock,
                    attributes=attrs,
                    is_active=True,
                )
                db.add(variant)
                created_variants.append((name, cat_slug, attrs, price, variant))
        await db.flush()

        # Kit-bog'lash uchun barcha (yangi+eski) variantlarni product bilan qayta o'qish.
        all_variants = (await db.scalars(select(ProductVariant))).all()
        all_products = {p.id: p for p in (await db.scalars(select(Product))).all()}

        def resolve_variant(item_name: str, item_variant_label: str, price: int) -> ProductVariant | None:
            hint = KIT_ITEM_PRODUCT_HINT.get(item_name, item_name)
            candidates = [v for v in all_variants if all_products[v.product_id].name.startswith(hint) and v.price == price]
            if not candidates:
                # Narx aniq mos kelmasa — nomi mos eng yaqin narxdagisini olamiz.
                same_name = [v for v in all_variants if all_products[v.product_id].name.startswith(hint)]
                if not same_name:
                    return None
                candidates = sorted(same_name, key=lambda v: abs(v.price - price))[:1]
            if len(candidates) == 1:
                return candidates[0]
            # Bir nechta narx-mos variant bor (masalan bir xil narxli muqova/rang) —
            # variant yorlig'idagi so'z attrs qiymatida uchraydiganini afzal ko'ramiz.
            label_words = item_variant_label.lower().replace("siyoh", "").split()
            for v in candidates:
                for val in v.attributes.values():
                    if any(w and w in val.lower() for w in label_words):
                        return v
            return candidates[0]

        # ── Sinf to'plamlari (grade 1-11) ──────────────────────
        existing_sets = {
            s.grade_level: s
            for s in (await db.scalars(select(ProductSet).where(ProductSet.shop_id == SHOP_ID))).all()
        }
        unresolved: list[str] = []
        for grade in range(1, 12):
            gs = str(grade)
            if gs in existing_sets:
                continue
            kit = ProductSet(
                shop_id=SHOP_ID,
                name=f"{grade}-sinf to'plami",
                grade_level=gs,
                is_active=True,
            )
            db.add(kit)
            await db.flush()
            for item_name, item_variant_label, qty, price in TIER_BY_GRADE[grade]:
                variant = resolve_variant(item_name, item_variant_label, price)
                if variant is None:
                    unresolved.append(f"grade={grade} item={item_name}/{item_variant_label}/{price}")
                    continue
                db.add(ProductSetItem(set_id=kit.id, variant_id=variant.id, quantity=qty))

        await db.commit()

        n_cats = len((await db.scalars(select(Category))).all())
        n_products = len((await db.scalars(select(Product))).all())
        n_variants = len((await db.scalars(select(ProductVariant))).all())
        n_kits = len((await db.scalars(select(ProductSet))).all())
        print(f"✅ Kategoriyalar: {n_cats}, mahsulotlar: {n_products}, variantlar: {n_variants}, to'plamlar: {n_kits}")
        if unresolved:
            print("⚠️  Bog'lanmagan kit elementlari:")
            for u in unresolved:
                print(f"   - {u}")


if __name__ == "__main__":
    asyncio.run(main())
