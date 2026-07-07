-- Hardening to keep the security advisor clean (matches what's deployed):
--  * pin search_path on the trigger helper (lint 0011)
--  * stop the SECURITY DEFINER signup function from being callable via the
--    public RPC API (lints 0028/0029). The trigger on auth.users still fires —
--    triggers don't require EXECUTE grants on their function.
alter function public.set_updated_at() set search_path = '';
revoke execute on function public.handle_new_user() from public, anon, authenticated;
