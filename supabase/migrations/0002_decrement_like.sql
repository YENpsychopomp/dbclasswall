-- 0002: decrement RPC for unlike
-- 刪除 question_likes 的去重 row 並安全地把 questions.likes -1
create or replace function public.decrement_question_like(
  qid uuid,
  anon text
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  new_likes integer;
begin
  delete from public.question_likes
    where question_id = qid and anon_id = anon;

  if found then
    update public.questions
      set likes = greatest(likes - 1, 0)
    where id = qid
    returning likes into new_likes;
  else
    select likes into new_likes
      from public.questions
     where id = qid;
  end if;

  return new_likes;
end;
$$;

revoke all on function public.decrement_question_like(uuid, text) from public;
grant execute on function public.decrement_question_like(uuid, text) to anon, authenticated;

comment on function public.decrement_question_like(uuid, text) is
  'Atomically delete dedup row + decrement questions.likes. Anon-callable via supabase.rpc().';
