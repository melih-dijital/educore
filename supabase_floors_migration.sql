-- floors tablosu oluştur
-- Supabase Dashboard > SQL Editor'da bu SQL'i çalıştırın

CREATE TABLE IF NOT EXISTS floors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  floor_order integer NOT NULL DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- RLS politikaları
ALTER TABLE floors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own floors" ON floors
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own floors" ON floors
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own floors" ON floors
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own floors" ON floors
  FOR DELETE USING (auth.uid() = user_id);
