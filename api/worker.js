import Papa from "papaparse"; 

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    const headers = {
      "content-type": "application/json; charset=UTF-8",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,OPTIONS",
      "access-control-allow-headers": "Content-Type"
    };
    if (request.method === "OPTIONS") return new Response(null, { headers });

    try {
      if (path === "/health") return new Response(JSON.stringify({ ok: true }), { headers });

      if (path === "/routines") {
        const provider = url.searchParams.get("provider");
        const category = url.searchParams.get("category");
        const tag = url.searchParams.get("tag");
        const order = url.searchParams.get("order") || "popular";
        const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 100);
        let where = [], params = [];
        if (provider) { where.push("provider = ?"); params.push(provider); }
        if (category) { where.push("instr(categories, ?) > 0"); params.push(category); }
        if (tag)      { where.push("instr(tags, ?) > 0");       params.push(tag); }
        const whereSQL = where.length ? ("WHERE " + where.join(" AND ")) : "";
        const orderSQL = order === "new" ? "created_at DESC" : "popularity_score DESC";
        const stmt = env.DB.prepare(`
          SELECT id,title,categories,cost_krw,time_min,difficulty,influencer_id,
                 popularity_score,video_url,thumbnail_url,provider,tags,created_at
          FROM routines
          ${whereSQL}
          ORDER BY ${orderSQL}
          LIMIT ?
        `).bind(...params, limit);
        const { results } = await stmt.all();
        return new Response(JSON.stringify({ items: results }), { headers });
      }

      const m = path.match(/^\/routines\/([^/]+)$/);
      if (m) {
        const rid = m[1];
        const r = await env.DB.prepare(`SELECT * FROM routines WHERE id = ?`).bind(rid).first();
        if (!r) return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers });
        const elems = await env.DB.prepare(`SELECT * FROM routine_elements WHERE routine_id = ? ORDER BY eid ASC`).bind(rid).all();
        r.elements = elems.results || [];
        return new Response(JSON.stringify(r), { headers });
      }

      if (path === "/trends") {
        const limit = Math.min(parseInt(url.searchParams.get("limit") || "100"), 1000);
        const { results } = await env.DB.prepare(`
          SELECT tags FROM routines ORDER BY datetime(created_at) DESC LIMIT ?
        `).bind(limit).all();
        const counts = {};
        for (const row of results) {
          const t = (row.tags || "").split(";").map(s => s.trim()).filter(Boolean);
          for (const x of t) counts[x] = (counts[x] || 0) + 1;
        }
        const top = Object.entries(counts).sort((a,b)=>b[1]-a[1]).slice(0,10).map(([tag,count])=>({tag,count}));
        return new Response(JSON.stringify({ tags: top }), { headers });
      }

   
      if (path === "/sync") {
        const result = await syncFromSheet(env);
        return new Response(JSON.stringify(result), { headers });
      }

      return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers });

    } catch (e) {
      return new Response(JSON.stringify({ error: "server_error", message: String(e) }), { status: 500, headers });
    }
  },


  async scheduled(event, env, ctx) {
    ctx.waitUntil(syncFromSheet(env));
  }
};

async function syncFromSheet(env) {
  try {
    const res = await fetch(env.SHEETS_CSV_URL);
    const text = await res.text();

    const parsed = Papa.parse(text, { header: true }).data;
    let insertedInfluencers = 0;
    let insertedRoutines = 0;

    for (const row of parsed) {
      if (!row["프로필 ID"] || !row["콘텐츠 ID"]) continue;


      await env.DB.prepare(
        `INSERT OR IGNORE INTO influencers (id, name, platform, handle, channel_url, followers)
         VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(
        row["프로필 ID"],
        row["프로필 ID"],
        row["분류"],
        row["프로필 ID"],
        row["프로필 url"],
        parseInt(row["구독자/팔로워 수"].replace(/,/g, "")) || 0
      ).run();
      insertedInfluencers++;

      await env.DB.prepare(
        `INSERT OR IGNORE INTO routines
        (id, title, categories, cost_krw, time_min, difficulty, influencer_id, popularity_score,
         video_url, thumbnail_url, provider, tags, created_at)
         VALUES (?, ?, ?, 0, 0, 1, ?, 50, ?, ?, ?, ?, datetime('now'))`
      ).bind(
        row["콘텐츠 ID"],
        row["제목"],
        row["키워드"],
        row["프로필 ID"],
        row["영상 url"],
        row["이미지 url"],
        row["분류"],
        row["키워드"]
      ).run();
      insertedRoutines++;
    }

    return { ok: true, influencers: insertedInfluencers, routines: insertedRoutines };
  } catch (err) {
    return { ok: false, error: err.message };
  }
}
