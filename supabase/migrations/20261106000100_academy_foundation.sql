-- KIVA Academy foundation. Review and apply to a staging Supabase project first.
-- Uses public-prefixed tables so the standard Supabase Data API can serve them
-- with RLS. No Account SSO handoff assumptions are made here.

create extension if not exists pgcrypto;

create table public.academy_provider_organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  verification_status text not null default 'pending' check (verification_status in ('pending','verified','rejected','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.academy_provider_memberships (
  organization_id uuid not null references public.academy_provider_organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  member_role text not null check (member_role in ('owner','trainer','reviewer')),
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);
create index academy_provider_memberships_user_idx on public.academy_provider_memberships(user_id, organization_id);

create table public.academy_platform_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('academy_admin','platform_admin')),
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (user_id, role)
);
create index academy_platform_roles_role_user_idx on public.academy_platform_roles(role, user_id);

create table public.academy_courses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.academy_provider_organizations(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  title text not null check (length(trim(title)) between 3 and 180),
  slug text not null,
  summary text not null default '' check (length(summary) <= 1200),
  destination text not null check (destination in ('UAE','South Africa','Mauritius')),
  category text not null default 'market_knowledge',
  difficulty text not null default 'foundation' check (difficulty in ('foundation','intermediate','advanced')),
  status text not null default 'draft' check (status in ('draft','in_review','published','archived')),
  estimated_minutes integer not null default 0 check (estimated_minutes >= 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, slug)
);
create index academy_courses_catalog_idx on public.academy_courses(status, destination, category, published_at desc);
create index academy_courses_provider_idx on public.academy_courses(organization_id, status, updated_at desc);

create table public.academy_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.academy_courses(id) on delete cascade,
  title text not null check (length(trim(title)) between 2 and 160),
  position integer not null check (position >= 0),
  created_at timestamptz not null default now(),
  unique (course_id, position)
);
create index academy_modules_course_position_idx on public.academy_modules(course_id, position);

create table public.academy_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.academy_modules(id) on delete cascade,
  title text not null check (length(trim(title)) between 2 and 180),
  lesson_type text not null check (lesson_type in ('video','reading','presentation','quiz')),
  body_markdown text not null default '',
  video_asset_id uuid,
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  is_preview boolean not null default false,
  position integer not null check (position >= 0),
  created_at timestamptz not null default now(),
  unique (module_id, position)
);
create index academy_lessons_module_position_idx on public.academy_lessons(module_id, position);

create table public.academy_assets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.academy_provider_organizations(id) on delete cascade,
  course_id uuid references public.academy_courses(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete restrict,
  storage_path text not null unique,
  asset_type text not null check (asset_type in ('video','document','presentation','image','floor_plan')),
  content_type text not null,
  byte_size bigint not null check (byte_size > 0),
  created_at timestamptz not null default now()
);
create index academy_assets_course_idx on public.academy_assets(course_id, created_at desc);
alter table public.academy_lessons add constraint academy_lessons_video_asset_fk foreign key (video_asset_id) references public.academy_assets(id) on delete set null;

create table public.academy_enrollments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.academy_courses(id) on delete restrict,
  learner_id uuid not null references auth.users(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active','completed','withdrawn')),
  completed_at timestamptz,
  unique (course_id, learner_id)
);
create index academy_enrollments_learner_idx on public.academy_enrollments(learner_id, status, enrolled_at desc);
create index academy_enrollments_course_idx on public.academy_enrollments(course_id, status);

create table public.academy_lesson_progress (
  enrollment_id uuid not null references public.academy_enrollments(id) on delete cascade,
  lesson_id uuid not null references public.academy_lessons(id) on delete cascade,
  learner_id uuid not null references auth.users(id) on delete cascade,
  checkpoint_seconds integer not null default 0 check (checkpoint_seconds >= 0),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (enrollment_id, lesson_id)
);
create index academy_lesson_progress_learner_idx on public.academy_lesson_progress(learner_id, updated_at desc);

create table public.academy_quizzes (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null unique references public.academy_lessons(id) on delete cascade,
  pass_mark numeric(5,2) not null default 70 check (pass_mark between 0 and 100),
  max_attempts integer check (max_attempts is null or max_attempts > 0),
  created_at timestamptz not null default now()
);

-- Learner-readable prompt/options are deliberately separated from answer keys.
create table public.academy_quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.academy_quizzes(id) on delete cascade,
  prompt text not null check (length(trim(prompt)) between 2 and 4000),
  options jsonb not null check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) between 2 and 10),
  position integer not null check (position >= 0),
  unique (quiz_id, position)
);
create index academy_quiz_questions_order_idx on public.academy_quiz_questions(quiz_id, position);

create table public.academy_quiz_answer_keys (
  question_id uuid primary key references public.academy_quiz_questions(id) on delete cascade,
  correct_option_indices integer[] not null check (cardinality(correct_option_indices) > 0),
  explanation text not null default ''
);
alter table public.academy_quiz_answer_keys enable row level security;
revoke all on public.academy_quiz_answer_keys from anon, authenticated;

create table public.academy_assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.academy_quizzes(id) on delete restrict,
  learner_id uuid not null references auth.users(id) on delete cascade,
  answers jsonb not null check (jsonb_typeof(answers) = 'object'),
  score numeric(5,2) check (score is null or score between 0 and 100),
  passed boolean,
  submitted_at timestamptz not null default now(),
  graded_at timestamptz
);
create index academy_attempts_learner_quiz_idx on public.academy_assessment_attempts(learner_id, quiz_id, submitted_at desc);

create table public.academy_certificates (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null unique references public.academy_enrollments(id) on delete restrict,
  learner_id uuid not null references auth.users(id) on delete restrict,
  course_id uuid not null references public.academy_courses(id) on delete restrict,
  certificate_number text not null unique default encode(gen_random_bytes(12), 'hex'),
  status text not null default 'issued' check (status in ('issued','revoked')),
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references auth.users(id) on delete set null,
  revocation_reason text check (revocation_reason is null or length(revocation_reason) <= 1000),
  check ((status = 'issued' and revoked_at is null) or (status = 'revoked' and revoked_at is not null))
);
create index academy_certificates_learner_idx on public.academy_certificates(learner_id, issued_at desc);
create index academy_certificates_course_idx on public.academy_certificates(course_id, status);

create table public.academy_meetings (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.academy_courses(id) on delete set null,
  organization_id uuid not null references public.academy_provider_organizations(id) on delete restrict,
  host_id uuid not null references auth.users(id) on delete restrict,
  title text not null check (length(trim(title)) between 3 and 180),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled','live','ended','cancelled')),
  sfu_session_ref text,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index academy_meetings_course_date_idx on public.academy_meetings(course_id, starts_at);
create index academy_meetings_provider_date_idx on public.academy_meetings(organization_id, starts_at);

create table public.academy_meeting_participants (
  meeting_id uuid not null references public.academy_meetings(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  participant_role text not null default 'learner' check (participant_role in ('host','presenter','learner')),
  invited_by uuid references auth.users(id) on delete set null,
  primary key (meeting_id, user_id)
);
create index academy_meeting_participants_user_idx on public.academy_meeting_participants(user_id, meeting_id);

create table public.academy_meeting_attendance (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null,
  user_id uuid not null,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  seconds_attended integer not null default 0 check (seconds_attended >= 0),
  foreign key (meeting_id, user_id) references public.academy_meeting_participants(meeting_id, user_id) on delete cascade
);
create index academy_attendance_meeting_idx on public.academy_meeting_attendance(meeting_id, joined_at);
create index academy_attendance_user_idx on public.academy_meeting_attendance(user_id, joined_at desc);

create table public.academy_meeting_messages (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.academy_meetings(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete restrict,
  body text not null check (length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index academy_meeting_messages_timeline_idx on public.academy_meeting_messages(meeting_id, created_at);

create table public.academy_collaboration_state (
  meeting_id uuid primary key references public.academy_meetings(id) on delete cascade,
  revision bigint not null default 0 check (revision >= 0),
  state jsonb not null default '{}'::jsonb check (jsonb_typeof(state) = 'object'),
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table public.academy_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null check (length(action) between 2 and 100),
  entity_type text not null check (length(entity_type) between 2 and 100),
  entity_id uuid,
  details jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);
create index academy_audit_entity_idx on public.academy_audit_log(entity_type, entity_id, created_at desc);
create index academy_audit_actor_idx on public.academy_audit_log(actor_id, created_at desc);

-- Enable RLS on all Academy tables. Mutating trusted workflows (grading,
-- certificate issue/revoke, provider verification, audit writes, meeting SFU
-- credentials) belong in authenticated server endpoints, never browser writes.
do $$ declare t text; begin
  foreach t in array array[
    'academy_provider_organizations','academy_provider_memberships','academy_platform_roles',
    'academy_courses','academy_modules','academy_lessons','academy_assets','academy_enrollments',
    'academy_lesson_progress','academy_quizzes','academy_quiz_questions','academy_assessment_attempts',
    'academy_certificates','academy_meetings','academy_meeting_participants','academy_meeting_attendance',
    'academy_meeting_messages','academy_collaboration_state','academy_audit_log'
  ] loop execute format('alter table public.%I enable row level security', t); end loop;
end $$;

grant select on public.academy_courses, public.academy_modules, public.academy_lessons,
  public.academy_quizzes, public.academy_quiz_questions to authenticated;
grant select, insert, update on public.academy_enrollments to authenticated;
grant select, insert, update on public.academy_lesson_progress to authenticated;
grant select on public.academy_certificates, public.academy_meetings,
  public.academy_meeting_participants, public.academy_meeting_attendance,
  public.academy_meeting_messages, public.academy_collaboration_state to authenticated;
grant select on public.academy_provider_organizations, public.academy_provider_memberships to authenticated;

create policy "learners read published courses" on public.academy_courses
  for select to authenticated using (status = 'published');
create policy "providers read their courses" on public.academy_courses
  for select to authenticated using (exists (
    select 1 from public.academy_provider_memberships m
    where m.organization_id = academy_courses.organization_id and m.user_id = (select auth.uid())
  ));
create policy "academy admins read courses" on public.academy_courses
  for select to authenticated using (exists (
    select 1 from public.academy_platform_roles r
    where r.user_id = (select auth.uid()) and r.role in ('academy_admin','platform_admin')
  ));

create policy "learners read modules in eligible courses" on public.academy_modules
  for select to authenticated using (exists (
    select 1 from public.academy_courses c where c.id = academy_modules.course_id and c.status = 'published'
  ) or exists (
    select 1 from public.academy_courses c join public.academy_provider_memberships m on m.organization_id = c.organization_id
    where c.id = academy_modules.course_id and m.user_id = (select auth.uid())
  ));
create policy "learners read lessons in eligible courses" on public.academy_lessons
  for select to authenticated using (exists (
    select 1 from public.academy_modules mo join public.academy_courses c on c.id = mo.course_id
    where mo.id = academy_lessons.module_id and (c.status = 'published' or exists (
      select 1 from public.academy_provider_memberships m where m.organization_id = c.organization_id and m.user_id = (select auth.uid())
    ))
  ));
create policy "learners read quiz definitions" on public.academy_quizzes
  for select to authenticated using (exists (
    select 1 from public.academy_lessons l join public.academy_modules mo on mo.id = l.module_id
    join public.academy_courses c on c.id = mo.course_id where l.id = academy_quizzes.lesson_id and c.status = 'published'
  ));
create policy "learners read question prompts" on public.academy_quiz_questions
  for select to authenticated using (exists (
    select 1 from public.academy_quizzes q join public.academy_lessons l on l.id = q.lesson_id
    join public.academy_modules mo on mo.id = l.module_id join public.academy_courses c on c.id = mo.course_id
    where q.id = academy_quiz_questions.quiz_id and c.status = 'published'
  ));

create policy "users read their platform roles" on public.academy_platform_roles
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users read their provider memberships" on public.academy_provider_memberships
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users read verified provider organizations" on public.academy_provider_organizations
  for select to authenticated using (verification_status = 'verified' or exists (
    select 1 from public.academy_provider_memberships m where m.organization_id = academy_provider_organizations.id and m.user_id = (select auth.uid())
  ));

create policy "learners read own enrollments" on public.academy_enrollments
  for select to authenticated using (learner_id = (select auth.uid()));
create policy "learners enroll themselves in published courses" on public.academy_enrollments
  for insert to authenticated with check (
    learner_id = (select auth.uid()) and status = 'active' and completed_at is null and exists (
      select 1 from public.academy_courses c where c.id = course_id and c.status = 'published'
    )
  );
create policy "learners update own active enrollment without changing identity" on public.academy_enrollments
  for update to authenticated using (learner_id = (select auth.uid()) and status = 'active')
  with check (learner_id = (select auth.uid()) and status = 'active' and completed_at is null);

create policy "learners read own progress" on public.academy_lesson_progress
  for select to authenticated using (learner_id = (select auth.uid()) and exists (
    select 1 from public.academy_enrollments e where e.id = enrollment_id and e.learner_id = (select auth.uid()) and e.status = 'active'
  ));
create policy "learners write own progress" on public.academy_lesson_progress
  for insert to authenticated with check (learner_id = (select auth.uid()) and exists (
    select 1 from public.academy_enrollments e where e.id = enrollment_id and e.learner_id = (select auth.uid()) and e.status = 'active'
  ));
create policy "learners update own progress" on public.academy_lesson_progress
  for update to authenticated using (learner_id = (select auth.uid()))
  with check (learner_id = (select auth.uid()) and exists (
    select 1 from public.academy_enrollments e where e.id = enrollment_id and e.learner_id = (select auth.uid()) and e.status = 'active'
  ));

create policy "learners read own attempts" on public.academy_assessment_attempts
  for select to authenticated using (learner_id = (select auth.uid()));
create policy "learners submit own attempts for published quizzes" on public.academy_assessment_attempts
  for insert to authenticated with check (learner_id = (select auth.uid()) and score is null and passed is null and graded_at is null and exists (
    select 1 from public.academy_quizzes q join public.academy_lessons l on l.id = q.lesson_id
    join public.academy_modules mo on mo.id = l.module_id join public.academy_courses c on c.id = mo.course_id
    where q.id = quiz_id and c.status = 'published'
  ));

create policy "learners read own certificates" on public.academy_certificates
  for select to authenticated using (learner_id = (select auth.uid()));
create policy "learners read authorized meetings" on public.academy_meetings
  for select to authenticated using (exists (
    select 1 from public.academy_meeting_participants p where p.meeting_id = academy_meetings.id and p.user_id = (select auth.uid())
  ) or exists (
    select 1 from public.academy_provider_memberships m where m.organization_id = academy_meetings.organization_id and m.user_id = (select auth.uid())
  ));
create policy "participants read own invitations" on public.academy_meeting_participants
  for select to authenticated using (user_id = (select auth.uid()) or exists (
    select 1 from public.academy_meetings me join public.academy_provider_memberships m on m.organization_id = me.organization_id
    where me.id = meeting_id and m.user_id = (select auth.uid())
  ));
create policy "participants read attendance" on public.academy_meeting_attendance
  for select to authenticated using (user_id = (select auth.uid()) or exists (
    select 1 from public.academy_meetings me join public.academy_provider_memberships m on m.organization_id = me.organization_id
    where me.id = meeting_id and m.user_id = (select auth.uid())
  ));
create policy "participants read meeting chat" on public.academy_meeting_messages
  for select to authenticated using (exists (
    select 1 from public.academy_meeting_participants p where p.meeting_id = academy_meeting_messages.meeting_id and p.user_id = (select auth.uid())
  ));
create policy "participants read collaboration state" on public.academy_collaboration_state
  for select to authenticated using (exists (
    select 1 from public.academy_meeting_participants p where p.meeting_id = academy_collaboration_state.meeting_id and p.user_id = (select auth.uid())
  ));

-- No client write policies for provider verification, provider course editing,
-- asset uploads, answer keys, grading, certificate issue/revoke, meeting SFU
-- credentials, chat moderation, collaboration state, or audit records. Add
-- narrowly scoped server-side endpoints after staging policy review.
