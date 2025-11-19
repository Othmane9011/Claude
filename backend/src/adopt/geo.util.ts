export function clampLat(v?: number): number | undefined {
  if (v == null) return undefined;
  if (!isFinite(v)) return undefined;
  if (v < -90 || v > 90) return undefined;
  return v;
}

export function clampLng(v?: number): number | undefined {
  if (v == null) return undefined;
  if (!isFinite(v)) return undefined;
  if (v < -180 || v > 180) return undefined;
  return v;
}

export function bboxFromCenter(lat: number, lng: number, radiusKm: number) {
  const deltaLat = radiusKm / 111.32;
  const deltaLng = radiusKm / (111.32 * Math.cos((lat * Math.PI) / 180));
  return {
    minLat: lat - deltaLat,
    maxLat: lat + deltaLat,
    minLng: lng - deltaLng,
    maxLng: lng + deltaLng,
  };
}

export function haversineKm(aLat: number, aLng: number, bLat: number, bLng: number) {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const aa =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(aa), Math.sqrt(1 - aa));
}

// Extraction lat/lng depuis URL Google Maps (cas principaux)
export function parseLatLngFromGoogleUrl(url?: string): { lat?: number; lng?: number } {
  if (!url) return {};
  try {
    const u = new URL(url);
    const q = u.searchParams;

    const pairs = ['q', 'll', 'daddr', 'saddr', 'query', 'center']
      .map((k) => q.get(k))
      .filter(Boolean) as string[];

    for (const s of pairs) {
      const m = s.match(/(-?\d+(\.\d+)?),\s*(-?\d+(\.\d+)?)/);
      if (m) return { lat: Number(m[1]), lng: Number(m[3]) };
    }

    // /@lat,lng,zoom
    const at = u.pathname.match(/@(-?\d+(\.\d+)?),(-?\d+(\.\d+)?)/);
    if (at) return { lat: Number(at[1]), lng: Number(at[3]) };

    // !3dlat!4dlng (ou !4d...!3d...)
    const t3d = url.match(/!3d(-?\d+(\.\d+)?)/);
    const t4d = url.match(/!4d(-?\d+(\.\d+)?)/);
    if (t3d && t4d) return { lat: Number(t3d[1]), lng: Number(t4d[1]) };

    // maps.app.goo.gl?link=... (réparse)
    const link = q.get('link');
    if (link) return parseLatLngFromGoogleUrl(link);
  } catch {}
  return {};
}
