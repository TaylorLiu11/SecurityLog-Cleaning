/**
 * API Gateway for Honeypot Logs
 * Implementation: TypeScript + Cloudflare Workers (ESM)
 * Purpose: Provides a secure abstraction layer between the frontend and Supabase
 */

// 
export interface Env {
  SUPABASE_URL: string,
  SUPABASE_PUBLISHABLE_KEY: string;
}

interface AnalyticsQuery {
  start_ts: string,
  end_ts: string
}

export default {
  async fetch(
    request: Request,
    env: Env,
    ctx: ExecutionContext
  ): Promise<Response> {
    // CORS = Cross-Origin Resource Sharing
    // By default, browsers block APIs coming from other origins (different domains)
    const corsHeaders = {
      // This allows any origins
      // Todo: Change this to the frontend URL
      "Access-Control-Allow-Origin": "*",
      // 
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      // 
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method Not Allow" }), {
        status: 405,
        headers: corsHeaders
      });
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

      const rpcMap: Record<string, string> = {
        "/api/stats": "get_dashboard_stats",
        "/api/countries": "get_country_distribution"
      };

      const rpcName = rpcMap[path];
      if(!rpcName) {
        return new Response(JSON.stringify({ error: "Route Not Found" }), {
          status: 404,
          headers: corsHeaders
        });
      }

      const body: AnalyticsQuery = await request.json();
      if (!body.start_ts || !body.end_ts) {
        throw new Error("Missing timeframe parameters");
      }

      const supabaseResponse = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/${rpcName}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": env.SUPABASE_PUBLISHABLE_KEY,
          "Authorization": `Bearer ${env.SUPABASE_PUBLISHABLE_KEY}`,
        },
        body: JSON.stringify(body),
      });

      if (!supabaseResponse.ok) {
        const errorDetail = await supabaseResponse.text();
        console.error(`Supabase Error: ${supabaseResponse.status}: ${errorDetail}`);
        throw new Error("Database service unavailable");
      }

      const data = await supabaseResponse.json();

      return new Response(JSON.stringify(data), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "X-Content-Type-Options": "nosniff",
          "Server": "Cloudflare-Worker-Gateway"
        },
      });

    } catch (error: any) {
      console.log(`Error: ${error}`)
      return new Response(JSON.stringify({ error: "Internal Server Error"}), {
        status: 500,
        headers: corsHeaders,
      });
    }
  },
};