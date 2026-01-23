-- ==============================================
-- Öğrenci ve Salon Kayıt Sistemi Migration
-- Supabase SQL Editor'de çalıştırın
-- ==============================================

-- Sınıf seviyeleri (9, 10, 11, 12)
CREATE TABLE IF NOT EXISTS school_grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,  -- "9. Sınıf"
  level INT NOT NULL,          -- 9, 10, 11, 12
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Şubeler (9-A, 9-B, vb.)
CREATE TABLE IF NOT EXISTS school_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  grade_id UUID REFERENCES school_grades(id) ON DELETE CASCADE,
  name VARCHAR(10) NOT NULL,   -- "A", "B", "C"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Öğrenciler
CREATE TABLE IF NOT EXISTS school_students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_id UUID REFERENCES school_sections(id) ON DELETE CASCADE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  student_number VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Salonlar
CREATE TABLE IF NOT EXISTS school_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  row_count INT DEFAULT 5,
  column_count INT DEFAULT 6,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================
-- RLS (Row Level Security) Policies
-- ==============================================

ALTER TABLE school_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_rooms ENABLE ROW LEVEL SECURITY;

-- Grades policies
CREATE POLICY "Users can view own grades" ON school_grades FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own grades" ON school_grades FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own grades" ON school_grades FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own grades" ON school_grades FOR DELETE USING (auth.uid() = user_id);

-- Sections policies (via grade)
CREATE POLICY "Users can view own sections" ON school_sections FOR SELECT 
  USING (EXISTS (SELECT 1 FROM school_grades WHERE id = grade_id AND user_id = auth.uid()));
CREATE POLICY "Users can insert own sections" ON school_sections FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM school_grades WHERE id = grade_id AND user_id = auth.uid()));
CREATE POLICY "Users can update own sections" ON school_sections FOR UPDATE 
  USING (EXISTS (SELECT 1 FROM school_grades WHERE id = grade_id AND user_id = auth.uid()));
CREATE POLICY "Users can delete own sections" ON school_sections FOR DELETE 
  USING (EXISTS (SELECT 1 FROM school_grades WHERE id = grade_id AND user_id = auth.uid()));

-- Students policies (via section > grade)
CREATE POLICY "Users can view own students" ON school_students FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM school_sections s 
    JOIN school_grades g ON s.grade_id = g.id 
    WHERE s.id = section_id AND g.user_id = auth.uid()
  ));
CREATE POLICY "Users can insert own students" ON school_students FOR INSERT 
  WITH CHECK (EXISTS (
    SELECT 1 FROM school_sections s 
    JOIN school_grades g ON s.grade_id = g.id 
    WHERE s.id = section_id AND g.user_id = auth.uid()
  ));
CREATE POLICY "Users can update own students" ON school_students FOR UPDATE 
  USING (EXISTS (
    SELECT 1 FROM school_sections s 
    JOIN school_grades g ON s.grade_id = g.id 
    WHERE s.id = section_id AND g.user_id = auth.uid()
  ));
CREATE POLICY "Users can delete own students" ON school_students FOR DELETE 
  USING (EXISTS (
    SELECT 1 FROM school_sections s 
    JOIN school_grades g ON s.grade_id = g.id 
    WHERE s.id = section_id AND g.user_id = auth.uid()
  ));

-- Rooms policies  
CREATE POLICY "Users can view own rooms" ON school_rooms FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own rooms" ON school_rooms FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own rooms" ON school_rooms FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own rooms" ON school_rooms FOR DELETE USING (auth.uid() = user_id);
