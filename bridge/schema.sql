CREATE TABLE IF NOT EXISTS hotel_rentals (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    identifier  VARCHAR(100) NOT NULL,
    hotel       VARCHAR(100) NOT NULL,
    room        INT NOT NULL,
    expires     INT NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hotel_bookings (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    identifier  VARCHAR(100) NOT NULL,
    hotel       VARCHAR(100) NOT NULL,
    room        INT NOT NULL,
    start_time  INT NOT NULL,
    end_time    INT NOT NULL,
    status      VARCHAR(30) DEFAULT 'active',
    cost        INT DEFAULT 0,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hotel_keys (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    identifier  VARCHAR(100) NOT NULL,
    hotel       VARCHAR(100) NOT NULL,
    room        INT NOT NULL,
    expires     INT DEFAULT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hotel_fines (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    hotel       VARCHAR(100) NOT NULL,
    identifier  VARCHAR(100) NOT NULL,
    amount      INT NOT NULL,
    reason      TEXT,
    created_at  INT NOT NULL
);

CREATE TABLE IF NOT EXISTS hotel_complaints (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    hotel       VARCHAR(100) NOT NULL,
    identifier  VARCHAR(100) NOT NULL,
    room        INT DEFAULT NULL,
    category    VARCHAR(100) DEFAULT 'Other',
    message     TEXT NOT NULL,
    status      VARCHAR(30) DEFAULT 'open',
    created_at  INT NOT NULL,
    resolved_at INT DEFAULT NULL,
    resolved_by VARCHAR(100) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS hotel_room_states (
    hotel      VARCHAR(100) NOT NULL,
    room       INT NOT NULL,
    state      VARCHAR(30) DEFAULT 'clean',
    updated_at INT NOT NULL,
    PRIMARY KEY (hotel, room)
);

CREATE TABLE IF NOT EXISTS hotel_ownership (
    hotel      VARCHAR(100) PRIMARY KEY,
    owner      VARCHAR(100) DEFAULT NULL,
    balance    INT DEFAULT 0,
    reputation INT DEFAULT 50
);

CREATE TABLE IF NOT EXISTS hotel_jobs (
    identifier VARCHAR(100) NOT NULL,
    hotel      VARCHAR(100) NOT NULL,
    role       VARCHAR(50) NOT NULL,
    PRIMARY KEY (identifier, role)
);

CREATE TABLE IF NOT EXISTS hotel_outfits (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(100) NOT NULL,
    name       VARCHAR(100) NOT NULL,
    skin       LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hotel_transactions (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(100) NOT NULL,
    amount     INT NOT NULL,
    type       VARCHAR(50) NOT NULL,
    reason     TEXT,
    created_at INT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_hotel_rentals_identifier   ON hotel_rentals(identifier);
CREATE INDEX IF NOT EXISTS idx_hotel_rentals_hotel_room   ON hotel_rentals(hotel, room);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_hotel_room  ON hotel_bookings(hotel, room);
CREATE INDEX IF NOT EXISTS idx_hotel_complaints_hotel     ON hotel_complaints(hotel);
