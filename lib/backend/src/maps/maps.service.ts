// src/maps/maps.service.ts
import { Injectable } from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';
import * as https from 'https';
import * as http from 'http';
import * as dns from 'dns';
import { chromium, Browser } from 'playwright'; // <-- ajout

type LatLng = { lat: number; lng: number };

@Injectable()
export class MapsService {
  private readonly httpIPv4: AxiosInstance;

  constructor() {
    const agentOptions = {
      keepAlive: true,
      // force IPv4 pour éviter les résolutions AAAA bloquées
      lookup: (hostname: string, _: any, cb: any) =>
        dns.lookup(hostname, { family: 4 }, cb),
    };
    this.httpIPv4 = axios.create({
      httpAgent: new http.Agent(agentOptions),
      httpsAgent: new https.Agent(agentOptions),
      responseType: 'text',
      validateStatus: () => true, // on lit le corps même en 30x/40x
      timeout: 12000,
      decompress: true,
    });
  }

  /* =================== Ponts “applink” =================== */

  private async tryApplink(shortUrl: string): Promise<{ url?: string; lat?: number; lng?: number } | null> {
    const UA = 'Mozilla/5.0 (Linux; Android 12; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    const target = `https://www.google.com/maps?source=applink&link=${encodeURIComponent(shortUrl)}`;
    try {
      const r = await this.httpIPv4.get(target, {
        maxRedirects: 6,
        headers: {
          'user-agent': UA,
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'accept-language': 'fr-FR,fr;q=0.9,en;q=0.8',
          'upgrade-insecure-requests': '1',
        },
      });
      // @ts-ignore
      let finalUrl: string | undefined = r.request?.res?.responseUrl || r.request?.path || r.config?.url || target;
      if (finalUrl?.startsWith('http')) {
        finalUrl = this.sanitizeMapsUrl(finalUrl);
        if (finalUrl.includes('/maps')) return { url: finalUrl };
      }
      const html = typeof r.data === 'string' ? r.data : '';
      if (html) {
        const any = this.extractAnyMapsFromHtml(html, finalUrl ?? target);
        if (any) return { url: this.sanitizeMapsUrl(any) };
      }
    } catch {}
    return null;
  }

  private async tryGoogleUrlRedirector(shortUrl: string): Promise<{ url?: string; lat?: number; lng?: number } | null> {
    const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    const target = `https://www.google.com/url?sa=t&source=maps_applink&url=${encodeURIComponent(shortUrl)}`;
    try {
      const r = await this.httpIPv4.get(target, {
        maxRedirects: 6,
        headers: {
          'user-agent': UA,
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'accept-language': 'fr-FR,fr;q=0.9,en;q=0.8',
        },
      });
      // @ts-ignore
      let finalUrl: string | undefined = r.request?.res?.responseUrl || r.request?.path || r.config?.url || target;
      if (finalUrl?.startsWith('http')) {
        finalUrl = this.sanitizeMapsUrl(finalUrl);
        if (finalUrl.includes('/maps')) return { url: finalUrl };
      }
      const html = typeof r.data === 'string' ? r.data : '';
      if (html) {
        const any = this.extractAnyMapsFromHtml(html, finalUrl ?? target);
        if (any) return { url: this.sanitizeMapsUrl(any) };
      }
    } catch {}
    return null;
  }

  /* =================== Public API =================== */

  getMapsUrlFromSpecialties(spec: any): string | null {
    if (!spec || typeof spec !== 'object') return null;
    const url =
      spec?.mapsUrl ??
      spec?.maps_url ??
      spec?.googleMapsUrl ??
      spec?.google_maps_url ??
      null;
    if (!url) return null;
    const s = String(url).trim();
    return s.length ? s : null;
  }

  isShortGoogleMapsUrl(url: string): boolean {
    try {
      const h = new URL(url).hostname.toLowerCase();
      return (
        h.endsWith('maps.app.goo.gl') ||
        h === 'goo.gl' ||
        h.endsWith('goo.gle') ||
        h === 'g.page'
      );
    } catch {
      return false;
    }
  }

  async expandShortGoogleMapsUrl(shortUrl: string): Promise<string | null> {
    const rich = await this.expandShortRich(shortUrl);
    return rich?.url ?? null;
  }

  async expandAndParse(
    url?: string | null,
    preferCenter = false,
  ): Promise<{ finalUrl?: string; lat?: number; lng?: number } | null> {
    if (!url) return null;
    let u = this.stripCtl(String(url).trim());
    if (!u) return null;

    if (this.isShortGoogleMapsUrl(u)) {
      const rich = await this.expandShortRich(u);
      if (rich?.url) u = rich.url;
      if (this.isFiniteNum(rich?.lat) && this.isFiniteNum(rich?.lng)) {
        const final = this.sanitizeMapsUrl(this.ensureAtCenter(u, rich!.lat!, rich!.lng!));
        return { finalUrl: final, lat: rich!.lat!, lng: rich!.lng! };
      }
    }

    u = this.sanitizeMapsUrl(u);
    const parsed = this.parseLatLngFromGoogleUrl(u, preferCenter);
    return { finalUrl: u, ...(parsed ?? {}) };
  }

  /* =================== Internals =================== */

  private isFiniteNum(n: any): n is number {
    return typeof n === 'number' && Number.isFinite(n);
  }
  private stripCtl(s: string): string {
    return s.replace(/[\u0000-\u001F\u007F]+/g, '');
  }
  private resolveAgainstBase(maybeRel: string, baseUrl: string): string {
    try { return new URL(maybeRel, baseUrl).toString(); } catch { return maybeRel; }
  }
  private looksLikeGoogleMapsLongUrl(u?: string | null): boolean {
    if (!u) return false;
    try { const h = new URL(u).hostname.toLowerCase(); return h.includes('google.') && u.includes('/maps'); }
    catch { return false; }
  }

  /** Suivi manuel (sans throw) */
  private async tryManualFollow(startUrl: string, headers: Record<string,string>, maxHops = 10)
  : Promise<{ finalUrl: string; html: string } | null> {
    try {
      let url = startUrl;
      let body = '';
      for (let i = 0; i < maxHops; i++) {
        const r = await this.httpIPv4.get(url, { maxRedirects: 0, headers });
        const locRaw = String(r.headers?.location ?? '');
        const loc = this.stripCtl(locRaw);
        if (loc) { url = this.resolveAgainstBase(loc, url); continue; }
        body = typeof r.data === 'string' ? this.deobfuscateHtml(this.stripCtl(r.data)) : '';
        break;
      }
      return { finalUrl: this.sanitizeMapsUrl(url), html: body };
    } catch { return null; }
  }

  /** Fallback **chromium** minimal. */
  private async expandWithChromium(shortUrl: string): Promise<{ url?: string; lat?: number; lng?: number } | null> {
    let browser: Browser | null = null;
    try {
      browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox','--disable-dev-shm-usage']
      });
      const ctx = await browser.newContext({
        locale: 'fr-FR',
        userAgent: 'Mozilla/5.0 (Linux; Android 12; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
      });
      const page = await ctx.newPage();

      await page.goto(shortUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
      try { await page.waitForLoadState('networkidle', { timeout: 5000 }); } catch {}

      let finalUrl = this.sanitizeMapsUrl(page.url());

      // Si toujours court, tenter un clic “browser/web” si présent.
      try {
        const cand = page.locator('text=/browser|web/i').first();
        if (await cand.count()) {
          await cand.click({ timeout: 3000 }).catch(() => {});
          try { await page.waitForLoadState('networkidle', { timeout: 4000 }); } catch {}
          finalUrl = this.sanitizeMapsUrl(page.url());
        }
      } catch {}

      const html = await page.content();
      const coordsFromUrl = this.parseLatLngFromGoogleUrl(finalUrl) || undefined;
      const coordsFromHtml = this.extractPoiFromText(html) || undefined;

      const lat = coordsFromUrl?.lat ?? coordsFromHtml?.lat;
      const lng = coordsFromUrl?.lng ?? coordsFromHtml?.lng;

      if (this.isFiniteNum(lat) && this.isFiniteNum(lng)) {
        finalUrl = this.ensureAtCenter(finalUrl, lat!, lng!);
      }

      return { url: finalUrl, lat, lng };
    } catch {
      return null;
    } finally {
      if (browser) await browser.close();
    }
  }

  /** Expand robuste: ponts applink → suivi manuel UA mobile/desktop → scrape → fallback chromium. */
  private async expandShortRich(shortUrlRaw: string)
  : Promise<{ url?: string; lat?: number; lng?: number } | null> {
    const shortUrl = this.stripCtl(shortUrlRaw);

    const UA_MOBILE =
      'Mozilla/5.0 (Linux; Android 12; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    const UA_DESKTOP =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

    const baseHeaders = {
      'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'accept-language': 'fr-FR,fr;q=0.9,en;q=0.8',
      'upgrade-insecure-requests': '1',
      'referer': 'https://www.google.com/',
      'accept-encoding': 'gzip, deflate, br',
    };

    const hasCoords = (u: string | undefined) =>
      !!u && (/@-?\d+(\.\d+)?,-?\d+(\.\d+)?/.test(u) || /!3d-?\d+(\.\d+)?!4d-?\d+(\.\d+)?/i.test(u));

    const tryFollowCidOrPid = async (u: string): Promise<string | null> => {
      const hex = this.extractHexCidFromUrl(u);
      if (hex) {
        const viaCid = await this.followCid(hex);
        if (viaCid) return this.sanitizeMapsUrl(viaCid);
      }
      const pid = this.extractPlaceIdFromUrl(u);
      if (pid) {
        const viaPid = await this.followPlaceId(pid);
        if (viaPid) return this.sanitizeMapsUrl(viaPid);
      }
      const viaQ = this.extractQParam(u);
      if (viaQ) return this.sanitizeMapsUrl(viaQ);
      return null;
    };

    // 0) ?link=
    const linkParam = this.extractEmbeddedLink(shortUrl);
    if (linkParam) {
      let link = this.sanitizeMapsUrl(linkParam);
      if (this.isShortGoogleMapsUrl(link)) {
        const again = await this.expandShortRich(link);
        return again ?? { url: link };
      }
      const hopped = await tryFollowCidOrPid(link);
      if (hopped) link = hopped;
      return { url: link };
    }

    // 0-bis) ponts officiels
    {
      const viaApplink = await this.tryApplink(shortUrl);
      if (viaApplink) return viaApplink;

      const viaRedirector = await this.tryGoogleUrlRedirector(shortUrl);
      if (viaRedirector) return viaRedirector;
    }

    // 1) UA mobile → suivi manuel
    {
      const hop = await this.tryManualFollow(shortUrl, { ...baseHeaders, 'user-agent': UA_MOBILE });
      if (hop) {
        const { finalUrl, html } = hop;
        if (!this.isShortGoogleMapsUrl(finalUrl)) {
          if (hasCoords(finalUrl)) return { url: finalUrl };
          const hopped = await tryFollowCidOrPid(finalUrl);
          if (hopped) return { url: hopped };
        }
        const fromHtml =
          this.extractAnyMapsFromHtml(html, finalUrl) ||
          this.extractCanonical(html) ||
          this.extractAlUrl(html) ||
          this.extractRedirectFromHtml(html, finalUrl);
        if (fromHtml) {
          let clean = this.sanitizeMapsUrl(fromHtml);
          if (hasCoords(clean)) return { url: clean };
          const pid = this.extractPlaceIdFromHtml(html);
          if (pid) {
            const viaPid = await this.followPlaceId(pid);
            if (viaPid) clean = this.sanitizeMapsUrl(viaPid);
          } else {
            const hopped = await tryFollowCidOrPid(clean);
            if (hopped) clean = hopped;
          }
          const poi = this.extractPoiFromText(html);
          if (poi && !hasCoords(clean)) {
            const anchored = this.ensureAtCenter(clean, poi.lat, poi.lng);
            return { url: this.sanitizeMapsUrl(anchored), lat: poi.lat, lng: poi.lng };
          }
          if (this.looksLikeGoogleMapsLongUrl(clean)) return { url: clean };
        }
      }
    }

    // 2) UA desktop → suivi manuel
    {
      const hop = await this.tryManualFollow(shortUrl, { ...baseHeaders, 'user-agent': UA_DESKTOP });
      if (hop) {
        const { finalUrl, html } = hop;
        if (!this.isShortGoogleMapsUrl(finalUrl)) {
          if (hasCoords(finalUrl)) return { url: finalUrl };
          const hopped = await tryFollowCidOrPid(finalUrl);
          if (hopped) return { url: hopped };
        }
        const fromHtml =
          this.extractAnyMapsFromHtml(html, finalUrl) ||
          this.extractCanonical(html) ||
          this.extractAlUrl(html) ||
          this.extractRedirectFromHtml(html, finalUrl);
        if (fromHtml) {
          let clean = this.sanitizeMapsUrl(fromHtml);
          if (hasCoords(clean)) return { url: clean };
          const pid = this.extractPlaceIdFromHtml(html);
          if (pid) {
            const viaPid = await this.followPlaceId(pid);
            if (viaPid) clean = this.sanitizeMapsUrl(viaPid);
          } else {
            const hopped = await tryFollowCidOrPid(clean);
            if (hopped) clean = hopped;
          }
          const poi = this.extractPoiFromText(html);
          if (poi && !hasCoords(clean)) {
            const anchored = this.ensureAtCenter(clean, poi.lat, poi.lng);
            return { url: this.sanitizeMapsUrl(anchored), lat: poi.lat, lng: poi.lng };
          }
          if (this.looksLikeGoogleMapsLongUrl(clean)) return { url: clean };
        }
      }
    }

    // 3) fallback **Chromium**
    const viaChromium = await this.expandWithChromium(shortUrl);
    if (viaChromium?.url) return viaChromium;

    // rien trouvé
    return null;
  }

  /* ====== HTML helpers / parsing ====== */

  private deobfuscateHtml(text: string): string {
    let t = text;
    t = t.replace(/\\x([0-9A-Fa-f]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16)));
    t = t.replace(/\\u00([0-9A-Fa-f]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16)));
    t = t.replace(/\\u003[aA]/g, ':').replace(/\\u002[fF]/g, '/');
    t = t.replace(/\\\//g, '/');
    const named: Record<string, string> = { amp: '&', quot: '"', apos: "'", lt: '<', gt: '>', nbsp: ' ' };
    t = t.replace(/&(#x?[0-9a-fA-F]+|[a-zA-Z]+);/g, (m, ent: string) => {
      ent = ent.toLowerCase();
      if (named[ent]) return named[ent];
      if (ent.startsWith('#x')) { const cp = parseInt(ent.slice(2), 16); return Number.isFinite(cp) ? String.fromCharCode(cp) : m; }
      if (ent.startsWith('#')) { const cp = parseInt(ent.slice(1), 10); return Number.isFinite(cp) ? String.fromCharCode(cp) : m; }
      return m;
    });
    return t;
  }

  private extractEmbeddedLink(u: string): string | null {
    try {
      const url = new URL(u);
      const host = url.hostname.toLowerCase();
      if (!host.endsWith('maps.app.goo.gl')) return null;
      const raw = url.searchParams.get('link');
      if (!raw) return null;
      const decoded = decodeURIComponent(raw);
      if (decoded.startsWith('http')) return decoded;
      return null;
    } catch { return null; }
  }

  private extractRedirectFromHtml(html: string, base: string): string | null {
    const reAbs = /(window\.)?location(?:\.href)?\s*=\s*['"](https?:\/\/[^"']+)['"]/i;
    const mAbs = reAbs.exec(html);
    if (mAbs?.[2]) { try { return new URL(mAbs[2], base).toString(); } catch { return mAbs[2]; } }
    const reRel = /(window\.)?location(?:\.href)?\s*=\s*['"]((?:\/|\.{1,2}\/)[^"']+)['"]/i;
    const mRel = reRel.exec(html);
    if (mRel?.[2]) { try { return new URL(mRel[2], base).toString(); } catch { return mRel[2]; } }
    return null;
  }

  private extractAlUrl(html: string): string | null {
    const m1 = html.match(/<meta[^>]+property=["']al:android:url["'][^>]+content=["']([^"']+)["']/i);
    if (m1?.[1] && m1[1].includes('/maps')) return m1[1];
    const m2 = html.match(/<meta[^>]+property=["']al:ios:url["'][^>]+content=["']([^"']+)["']/i);
    if (m2?.[1] && m2[1].includes('/maps')) return m2[1];
    return null;
  }

  private extractCanonical(html: string): string | null {
    const m = html.match(/<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)["']/i);
    return m?.[1] ?? null;
  }

  private extractAnyMapsFromHtml(html: string, baseUrl: string): string | null {
    const candidates: Set<string> = new Set();
    const push = (u?: string | null) => { if (!u) return; try { candidates.add(new URL(this.stripCtl(u), baseUrl).toString()); } catch {} };

    for (const m of html.matchAll(/https?:\/\/(?:www\.)?google\.[^"' >]+\/maps[^\s"'<>]*/gi)) push(m[0]);
    for (const m of html.matchAll(/["']\/\/(?:www\.)?google\.[^"' >]+\/maps[^"']*["']/gi)) push(m[0].slice(1, -1).replace(/^\/\//, 'https://'));
    for (const m of html.matchAll(/["'](\/maps\/[^"']*)["']/gi)) push(m[1]);

    const enc = html.match(/https?%3A%2F%2F(?:www\.)?google\.[0-9A-Za-z_.%-]*%2Fmaps[^"'<>]*/i)?.[0];
    if (enc) { try { const once = decodeURIComponent(enc); push(once); try { push(decodeURIComponent(once)); } catch {} } catch {} }
    for (const m of html.matchAll(/https:\\\/\\\/(?:www\.)?google\.[^"' >]+\\\/maps[^\s"'<>]*/gi)) push(m[0].replace(/\\\//g, '/'));
    for (const m of html.matchAll(/https\\x3A\\x2F\\x2F(?:www\\.)?google\.[^"' >]+\\x2Fmaps[^\s"'<>]*/gi)) {
      const norm = m[0].replace(/\\x([0-9A-Fa-f]{2})/g, (_, h) => String.fromCharCode(parseInt(h,16)));
      push(norm);
    }
    for (const m of html.matchAll(/https?:\/\/www\.google\.[^"' >]+\/url\?[^"' >]+/gi)) {
      const real = this.extractQParam(m[0]); if (real) push(real);
    }
    for (const m of html.matchAll(/<meta[^>]+http-equiv=["']refresh["'][^>]+content=["'][^"']*url=([^"']+)/ig)) push(m[1]);
    for (const m of html.matchAll(/<meta[^>]+property=["']og:url["'][^>]+content=["']([^"']+)["']/ig)) push(m[1]);
    for (const m of html.matchAll(/href=["'](https?:\/\/(?:www\.)?google\.[^"']+\/maps[^"']*)["']/ig)) push(m[1]);
    for (const m of html.matchAll(/location\.(?:assign|replace)\(\s*["'](https?:\/\/[^"']+\/maps[^"']*)["']\s*\)/ig)) push(m[1]);

    if (candidates.size === 0) return null;

    const score = (u: string): number => {
      let s = 0;
      if (/\/maps\/place\//.test(u)) s += 10;
      if (/!3d|!4d/i.test(u)) s += 5;
      if (/@[+-]?\d+(?:\.\d+)?,[+-]?\d+(?:\.\d+)?/.test(u)) s += 2;
      return s;
    };

    let best: string | null = null;
    let bestScore = -1;
    for (const u of candidates) {
      if (!this.looksLikeGoogleMapsLongUrl(u)) continue;
      const sc = score(u);
      if (sc > bestScore) { best = u; bestScore = sc; }
    }
    return best;
  }

  private extractQParam(u: string): string | null {
    try {
      const url = new URL(u);
      if (!/\/url$/i.test(url.pathname)) return null;
      const q = url.searchParams.get('q');
      if (!q) return null;
      const dec = decodeURIComponent(q);
      return dec.startsWith('http') ? dec : null;
    } catch { return null; }
  }

  private hexToBigInt(hex: string): bigint {
    const clean = hex.trim().toLowerCase().startsWith('0x') ? hex.trim() : `0x${hex.trim()}`;
    return BigInt(clean);
  }

  public ensureAtCenter(url: string, lat: number, lng: number, zoom = 17): string {
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return this.sanitizeMapsUrl(url);
    const latS = String(lat), lngS = String(lng);
    const cleaned = this.sanitizeMapsUrl(url);
    const hasAt = /@-?\d+(\.\d+)?,-?\d+(\.\d+)?(,[^\/?#]+)?/.test(cleaned);
    if (hasAt) return cleaned.replace(/@-?\d+(\.\d+)?,-?\d+(\.\d+)?(,[^\/?#]+)?/, `@${latS},${lngS},${zoom}z`);
    try {
      const u = new URL(cleaned);
      if (u.pathname.includes('/maps')) {
        const before = (u.origin + u.pathname).replace(/\/$/, '');
        return `${before}/@${latS},${lngS},${zoom}z${u.search}${u.hash}`;
      }
    } catch {}
    return `https://www.google.com/maps/@${latS},${lngS},${zoom}z`;
  }

  public sanitizeMapsUrl(u: string): string {
    try {
      const url = new URL(this.stripCtl(u));
      const del = ['ts','utm_source','utm_medium','utm_campaign','utm_term','utm_content','entry','g_ep','hl','ved','source','opi','sca_esv'];
      del.forEach((k) => url.searchParams.delete(k));
      url.pathname = url.pathname.replace(/\/{2,}/g, '/').replace(/\/data=![^/?#]*/g, '');
      let s = url.toString();
      return this.stripCtl(s).replace(/[?#]$/, '');
    } catch {
      return this.stripCtl(u).replace(/[?#]$/, '');
    }
  }

  private extractHexCidFromUrl(u: string): string | null {
    const matches = [...u.matchAll(/:0x([0-9a-fA-F]+)/g)];
    return matches.length ? matches[matches.length - 1][1] : null;
  }

  private async followCid(hex: string): Promise<string | null> {
    const UA = 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    try {
      const dec = this.hexToBigInt(hex).toString(10);
      const cidUrl = `https://maps.google.com/?cid=${dec}`;
      const r1 = await this.httpIPv4.get(cidUrl, { maxRedirects: 0, headers: { 'user-agent': UA, 'accept-language': 'fr-FR,fr;q=0.9,en;q=0.8' } });
      const loc = (r1.headers?.location ?? '') as string;
      if (loc) return new URL(loc, cidUrl).toString();
      const r2 = await this.httpIPv4.get(cidUrl, { maxRedirects: 6, headers: { 'user-agent': UA, 'accept-language': 'fr-FR,fr;q=0.9,en;q=0.8' } });
      // @ts-ignore
      return r2.request?.res?.responseUrl || r2.request?.path || r2.config?.url || cidUrl;
    } catch { return null; }
  }

  private extractPlaceIdFromUrl(u: string): string | null {
    try {
      const dec = decodeURIComponent(u);
      let m = dec.match(/(?:[?&]query_place_id=|place_id[:=])(ChI[0-9A-Za-z_-]+)/);
      if (m?.[1]) return m[1];
      m = dec.match(/!1s([^!]+)/);
      if (m?.[1]) {
        const s = decodeURIComponent(m[1]);
        if (/^ChI[0-9A-Za-z_-]+$/.test(s)) return s;
      }
    } catch {}
    return null;
  }

  private extractPlaceIdFromHtml(html: string): string | null {
    let m = html.match(/query_place_id=([^&"'<>\s]+)/i);
    if (m?.[1]) return decodeURIComponent(m[1]);
    m = html.match(/place_id(?:%3A|:)(ChI[0-9A-Za-z_-]+)/i);
    if (m?.[1]) return m[1];
    m = html.match(/!1s([^!]+)/);
    if (m?.[1]) {
      try {
        const s = decodeURIComponent(m[1]);
        if (/^ChI[0-9A-Za-z_-]+$/.test(s)) return s;
      } catch {}
    }
    return null;
  }

  private async followPlaceId(pid: string): Promise<string | null> {
    const UA = 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    const url = `https://www.google.com/maps/search/?api=1&query_place_id=${encodeURIComponent(pid)}`;
    try {
      const r = await this.httpIPv4.get(url, { maxRedirects: 6, headers: { 'user-agent': UA } });
      // @ts-ignore
      return r.request?.res?.responseUrl || r.request?.path || r.config?.url || url;
    } catch { return null; }
  }

  private parseLatLngCandidates(url?: string | null): {
    center?: LatLng; poi?: LatLng; q?: LatLng;
  } {
    const out: { center?: LatLng; poi?: LatLng; q?: LatLng } = {};
    if (!url) return out;
    let u = String(url).trim();
    if (!u) return out;
    try { u = decodeURIComponent(u); } catch {}

    const toNum = (s: string) => Number(String(s).replace(',', '.'));
    const clamp = (lat: number, lng: number): LatLng | null => {
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
      if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
      if (lat === 0 && lng === 0) return null;
      return { lat, lng };
    };

    const m34 = [...u.matchAll(/!3d(-?\d+(?:[.,]\d+)?)!4d(-?\d+(?:[.,]\d+)?)/gi)];
    if (m34.length) {
      const m = m34[m34.length - 1];
      const poi = clamp(toNum(m[1]), toNum(m[2])); if (poi) out.poi = poi;
    } else {
      const m43 = [...u.matchAll(/!4d(-?\d+(?:[.,]\d+)?)!3d(-?\d+(?:[.,]\d+)?)/gi)];
      if (m43.length) {
        const m = m43[m43.length - 1];
        const poi = clamp(toNum(m[2]), toNum(m[1])); if (poi) out.poi = poi;
      }
    }

    const atAll = [...u.matchAll(/@(-?\d+(?:[.,]\d+)?),\s*(-?\d+(?:[.,]\d+)?)/g)];
    if (atAll.length) {
      const last = atAll[atAll.length - 1];
      const center = clamp(toNum(last[1]), toNum(last[2])); if (center) out.center = center;
    }

    try {
      const uri = new URL(u);
      const keys = ['q','ll','query','center','destination','origin','daddr','saddr','sll'];
      for (const k of keys) {
        const v = uri.searchParams.get(k); if (!v) continue;
        const vm = decodeURIComponent(v).match(/(-?\d+(?:[.,]\d+)?)\s*,\s*(-?\d+(?:[.,]\d+)?)/);
        if (!vm) continue;
        const q = clamp(toNum(vm[1]), toNum(vm[2])); if (q) { out.q = q; break; }
      }
    } catch {}

    return out;
  }

  parseLatLngFromGoogleUrl(url?: string | null, preferCenter = false): LatLng | null {
    const raw = (url ?? '').toString();
    const c = this.parseLatLngCandidates(raw);
    const isPlace = /\/maps\/place\//.test(raw) || /!3d|!4d/i.test(raw);
    if (isPlace && c.poi) return c.poi;

    const preferCenterHeuristic =
      !c.poi && ((!!c.center && /@[^/]*,\s*\d+(?:\.\d+)?m/.test(raw)) || /!1e3/.test(raw));
    const useCenterFirst = preferCenter || preferCenterHeuristic;

    if (!useCenterFirst) {
      if (c.poi) return c.poi;
      if (c.center) return c.center;
      if (c.q) return c.q;
      return null;
    } else {
      if (c.center) return c.center;
      if (c.poi) return c.poi;
      if (c.q) return c.q;
      return null;
    }
  }

  private extractPoiFromText(text: string): LatLng | null {
    const toNum = (s: string) => Number(String(s).replace(',', '.'));
    const clamp = (lat: number, lng: number): LatLng | null => {
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
      if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
      if (lat === 0 && lng === 0) return null;
      return { lat, lng };
    };
    const m34 = [...text.matchAll(/!3d(-?\d+(?:[.,]\d+)?)!4d(-?\d+(?:[.,]\d+)?)/gi)];
    if (m34.length) { const m = m34[m34.length - 1]; return clamp(toNum(m[1]), toNum(m[2])); }
    const m43 = [...text.matchAll(/!4d(-?\d+(?:[.,]\d+)?)!3d(-?\d+(?:[.,]\d+)?)/gi)];
    if (m43.length) { const m = m43[m43.length - 1]; return clamp(toNum(m[2]), toNum(m[1])); }
    return null;
  }
}
