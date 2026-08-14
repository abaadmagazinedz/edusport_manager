-- ============================================================================
-- EduSport Manager — Supabase Database Schema
-- Relational, UUID-based, RLS-protected, extensible
-- ============================================================================

create extension if not exists "uuid-ossp";

-- ============================================================================
-- 1. TEACHERS (linked to Supabase auth.users)
-- ============================================================================
create table public.teachers (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  phone text,
  subject text default 'التربية البدنية والرياضية',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- 2. ACADEMIC YEARS
-- ============================================================================
create table public.academic_years (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  label text not null,              -- e.g. '2026/2027'
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (teacher_id, label)
);

-- ============================================================================
-- 3. SECTIONS (classes/groups)
-- ============================================================================
create table public.sections (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  name text not null,                -- e.g. '1AS-Sci-2'
  level text,                        -- e.g. 'أولى ثانوي'
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- 4. STUDENTS
-- ============================================================================
create table public.students (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  registration_number text,
  gender text check (gender in ('male', 'female')),
  birth_date date,
  notes text,
  photo_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_students_section on public.students(section_id);
create index idx_students_teacher on public.students(teacher_id);

-- ============================================================================
-- 5. SESSIONS (حصص)
-- ============================================================================
create table public.sessions (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  subject text default 'التربية البدنية والرياضية',
  session_date date not null,
  start_time time not null,
  duration_minutes int not null default 60,
  activity_type text,                 -- e.g. 'كرة القدم', 'ألعاب القوى'
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_sessions_section on public.sessions(section_id);
create index idx_sessions_date on public.sessions(session_date);

-- ============================================================================
-- 6. ATTENDANCE (الحضور والغياب)
-- ============================================================================
create table public.attendance_records (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  status text not null check (status in ('present', 'absent', 'late', 'excused')),
  minutes_late int,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (session_id, student_id)
);

create index idx_attendance_student on public.attendance_records(student_id);
create index idx_attendance_session on public.attendance_records(session_id);

-- ============================================================================
-- 7. EVALUATION CRITERIA — نظام تقييم واحد موحّد (أكاديمي / بدني / سلوكي)
-- بدل ثلاثة أنظمة متوازية (فروض + معايير رياضية + سلوك)، كل "معيار" مصنّف
-- بفئة، وقابل للإضافة والتعديل والحذف بالكامل من طرف الأستاذ.
-- ============================================================================
create table public.evaluation_criteria (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  name text not null,                  -- e.g. 'فرض', 'السرعة', 'الانضباط'
  category text not null check (category in ('academic', 'physical', 'behavioral')),
  default_coefficient numeric(4,2) not null default 1,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_criteria_teacher on public.evaluation_criteria(teacher_id);

-- ============================================================================
-- 8. EVALUATIONS (كل قياس فعلي لتلميذ حسب معيار معيّن)
-- ============================================================================
create table public.evaluations (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  criterion_id uuid not null references public.evaluation_criteria(id) on delete restrict,
  score numeric(5,2) not null,
  max_score numeric(5,2) not null default 20,
  coefficient numeric(4,2) not null default 1,
  eval_date date not null default current_date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_evaluations_student on public.evaluations(student_id);
create index idx_evaluations_section on public.evaluations(section_id);
create index idx_evaluations_criterion on public.evaluations(criterion_id);

-- ============================================================================
-- 10. MOTIVATION POINTS (نقاط تحفيزية — قواعد قابلة للتعديل)
-- ============================================================================
create table public.motivation_rules (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  label text not null,                 -- e.g. 'حضور', 'مشاركة', 'غياب غير مبرر'
  points int not null,                 -- positive or negative
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.motivation_points (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  rule_id uuid references public.motivation_rules(id) on delete set null,
  points int not null,
  reason text,
  awarded_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_motivation_student on public.motivation_points(student_id);

-- ============================================================================
-- 11. BADGES / ACHIEVEMENTS (شارات وإنجازات)
-- ============================================================================
create table public.badges (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  name text not null,                  -- e.g. 'الحضور المثالي'
  description text,
  icon text,                           -- icon key/name
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.student_badges (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  awarded_date date not null default current_date,
  is_auto boolean not null default false, -- true إن مُنحت تلقائيًا من محرك الشارات
  notes text,
  created_at timestamptz not null default now(),
  unique (student_id, badge_id, awarded_date)
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- Every teacher only sees/modifies their own data.
-- ============================================================================
alter table public.teachers enable row level security;
alter table public.academic_years enable row level security;
alter table public.sections enable row level security;
alter table public.students enable row level security;
alter table public.sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.evaluation_criteria enable row level security;
alter table public.evaluations enable row level security;
alter table public.motivation_rules enable row level security;
alter table public.motivation_points enable row level security;
alter table public.badges enable row level security;
alter table public.student_badges enable row level security;

create policy "teachers_self" on public.teachers
  for all using (id = auth.uid()) with check (id = auth.uid());

-- Generic pattern: teacher_id = auth.uid() for direct-owner tables
create policy "own_rows" on public.academic_years for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.sections for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.students for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.sessions for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.evaluation_criteria for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.evaluations for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.motivation_rules for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.motivation_points for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.badges for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "own_rows" on public.student_badges for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

-- attendance_records has no teacher_id directly -> check via session
create policy "own_via_session" on public.attendance_records for all
  using (exists (
    select 1 from public.sessions s
    where s.id = attendance_records.session_id and s.teacher_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.sessions s
    where s.id = attendance_records.session_id and s.teacher_id = auth.uid()
  ));

-- ============================================================================
-- TRIGGER: auto-update updated_at
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

do $$
declare t text;
begin
  for t in select unnest(array[
    'teachers','academic_years','sections','students','sessions',
    'attendance_records','evaluation_criteria','evaluations',
    'motivation_rules','motivation_points','badges'
  ])
  loop
    execute format(
      'create trigger trg_set_updated_at before update on public.%I
       for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

-- ============================================================================
-- TRIGGER: auto-create teacher profile row on new auth user signup
-- ============================================================================
create or replace function public.handle_new_teacher()
returns trigger as $$
begin
  insert into public.teachers (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_teacher();

-- ============================================================================
-- SEED: default evaluation types, sport disciplines/criteria, motivation rules
-- (Run once per teacher after signup — see app bootstrap logic)
-- ============================================================================
-- These are inserted per-teacher at first login by the app (see
-- lib/services/bootstrap_service.dart) rather than globally, since RLS
-- requires teacher_id ownership.
