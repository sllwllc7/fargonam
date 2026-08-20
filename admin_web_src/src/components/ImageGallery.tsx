import { useEffect, useState } from "react";
import {
  addProductImage,
  deleteProductImage,
  listProductImages,
  reorderProductImages,
  setMainProductImage,
  type GalleryImage,
} from "../api/products";
import type { ApiError } from "../api/client";
import type { ProductOut } from "../api/types";
import { ImageCropModal } from "./ImageCropModal";

export function ImageGallery({
  productId,
  onMainImageChanged,
}: {
  productId: number;
  onMainImageChanged: (p: ProductOut) => void;
}) {
  const [images, setImages] = useState<GalleryImage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [cropSrc, setCropSrc] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    try {
      const rows = await listProductImages(productId);
      setImages(rows.sort((a, b) => a.sort_order - b.sort_order));
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productId]);

  function pickFile() {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/jpeg,image/png,image/webp";
    input.onchange = () => {
      const file = input.files?.[0];
      if (file) setCropSrc(URL.createObjectURL(file));
    };
    input.click();
  }

  async function handleCropDone(blob: Blob) {
    setCropSrc(null);
    setError(null);
    try {
      await addProductImage(productId, blob);
      await load();
    } catch (e) {
      setError((e as ApiError).message || "Rasm yuklashda xato");
    }
  }

  async function handleDelete(img: GalleryImage) {
    setBusyId(img.id);
    setError(null);
    try {
      await deleteProductImage(productId, img.id);
      setImages((prev) => prev.filter((i) => i.id !== img.id));
    } catch (e) {
      setError((e as ApiError).message || "O'chirishda xato");
    } finally {
      setBusyId(null);
    }
  }

  async function handleSetMain(img: GalleryImage) {
    setBusyId(img.id);
    setError(null);
    try {
      const updated = await setMainProductImage(productId, img.id);
      onMainImageChanged(updated);
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusyId(null);
    }
  }

  async function move(index: number, dir: -1 | 1) {
    const target = index + dir;
    if (target < 0 || target >= images.length) return;
    const next = [...images];
    [next[index], next[target]] = [next[target], next[index]];
    setImages(next);
    try {
      await reorderProductImages(
        productId,
        next.map((img, i) => ({ id: img.id, sort_order: i })),
      );
    } catch (e) {
      setError((e as ApiError).message || "Tartibni saqlashda xato");
      load();
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <label className="text-xs font-medium text-text-muted">Qo'shimcha rasmlar</label>
        <button onClick={pickFile} className="text-xs font-medium text-primary-mid hover:underline">
          + Rasm qo'shish
        </button>
      </div>

      {error && <div className="mt-1 rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{error}</div>}

      {loading ? (
        <p className="mt-2 text-xs text-text-muted">Yuklanmoqda...</p>
      ) : images.length === 0 ? (
        <p className="mt-2 text-xs text-text-muted">Qo'shimcha rasm yo'q</p>
      ) : (
        <div className="mt-2 grid grid-cols-4 gap-2">
          {images.map((img, i) => (
            <div key={img.id} className="rounded-lg border border-border overflow-hidden">
              <img src={img.thumb_url ?? img.image_url} className="h-16 w-full object-cover" alt="" />
              <div className="flex flex-wrap gap-0.5 p-1">
                <button
                  onClick={() => handleSetMain(img)}
                  disabled={busyId === img.id}
                  className="rounded bg-background px-1 py-0.5 text-[10px] font-medium hover:bg-primary-light disabled:opacity-60"
                  title="Asosiy qilish"
                >
                  Asosiy
                </button>
                <button
                  onClick={() => move(i, -1)}
                  disabled={i === 0}
                  className="rounded bg-background px-1 py-0.5 text-[10px] disabled:opacity-30"
                  title="Yuqoriga"
                >
                  ▲
                </button>
                <button
                  onClick={() => move(i, 1)}
                  disabled={i === images.length - 1}
                  className="rounded bg-background px-1 py-0.5 text-[10px] disabled:opacity-30"
                  title="Pastga"
                >
                  ▼
                </button>
                <button
                  onClick={() => handleDelete(img)}
                  disabled={busyId === img.id}
                  className="rounded bg-danger-tint px-1 py-0.5 text-[10px] text-danger disabled:opacity-60"
                  title="O'chirish"
                >
                  ✕
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {cropSrc && (
        <ImageCropModal imageSrc={cropSrc} onCancel={() => setCropSrc(null)} onDone={handleCropDone} />
      )}
    </div>
  );
}
