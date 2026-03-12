-- ============================================================
-- Flash Pharma — Supabase Database Setup
-- Run this SQL in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. PROFILES (extends auth.users)
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  email text not null,
  phone text default '',
  role text not null default 'patient'
    check (role in ('patient', 'pharmacy', 'admin', 'delivery')),
  avatar_url text,
  address text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz default now()
);

-- 2. PHARMACIES
create table if not exists pharmacies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references profiles(id) on delete cascade not null,
  name text not null,
  owner_name text not null,
  email text not null,
  phone text not null,
  address text not null,
  latitude double precision not null,
  longitude double precision not null,
  image_url text,
  license_number text not null,
  rating double precision default 0,
  total_ratings int default 0,
  is_open boolean default true,
  open_time text default '08:00',
  close_time text default '22:00',
  delivery_radius double precision default 10.0,
  delivery_fee double precision default 30.0,
  created_at timestamptz default now()
);

-- 3. MEDICINES
create table if not exists medicines (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  generic_name text default '',
  manufacturer text default '',
  category text default '',
  description text default '',
  dosage_form text default '',
  strength text default '',
  image_url text,
  requires_prescription boolean default false,
  tags text[] default '{}',
  created_at timestamptz default now()
);

-- 4. INVENTORY (pharmacy stock)
create table if not exists inventory (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid references pharmacies(id) on delete cascade not null,
  medicine_id uuid references medicines(id) on delete cascade not null,
  price double precision not null,
  quantity int not null default 0,
  batch_number text default '',
  expiry_date date not null,
  in_stock boolean default true,
  updated_at timestamptz default now()
);

-- 5. ORDERS
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references profiles(id) not null,
  patient_name text not null,
  pharmacy_id uuid references pharmacies(id) not null,
  pharmacy_name text not null,
  delivery_agent_id uuid,
  delivery_agent_name text,
  subtotal double precision not null,
  delivery_fee double precision not null,
  discount double precision default 0,
  total_amount double precision not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','preparing','out_for_delivery','delivered','cancelled')),
  delivery_address text not null,
  delivery_latitude double precision not null,
  delivery_longitude double precision not null,
  prescription_url text,
  payment_method text not null,
  payment_status text default 'pending',
  payment_id text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  delivered_at timestamptz
);

-- 6. ORDER ITEMS
create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade not null,
  medicine_id uuid not null,
  medicine_name text not null,
  medicine_image_url text,
  quantity int not null,
  unit_price double precision not null,
  total_price double precision not null
);

-- 7. SEARCH LOGS (for trending)
create table if not exists search_logs (
  id uuid primary key default gen_random_uuid(),
  query text not null,
  user_id uuid references profiles(id),
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table profiles enable row level security;
alter table pharmacies enable row level security;
alter table medicines enable row level security;
alter table inventory enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table search_logs enable row level security;

-- PROFILES policies
create policy "Profiles are viewable by everyone"
  on profiles for select using (true);
create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);
create policy "Users can insert own profile"
  on profiles for insert with check (auth.uid() = id);

-- PHARMACIES policies
create policy "Pharmacies are viewable by everyone"
  on pharmacies for select using (true);
create policy "Pharmacy owner can update"
  on pharmacies for update using (auth.uid() = owner_id);
create policy "Pharmacy owner can insert"
  on pharmacies for insert with check (auth.uid() = owner_id);

-- MEDICINES policies
create policy "Medicines are viewable by everyone"
  on medicines for select using (true);
create policy "Authenticated users can insert medicines"
  on medicines for insert with check (auth.role() = 'authenticated');
create policy "Authenticated users can update medicines"
  on medicines for update using (auth.role() = 'authenticated');

-- INVENTORY policies
create policy "Inventory is viewable by everyone"
  on inventory for select using (true);
create policy "Pharmacy owner can manage inventory"
  on inventory for insert with check (
    exists (select 1 from pharmacies where id = pharmacy_id and owner_id = auth.uid())
  );
create policy "Pharmacy owner can update inventory"
  on inventory for update using (
    exists (select 1 from pharmacies where id = pharmacy_id and owner_id = auth.uid())
  );
create policy "Pharmacy owner can delete inventory"
  on inventory for delete using (
    exists (select 1 from pharmacies where id = pharmacy_id and owner_id = auth.uid())
  );

-- ORDERS policies
create policy "Patients can view own orders"
  on orders for select using (auth.uid() = patient_id);
create policy "Pharmacies can view their orders"
  on orders for select using (
    exists (select 1 from pharmacies where id = pharmacy_id and owner_id = auth.uid())
  );
create policy "Patients can create orders"
  on orders for insert with check (auth.uid() = patient_id);
create policy "Pharmacies can update order status"
  on orders for update using (
    exists (select 1 from pharmacies where id = pharmacy_id and owner_id = auth.uid())
  );

-- ORDER ITEMS policies
create policy "Order items viewable by order owner"
  on order_items for select using (
    exists (select 1 from orders where id = order_id and (patient_id = auth.uid()
      or exists (select 1 from pharmacies where id = orders.pharmacy_id and owner_id = auth.uid())))
  );
create policy "Patients can insert order items"
  on order_items for insert with check (
    exists (select 1 from orders where id = order_id and patient_id = auth.uid())
  );

-- SEARCH LOGS policies
create policy "Anyone can insert search logs"
  on search_logs for insert with check (true);
create policy "Anyone can read search logs"
  on search_logs for select using (true);

-- ============================================================
-- AUTO-CREATE PROFILE ON SIGNUP (trigger)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, phone, role, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'User'),
    new.email,
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'role', 'patient'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Drop if exists then create trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- SEED DATA — Sample medicines
-- ============================================================
insert into medicines (name, generic_name, manufacturer, category, dosage_form, strength, requires_prescription) values
  ('Dolo 650', 'Paracetamol', 'Micro Labs', 'Pain Relief', 'Tablet', '650mg', false),
  ('Crocin Advance', 'Paracetamol', 'GSK', 'Pain Relief', 'Tablet', '500mg', false),
  ('Azithral 500', 'Azithromycin', 'Alembic Pharma', 'Antibiotic', 'Tablet', '500mg', true),
  ('Pan 40', 'Pantoprazole', 'Alkem', 'Gastro', 'Tablet', '40mg', false),
  ('Shelcal 500', 'Calcium + Vitamin D3', 'Torrent Pharma', 'Supplement', 'Tablet', '500mg', false),
  ('Allegra 120', 'Fexofenadine', 'Sanofi', 'Allergy', 'Tablet', '120mg', false),
  ('Augmentin 625', 'Amoxicillin + Clavulanate', 'GSK', 'Antibiotic', 'Tablet', '625mg', true),
  ('Combiflam', 'Ibuprofen + Paracetamol', 'Sanofi', 'Pain Relief', 'Tablet', '400mg+325mg', false),
  ('Cetirizine', 'Cetirizine', 'Cipla', 'Allergy', 'Tablet', '10mg', false),
  ('ORS Powder', 'Oral Rehydration Salts', 'WHO Standard', 'Electrolyte', 'Powder', '21g', false),
  ('Betadine', 'Povidone Iodine', 'Win Medicare', 'Antiseptic', 'Solution', '5%', false),
  ('Volini Spray', 'Diclofenac + Methyl Salicylate', 'Sun Pharma', 'Pain Relief', 'Spray', '15g', false),
  ('Metformin 500', 'Metformin', 'USV', 'Diabetes', 'Tablet', '500mg', true),
  ('Ecosprin 75', 'Aspirin', 'USV', 'Cardio', 'Tablet', '75mg', true),
  ('Limcee', 'Vitamin C', 'Abbott', 'Supplement', 'Chewable Tablet', '500mg', false);

-- ============================================================
-- DONE! Your database is ready.
-- ============================================================
