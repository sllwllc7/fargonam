export type ParamDef = { name: string; values: string[] };

/** Variantlarning `attributes`idan parametr ta'riflarini chiqarib oladi —
 * har kalit bo'yicha uchragan qiymatlar to'plami. */
export function deriveParamsFromVariants(variants: { attributes: Record<string, unknown> }[]): ParamDef[] {
  const map = new Map<string, Set<string>>();
  for (const v of variants) {
    for (const [key, value] of Object.entries(v.attributes ?? {})) {
      if (!map.has(key)) map.set(key, new Set());
      map.get(key)!.add(String(value));
    }
  }
  return [...map.entries()].map(([name, values]) => ({ name, values: [...values] }));
}

function cartesian(params: ParamDef[]): Record<string, string>[] {
  if (params.length === 0) return [{}];
  return params.reduce<Record<string, string>[]>(
    (acc, param) =>
      acc.flatMap((combo) => param.values.map((value) => ({ ...combo, [param.name]: value }))),
    [{}],
  );
}

export function comboKey(attrs: Record<string, unknown>): string {
  return Object.entries(attrs)
    .map(([k, v]) => [k, String(v)] as [string, string])
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([k, v]) => `${k}=${v}`)
    .join("&");
}

export function comboLabel(combo: Record<string, string>): string {
  const values = Object.values(combo);
  return values.length ? values.join(" / ") : "Standart";
}

/** Parametr ro'yxatidan SKU kombinatsiyalarini generatsiya qiladi. */
export function generateCombos(params: ParamDef[]): Record<string, string>[] {
  const cleanParams = params
    .map((p) => ({ name: p.name.trim(), values: p.values.map((v) => v.trim()).filter(Boolean) }))
    .filter((p) => p.name && p.values.length > 0);
  return cartesian(cleanParams);
}
