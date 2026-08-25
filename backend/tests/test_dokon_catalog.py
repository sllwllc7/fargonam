"""/dokon katalog boshqaruvidagi sof funksiyalar uchun testlar (DB/Redis'siz).

To'liq zanjir (login -> kategoriya -> mahsulot -> Mini App -> savat ->
buyurtma -> /dokon) qo'lda, real brauzerda (Playwright) tekshirildi —
PROGRESS.md'ga qara. Bu yerda faqat DB'siz sinash mumkin bo'lgan sof
mantiq — SKU combo nomlash va tahrir to'qnashuvi aniqlash."""
from app.api.dokon_catalog import _combo_label, _conflict_info


def test_combo_label_empty_attributes_is_standart():
    assert _combo_label({}) == "Standart"


def test_combo_label_single_attribute():
    assert _combo_label({"Varoq soni": "48"}) == "48"


def test_combo_label_multiple_attributes_joined():
    assert _combo_label({"Varoq soni": "48", "Muqova": "Qattiq"}) == "48 / Qattiq"


def test_conflict_info_no_known_rev_means_no_check():
    touch = {"rev": 3, "prev_rev": 2, "prev_updated_by": "Aziz"}
    assert _conflict_info(None, touch) is None


def test_conflict_info_same_rev_no_conflict():
    # Xodim aynan o'zi yuklagan rev'dan saqladi — hech kim orada o'zgartirmagan
    touch = {"rev": 2, "prev_rev": 1, "prev_updated_by": "Aziz"}
    assert _conflict_info(1, touch) is None


def test_conflict_info_stale_rev_flags_other_editor():
    # Boshqa xodim (Aziz) orada allaqachon saqlagan, biz eski (rev=1) holatdan yuklagan edik
    touch = {"rev": 3, "prev_rev": 2, "prev_updated_by": "Aziz"}
    result = _conflict_info(1, touch)
    assert result == {"conflict": True, "conflict_by": "Aziz"}


def test_conflict_info_stale_but_no_prior_editor_name():
    # rev oshgan lekin ism yo'q (masalan Redis flush bo'lgan) — ogohlantirish chiqmaydi
    touch = {"rev": 2, "prev_rev": 1, "prev_updated_by": None}
    assert _conflict_info(0, touch) is None
