-- Ghumakkad Complete Database Schema

CREATE TABLE users (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  phone           VARCHAR(15) NOT NULL UNIQUE,
  name            VARCHAR(100) NOT NULL,
  avatar_url      VARCHAR(255),
  fcm_token       VARCHAR(255),
  is_active       TINYINT(1) DEFAULT 1,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE trips (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid            CHAR(36) NOT NULL UNIQUE,             -- for share links
  title           VARCHAR(150) NOT NULL,                -- "Spiti Valley 2024"
  description     TEXT,
  cover_image_url VARCHAR(255),
  start_date      DATE,
  end_date        DATE,
  creator_id      INT UNSIGNED NOT NULL,
  status          ENUM('active','archived') DEFAULT 'active',
  invite_code     VARCHAR(12) UNIQUE,                   -- 12-char alphanumeric
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (creator_id) REFERENCES users(id)
);

CREATE TABLE trip_members (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id         INT UNSIGNED NOT NULL,
  user_id         INT UNSIGNED NOT NULL,
  role            ENUM('creator','member') DEFAULT 'member',
  joined_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_trip_user (trip_id, user_id),
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE trip_pins (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id         INT UNSIGNED NOT NULL,
  added_by        INT UNSIGNED NOT NULL,
  pin_type        ENUM('memory','hotel','ticket','food','viewpoint','custom') DEFAULT 'memory',
  title           VARCHAR(150),
  latitude        DECIMAL(10,7) NOT NULL,
  longitude       DECIMAL(10,7) NOT NULL,
  address         VARCHAR(255),
  pin_order       INT UNSIGNED DEFAULT 0,               -- for route sequence
  pinned_at       DATETIME,                             -- actual moment (not created_at)
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (added_by) REFERENCES users(id)
);

CREATE TABLE pin_memories (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pin_id          INT UNSIGNED NOT NULL,
  added_by        INT UNSIGNED NOT NULL,
  memory_type     ENUM('photo','note') NOT NULL,
  content         TEXT,                                 -- note text or image URL
  caption         VARCHAR(255),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pin_id) REFERENCES trip_pins(id),
  FOREIGN KEY (added_by) REFERENCES users(id)
);

CREATE TABLE trip_tickets (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id         INT UNSIGNED NOT NULL,
  pin_id          INT UNSIGNED,                         -- optional: link to a pin
  added_by        INT UNSIGNED NOT NULL,
  ticket_type     ENUM('flight','train','bus','other') NOT NULL,
  from_place      VARCHAR(150) NOT NULL,
  to_place        VARCHAR(150) NOT NULL,
  travel_date     DATE,
  travel_time     TIME,
  pnr_number      VARCHAR(50),
  amount          DECIMAL(10,2) DEFAULT 0,
  ticket_image_url VARCHAR(255),
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (pin_id) REFERENCES trip_pins(id),
  FOREIGN KEY (added_by) REFERENCES users(id)
);

CREATE TABLE trip_hotels (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id         INT UNSIGNED NOT NULL,
  pin_id          INT UNSIGNED,
  added_by        INT UNSIGNED NOT NULL,
  hotel_name      VARCHAR(150) NOT NULL,
  city            VARCHAR(100),
  check_in        DATE,
  check_out       DATE,
  confirmation_no VARCHAR(100),
  amount          DECIMAL(10,2) DEFAULT 0,
  booking_image_url VARCHAR(255),
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (pin_id) REFERENCES trip_pins(id),
  FOREIGN KEY (added_by) REFERENCES users(id)
);

CREATE TABLE trip_expenses (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id         INT UNSIGNED NOT NULL,
  paid_by         INT UNSIGNED NOT NULL,
  title           VARCHAR(150) NOT NULL,               -- "Petrol Manali", "Dinner at Rohtang"
  amount          DECIMAL(10,2) NOT NULL,
  split_type      ENUM('equal','custom','individual') NOT NULL,
  expense_date    DATE,
  category        ENUM('transport','food','hotel','ticket','activity','other') DEFAULT 'other',
  receipt_url     VARCHAR(255),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (paid_by) REFERENCES users(id)
);

CREATE TABLE expense_splits (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expense_id      INT UNSIGNED NOT NULL,
  user_id         INT UNSIGNED NOT NULL,
  share_amount    DECIMAL(10,2) NOT NULL,
  is_settled      TINYINT(1) DEFAULT 0,
  settled_at      TIMESTAMP NULL,
  FOREIGN KEY (expense_id) REFERENCES trip_expenses(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE trip_route (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id         INT UNSIGNED NOT NULL,
  latitude        DECIMAL(10,7) NOT NULL,
  longitude       DECIMAL(10,7) NOT NULL,
  point_order     INT UNSIGNED NOT NULL,
  FOREIGN KEY (trip_id) REFERENCES trips(id)
);

CREATE TABLE admin_users (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email           VARCHAR(150) NOT NULL UNIQUE,
  password_hash   VARCHAR(255) NOT NULL,
  name            VARCHAR(100),
  is_active       TINYINT(1) DEFAULT 1,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth_tokens (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id         INT UNSIGNED NOT NULL,
  token           VARCHAR(255) NOT NULL UNIQUE,
  expires_at      DATETIME NOT NULL,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
