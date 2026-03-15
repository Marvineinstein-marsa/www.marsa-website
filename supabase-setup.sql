CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  price INTEGER NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'Electronics',
  stock INTEGER NOT NULL DEFAULT 0,
  image TEXT DEFAULT '📦',
  badge TEXT,
  featured BOOLEAN DEFAULT false,
  rating DECIMAL DEFAULT 4.5,
  reviews_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  email TEXT,
  is_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES auth.users ON DELETE SET NULL,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  customer_phone TEXT,
  customer_address TEXT,
  items JSONB NOT NULL DEFAULT '[]',
  total INTEGER NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'Mobile Money',
  status TEXT NOT NULL DEFAULT 'Pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users ON DELETE SET NULL,
  reviewer_name TEXT NOT NULL DEFAULT 'Anonymous',
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "products_read_all" ON products FOR SELECT USING (true);
CREATE POLICY "products_admin_insert" ON products FOR INSERT WITH CHECK (auth.email() = 'einsteinmarvin256@gmail.com');
CREATE POLICY "products_admin_update" ON products FOR UPDATE USING (auth.email() = 'einsteinmarvin256@gmail.com');
CREATE POLICY "products_admin_delete" ON products FOR DELETE USING (auth.email() = 'einsteinmarvin256@gmail.com');

CREATE POLICY "profiles_read_own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "orders_insert_any" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "orders_read_own" ON orders FOR SELECT USING (auth.uid() = user_id OR auth.email() = 'einsteinmarvin256@gmail.com');
CREATE POLICY "orders_admin_update" ON orders FOR UPDATE USING (auth.email() = 'einsteinmarvin256@gmail.com');

CREATE POLICY "reviews_read_all" ON reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert_auth" ON reviews FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, is_admin)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.email = 'einsteinmarvin256@gmail.com'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (name, description, price, category, stock, image, badge, featured, rating, reviews_count) VALUES
('MARSA Scout Drone X1', 'Professional quadcopter with 4K camera, 30-min flight time and GPS.', 285000, 'Drones', 12, '🛸', 'Bestseller', true, 4.8, 24),
('Arduino Robotics Kit Pro', 'Complete robotics kit with Arduino Mega and servo motors.', 125000, 'Robotics', 20, '🤖', 'New', true, 4.7, 31),
('200W Solar Panel System', 'High-efficiency solar panel with charge controller.', 420000, 'Energy Systems', 8, '☀️', 'Top Rated', true, 4.9, 18),
('Raspberry Pi 4 Starter Pack', 'Raspberry Pi 4 with case, power supply and microSD.', 180000, 'Electronics', 15, '💻', 'Popular', true, 4.8, 67),
('MARSA FPV Racing Drone Z3', 'Racing FPV drone with 5.8GHz video transmission.', 650000, 'Drones', 4, '🚁', 'Premium', true, 4.9, 11),
('Robotic Arm Kit 6-DOF', '6-axis robotic arm with servo motors and Arduino.', 210000, 'Robotics', 10, '🦾', 'New', true, 4.6, 17),
('Smart Telescope 80AZ', '80mm refractor with GoTo motorized mount.', 320000, 'Science Equipment', 7, '🔭', 'Space', true, 4.8, 22),
('DIY Electronics Starter Kit', '850-piece kit with breadboard and components.', 65000, 'DIY Technology', 40, '🔧', null, false, 4.4, 55),
('Digital Multimeter Pro', 'True RMS digital multimeter, auto-ranging.', 28000, 'Electronics', 35, '📊', null, false, 4.7, 93),
('Wind Turbine Generator 500W', 'Permanent magnet wind turbine generator.', 550000, 'Energy Systems', 5, '🌬️', 'Limited', false, 4.7, 9)
ON CONFLICT DO NOTHING;
