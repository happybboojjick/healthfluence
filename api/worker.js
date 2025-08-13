import Papa from "papaparse";

// ================================
// Cloudflare Worker (D1 API)
// ================================
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // 공통 CORS 헤더
    const headers = {
      "content-type": "application/json; charset=UTF-8",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,OPTIONS",
      "access-control-allow-headers": "Content-Type"
    };
    if (method === "OPTIONS") return new Response(null, { headers });

    try {
      // 헬스체크
      if (path === "/health") {
        return new Response(JSON.stringify({ ok: true }), { headers });
      }

      // -----------------------------------------
      // [GET] /influencers?platform=&search=&limit=&offset=
      // - platform: 'youtube' / 'tiktok' 등
      // - search: name/handle 부분매치 (대소문자 무시)
      // -----------------------------------------
      if (path === "/influencers" && method === "GET") {
        const platform = url.searchParams.get("platform");
        const search   = url.searchParams.get("search");
        const limit    = Math.min(parseInt(url.searchParams.get("limit")  || "100"), 500);
        const offset   = Math.max(parseInt(url.searchParams.get("offset") || "0"), 0);

        const where = [];
        const params = [];

        if (platform) {
          where.push("platform = ?");
          params.push(platform);
        }
        if (search) {
          // 대소문자 무시 부분매치
          where.push("(lower(name) LIKE lower(?) OR lower(handle) LIKE lower(?))");
          params.push(`%${search}%`, `%${search}%`);
        }

        let sql = `
          SELECT id, name, platform, handle, channel_url, followers
          FROM influencers
        `;
        if (where.length) sql += " WHERE " + where.join(" AND ");
        sql += " ORDER BY followers DESC LIMIT ? OFFSET ?";

        const { results } = await env.DB.prepare(sql).bind(...params, limit, offset).all();
        return new Response(JSON.stringify({ items: results }), { headers });
      }

      // -----------------------------------------
      // [GET] /routines?provider=&category=&tag=&influencer_id=&order=&limit=&offset=
      // - provider: 필터 (예: 'youtube', 'tiktok', 커스텀 등)
      // - category/tag: TEXT 컬럼에 부분 포함 (대소문자 무시)
      // - influencer_id: 해당 인플루언서 소속만
      // - order: 'popular'(기본) | 'new' | 'time_asc' | 'time_desc'
      // -----------------------------------------
      if (path === "/routines" && method === "GET") {
        const provider     = url.searchParams.get("provider");
        const category     = url.searchParams.get("category");
        const tag          = url.searchParams.get("tag");
        const influencerId = url.searchParams.get("influencer_id");
        const orderParam   = url.searchParams.get("order") || "popular";
        const limit        = Math.min(parseInt(url.searchParams.get("limit")  || "20"), 100);
        const offset       = Math.max(parseInt(url.searchParams.get("offset") || "0"), 0);

        const where = [];
        const params = [];

        if (provider) {
          where.push("provider = ?");
          params.push(provider);
        }
        if (category) {
          // categories TEXT에 부분 포함 (대소문자 무시)
          where.push("instr(lower(categories), lower(?)) > 0");
          params.push(category);
        }
        if (tag) {
          // tags TEXT에 부분 포함 (대소문자 무시)
          where.push("instr(lower(tags), lower(?)) > 0");
          params.push(tag);
        }
        if (influencerId) {
          where.push("influencer_id = ?");
          params.push(influencerId);
        }

        let orderSQL = "popularity_score DESC";
        switch (orderParam) {
          case "new":       orderSQL = "datetime(created_at) DESC"; break;
          case "time_asc":  orderSQL = "time_min ASC"; break;
          case "time_desc": orderSQL = "time_min DESC"; break;
          default:          orderSQL = "popularity_score DESC";
        }

        let sql = `
          SELECT
            id, title, categories, cost_krw, time_min, difficulty, influencer_id,
            popularity_score, video_url, thumbnail_url, provider, tags, created_at
          FROM routines
        `;
        if (where.length) sql += " WHERE " + where.join(" AND ");
        sql += ` ORDER BY ${orderSQL} LIMIT ? OFFSET ?`;

        const { results } = await env.DB.prepare(sql).bind(...params, limit, offset).all();
        // NOTE: categories/tags는 TEXT 그대로 반환 (Flutter 쪽 기존 파서 유지 시 호환)
        return new Response(JSON.stringify({ items: results }), { headers });
      }

      // -----------------------------------------
      // [GET] /routines/:id  → 루틴 상세 + elements
      // -----------------------------------------
      const m = path.match(/^\/routines\/([^/]+)$/);
      if (m && method === "GET") {
        const rid = m[1];

        const r = await env.DB
          .prepare(`SELECT * FROM routines WHERE id = ?`)
          .bind(rid)
          .first();

        if (!r) {
          return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers });
        }

        // eid가 문자열일 수 있어 숫자 정렬 보장
        const elems = await env.DB
          .prepare(`
            SELECT * FROM routine_elements
            WHERE routine_id = ?
            ORDER BY CAST(eid AS INTEGER) ASC
          `)
          .bind(rid)
          .all();

        r.elements = elems.results || [];
        return new Response(JSON.stringify(r), { headers });
      }

      // -----------------------------------------
      // [GET] /trends  → 최근 태그 Top-N 집계
      // -----------------------------------------
      if (path === "/trends" && method === "GET") {
        const limit = Math.min(parseInt(url.searchParams.get("limit") || "100"), 1000);
        const { results } = await env.DB.prepare(`
          SELECT tags FROM routines ORDER BY datetime(created_at) DESC LIMIT ?
        `).bind(limit).all();

        const counts = {};
        for (const row of results) {
          // 쉼표/세미콜론 구분 모두 허용
          const t = String(row?.tags || "")
            .split(/[,;]+/)
            .map(s => s.trim())
            .filter(Boolean);
          for (const x of t) counts[x] = (counts[x] || 0) + 1;
        }

        const top = Object.entries(counts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 10)
          .map(([tag, count]) => ({ tag, count }));

        return new Response(JSON.stringify({ tags: top }), { headers });
      }

      // -----------------------------------------
      // [POST or CRON] /sync  → 시트 동기화
      // - ENV: SHEETS_CSV_URL 필요
      // -----------------------------------------
      if (path === "/sync") {
        const result = await syncFromSheet(env);
        return new Response(JSON.stringify(result), { headers });
      }

      // not found
      return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers });

    } catch (e) {
      return new Response(JSON.stringify({ error: "server_error", message: String(e) }), { status: 500, headers });
    }
  },

  // 스케줄 트리거(선택)
  async scheduled(event, env, ctx) {
    ctx.waitUntil(syncFromSheet(env));
  }
};

// ================================
// Helpers
// ================================

/**
 * Google Sheets CSV → D1 동기화
 * ENV:
 *  - SHEETS_CSV_URL: 퍼블릭 CSV URL
 */
async function syncFromSheet(env) {
  try {
    if (!env.SHEETS_CSV_URL) {
      return { ok: false, error: "SHEETS_CSV_URL is not set" };
    }

    const res = await fetch(env.SHEETS_CSV_URL);
    if (!res.ok) {
      return { ok: false, error: `Failed to fetch CSV: ${res.status}` };
    }
    const text = await res.text();

    const parsed = Papa.parse(text, { header: true }).data;
    let upsertInfluencers = 0;
    let upsertRoutines = 0;

    for (const row of parsed) {
      if (!row["프로필 ID"] || !row["콘텐츠 ID"]) continue;

      // ========== influencers upsert ==========
      // NOTE: name/handle 매핑은 시트 컬럼명에 맞게 필요시 조정하세요.
      await env.DB.prepare(
        `INSERT OR IGNORE INTO influencers (id, name, platform, handle, channel_url, followers)
         VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(
        row["프로필 ID"],                    // id
        row["프로필 ID"],                    // name (필요시 "프로필 이름" 등으로 교체)
        row["분류"],                         // platform (예: youtube/tiktok 등)
        row["프로필 ID"],                    // handle (필요시 "@handle" 등으로 교체)
        row["프로필 url"],                   // channel_url
        parseInt(String(row["구독자/팔로워 수"] || "0").replace(/,/g, "")) || 0 // followers
      ).run();
      upsertInfluencers++;

      // ========== routines upsert ==========
      await env.DB.prepare(
        `INSERT OR IGNORE INTO routines
          (id, title, categories, cost_krw, time_min, difficulty, influencer_id, popularity_score,
           video_url, thumbnail_url, provider, tags, created_at)
         VALUES (?, ?, ?, 0, 0, 1, ?, 50, ?, ?, ?, ?, datetime('now'))`
      ).bind(
        row["콘텐츠 ID"],  // id
        row["제목"],       // title
        row["키워드"],     // categories (TEXT)
        row["프로필 ID"],  // influencer_id
        row["영상 url"],   // video_url
        row["이미지 url"], // thumbnail_url
        row["분류"],       // provider
        row["키워드"]      // tags (TEXT)
      ).run();
      upsertRoutines++;
    }

    return { ok: true, influencers: upsertInfluencers, routines: upsertRoutines };
  } catch (err) {
    return { ok: false, error: String(err?.message || err) };
  }
}
