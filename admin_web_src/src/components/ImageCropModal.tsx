import { useState } from "react";
import Cropper, { type Area } from "react-easy-crop";
import { getCroppedImageBlob } from "../utils/cropImage";

export function ImageCropModal({
  imageSrc,
  onCancel,
  onDone,
}: {
  imageSrc: string;
  onCancel: () => void;
  onDone: (blob: Blob) => void;
}) {
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [croppedArea, setCroppedArea] = useState<Area | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleDone() {
    if (!croppedArea) return;
    setBusy(true);
    try {
      const blob = await getCroppedImageBlob(imageSrc, croppedArea, rotation);
      onDone(blob);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-lg rounded-2xl bg-surface card-shadow overflow-hidden">
        <div className="relative h-96 bg-black">
          <Cropper
            image={imageSrc}
            crop={crop}
            zoom={zoom}
            rotation={rotation}
            aspect={1}
            onCropChange={setCrop}
            onZoomChange={setZoom}
            onRotationChange={setRotation}
            onCropComplete={(_area, areaPixels) => setCroppedArea(areaPixels)}
          />
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="text-xs font-medium text-text-muted">Kattalashtirish</label>
            <input
              type="range"
              min={1}
              max={3}
              step={0.01}
              value={zoom}
              onChange={(e) => setZoom(Number(e.target.value))}
              className="w-full"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Aylantirish</label>
            <input
              type="range"
              min={0}
              max={360}
              step={1}
              value={rotation}
              onChange={(e) => setRotation(Number(e.target.value))}
              className="w-full"
            />
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <button
              onClick={onCancel}
              className="rounded-xl border border-border px-4 py-2 text-sm font-medium text-text-secondary hover:bg-background"
            >
              Bekor qilish
            </button>
            <button
              onClick={handleDone}
              disabled={busy || !croppedArea}
              className="btn-primary rounded-xl px-4 py-2 text-sm font-semibold disabled:opacity-60"
            >
              {busy ? "Tayyorlanmoqda..." : "Qo'llash"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
