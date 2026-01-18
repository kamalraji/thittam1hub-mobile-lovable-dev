import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const GIPHY_API_KEY = Deno.env.get('GIPHY_API_KEY');
    
    if (!GIPHY_API_KEY) {
      console.error('GIPHY_API_KEY not configured');
      return new Response(
        JSON.stringify({ error: 'Giphy API key not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const url = new URL(req.url);
    const action = url.searchParams.get('action') || 'trending';
    const query = url.searchParams.get('q') || '';
    const limit = url.searchParams.get('limit') || '25';
    const offset = url.searchParams.get('offset') || '0';
    const rating = 'pg-13';

    let giphyUrl: string;
    
    if (action === 'search' && query) {
      giphyUrl = `https://api.giphy.com/v1/gifs/search?api_key=${GIPHY_API_KEY}&q=${encodeURIComponent(query)}&limit=${limit}&offset=${offset}&rating=${rating}&lang=en`;
    } else {
      giphyUrl = `https://api.giphy.com/v1/gifs/trending?api_key=${GIPHY_API_KEY}&limit=${limit}&offset=${offset}&rating=${rating}`;
    }

    console.log(`Fetching from Giphy: action=${action}, query=${query}, limit=${limit}, offset=${offset}`);
    
    const response = await fetch(giphyUrl);
    const data = await response.json();

    if (!response.ok) {
      console.error('Giphy API error:', data);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch from Giphy', details: data }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Giphy returned ${data.data?.length || 0} results`);

    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error: unknown) {
    console.error('Error in giphy-proxy:', error);
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(
      JSON.stringify({ error: 'Internal server error', message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
