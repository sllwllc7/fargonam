"""Mobil ilovadagi `category_icons.dart` bilan bir xil ro'yxat.

Admin panel kategoriyaga faqat shu ro'yxatdagi ikonkalardan birini biriktira
oladi (yangi ikonka o'ylab topilmaydi — CLAUDE.md §6). Hozircha bu qiymat
faqat saqlanadi, mobil ilova hamon o'z slug'i bo'yicha ikonka tanlaydi
(`categoryIconPaths[slug]`) — bog'lash keyingi bosqichda.
"""

ALLOWED_CATEGORY_ICONS = frozenset({
    "ruchka", "daftar", "qalam", "rangli-qalam", "a4", "rangli-qogoz",
    "flomaster", "marker", "ochirgich", "lineyka", "yelim", "qaychi",
    "albom", "papka", "kundalik", "qalamdon", "shtrix", "skotch",
})
