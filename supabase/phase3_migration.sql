-- ============================================================================
-- EduSport Manager — ترحيل إلى نظام التقييم الموحّد (المرحلة 3)
--
-- استخدم هذا الملف فقط إذا كنت قد نفّذت schema.sql القديم (الذي كان يحتوي
-- على evaluation_types / grades / sport_disciplines / sport_criteria /
-- sport_evaluations) وتريد ترحيل بياناتك إلى النظام الموحّد الجديد
-- (evaluation_criteria / evaluations) دون فقدانها.
--
-- إن كنت تبدأ مشروعًا جديدًا على Supabase لم يُشغَّل عليه أي شيء بعد،
-- تجاهل هذا الملف تمامًا ونفّذ schema.sql وحده (يحتوي البنية الموحّدة
-- مباشرة).
-- ============================================================================

-- 1) إنشاء الجدولين الموحّدين إن لم يكونا موجودين (نفس تعريف schema.sql)
create table if not exists public.evaluation_criteria (
  id uuid primary key default uuid_generate_v4(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  name text not null,
  category text not null check (category in ('academic', 'physical', 'behavioral')),
  default_coefficient numeric(4,2) not null default 1,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.evaluations (
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

alter table public.evaluation_criteria enable row level security;
alter table public.evaluations enable row level security;

drop policy if exists "own_rows" on public.evaluation_criteria;
create policy "own_rows" on public.evaluation_criteria for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "own_rows" on public.evaluations;
create policy "own_rows" on public.evaluations for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

-- 2) ترحيل أنواع التقييم الأكاديمية القديمة -> معايير أكاديمية جديدة
insert into public.evaluation_criteria (id, teacher_id, name, category, default_coefficient, is_system, created_at)
select id, teacher_id, name, 'academic', default_coefficient, is_system, created_at
from public.evaluation_types
on conflict (id) do nothing;

-- 3) ترحيل معايير التقييم الرياضي القديمة -> معايير بدنية/سلوكية جديدة
insert into public.evaluation_criteria (id, teacher_id, name, category, default_coefficient, is_system, created_at)
select id, teacher_id, name,
       case when category = 'behavioral' then 'behavioral' else 'physical' end,
       default_coefficient, is_system, created_at
from public.sport_criteria
on conflict (id) do nothing;

-- 4) ترحيل العلامات القديمة (grades) -> evaluations
insert into public.evaluations (id, teacher_id, student_id, section_id, criterion_id, score, max_score, coefficient, eval_date, notes, created_at)
select id, teacher_id, student_id, section_id, evaluation_type_id, score, max_score, coefficient, grade_date, notes, created_at
from public.grades
on conflict (id) do nothing;

-- 5) ترحيل التقييمات الرياضية القديمة (sport_evaluations) -> evaluations
--    (section_id غير متوفر في الجدول القديم؛ يُستنتج من قسم التلميذ الحالي)
insert into public.evaluations (id, teacher_id, student_id, section_id, criterion_id, score, max_score, coefficient, eval_date, notes, created_at)
select se.id, se.teacher_id, se.student_id, s.section_id, se.criterion_id, se.score, se.max_score, se.coefficient, se.eval_date, se.notes, se.created_at
from public.sport_evaluations se
join public.students s on s.id = se.student_id
on conflict (id) do nothing;

-- 6) حذف الجداول القديمة بعد التأكد من نجاح الترحيل (راجع بياناتك أولاً!)
-- شغّل هذه الأسطر يدويًا فقط بعد التحقق من صحة الترحيل أعلاه:
-- drop table if exists public.grades cascade;
-- drop table if exists public.sport_evaluations cascade;
-- drop table if exists public.sport_criteria cascade;
-- drop table if exists public.sport_disciplines cascade;
-- drop table if exists public.evaluation_types cascade;

-- 7) عمود جديد لتمييز الشارات الممنوحة تلقائيًا (محرك الشارات)
alter table public.student_badges add column if not exists is_auto boolean not null default false;

-- 8) مشغّلات updated_at للجدولين الجديدين (تفترض وجود set_updated_at من schema.sql)
drop trigger if exists trg_set_updated_at on public.evaluation_criteria;
create trigger trg_set_updated_at before update on public.evaluation_criteria
  for each row execute function public.set_updated_at();

drop trigger if exists trg_set_updated_at on public.evaluations;
create trigger trg_set_updated_at before update on public.evaluations
  for each row execute function public.set_updated_at();
