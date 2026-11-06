export const onRequestGet = async () => new Response(
  JSON.stringify({ service: 'kiva-academy-api', status: 'ok' }),
  { headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } },
)
