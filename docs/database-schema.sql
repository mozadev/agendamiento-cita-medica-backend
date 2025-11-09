-- ============================================
-- SCHEMA: appointments_pe y appointments_cl
-- Descripción: Esquema de base de datos MySQL para agendamientos
-- País: PE (Perú) y CL (Chile)
-- ============================================

-- Usar la base de datos correspondiente
-- USE appointments_pe; -- Para Perú
-- USE appointments_cl; -- Para Chile

-- ============================================
-- Tabla: appointments
-- Descripción: Almacena los agendamientos procesados por país
-- ============================================

CREATE TABLE IF NOT EXISTS appointments (
  -- Identificadores
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID autoincremental único',
  appointment_id VARCHAR(50) UNIQUE NOT NULL COMMENT 'ID único del agendamiento (de DynamoDB)',
  
  -- Datos del agendamiento
  insured_id VARCHAR(5) NOT NULL COMMENT 'Código del asegurado (5 dígitos con ceros)',
  schedule_id INT NOT NULL COMMENT 'Identificador del espacio de agendamiento',
  country_iso VARCHAR(2) NOT NULL COMMENT 'Código ISO del país (PE o CL)',
  status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT 'Estado: pending, completed, failed, cancelled',
  
  -- Metadatos
  metadata JSON COMMENT 'Información adicional en formato JSON',
  
  -- Auditoría
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Fecha de última actualización',
  
  -- Índices para optimizar consultas
  INDEX idx_insured_id (insured_id) COMMENT 'Índice para búsquedas por asegurado',
  INDEX idx_appointment_id (appointment_id) COMMENT 'Índice para búsquedas por ID de agendamiento',
  INDEX idx_created_at (created_at) COMMENT 'Índice para ordenar por fecha',
  INDEX idx_status (status) COMMENT 'Índice para filtrar por estado',
  INDEX idx_country_iso (country_iso) COMMENT 'Índice para filtrar por país'
  
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Tabla de agendamientos de citas médicas';

-- ============================================
-- Tabla: schedules (Opcional - para referencia)
-- Descripción: Define los espacios de agendamiento disponibles
-- ============================================

CREATE TABLE IF NOT EXISTS schedules (
  schedule_id INT AUTO_INCREMENT PRIMARY KEY,
  center_id INT NOT NULL COMMENT 'ID del centro médico',
  specialty_id INT NOT NULL COMMENT 'ID de la especialidad',
  medic_id INT NOT NULL COMMENT 'ID del médico',
  appointment_date DATETIME NOT NULL COMMENT 'Fecha y hora del espacio',
  is_available BOOLEAN DEFAULT TRUE COMMENT 'Disponibilidad del espacio',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_center_specialty (center_id, specialty_id),
  INDEX idx_medic_date (medic_id, appointment_date),
  INDEX idx_availability (is_available, appointment_date)
  
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Espacios de agendamiento disponibles';

-- ============================================
-- Tabla: medical_centers (Opcional - para referencia)
-- ============================================

CREATE TABLE IF NOT EXISTS medical_centers (
  center_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address TEXT,
  city VARCHAR(100),
  country_iso VARCHAR(2) NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_country (country_iso)
  
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Centros médicos';

-- ============================================
-- Tabla: specialties (Opcional - para referencia)
-- ============================================

CREATE TABLE IF NOT EXISTS specialties (
  specialty_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Especialidades médicas';

-- ============================================
-- Tabla: medics (Opcional - para referencia)
-- ============================================

CREATE TABLE IF NOT EXISTS medics (
  medic_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  specialty_id INT NOT NULL,
  license_number VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id),
  INDEX idx_specialty (specialty_id)
  
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Médicos';

-- ============================================
-- Datos de ejemplo (para testing)
-- ============================================

-- Centros médicos
INSERT INTO medical_centers (name, address, city, country_iso, phone) VALUES
('Clínica San Felipe', 'Av. Gregorio Escobedo 650', 'Lima', 'PE', '+51-1-2345678'),
('Clínica Ricardo Palma', 'Av. Javier Prado Este 1066', 'Lima', 'PE', '+51-1-2234567'),
('Clínica Las Condes', 'Lo Fontecilla 441', 'Santiago', 'CL', '+56-2-22345678'),
('Clínica Alemana', 'Av. Vitacura 5951', 'Santiago', 'CL', '+56-2-22123456');

-- Especialidades
INSERT INTO specialties (name, description) VALUES
('Cardiología', 'Especialidad médica del corazón'),
('Dermatología', 'Especialidad de la piel'),
('Pediatría', 'Especialidad infantil'),
('Traumatología', 'Especialidad del sistema musculoesquelético');

-- Médicos
INSERT INTO medics (first_name, last_name, specialty_id, license_number) VALUES
('Juan', 'García', 1, 'CMP-12345'),
('María', 'López', 2, 'CMP-23456'),
('Carlos', 'Rodríguez', 3, 'CMP-34567'),
('Ana', 'Martínez', 4, 'CMP-45678');

-- Espacios de agendamiento
INSERT INTO schedules (center_id, specialty_id, medic_id, appointment_date, is_available) VALUES
(1, 1, 1, '2024-11-10 09:00:00', TRUE),
(1, 1, 1, '2024-11-10 10:00:00', TRUE),
(1, 2, 2, '2024-11-10 11:00:00', TRUE),
(2, 3, 3, '2024-11-11 14:00:00', TRUE),
(2, 4, 4, '2024-11-11 15:00:00', TRUE);

-- ============================================
-- Consultas útiles
-- ============================================

-- Ver todos los agendamientos de un asegurado
-- SELECT * FROM appointments WHERE insured_id = '12345' ORDER BY created_at DESC;

-- Ver agendamientos por estado
-- SELECT status, COUNT(*) as total FROM appointments GROUP BY status;

-- Ver agendamientos del día actual
-- SELECT * FROM appointments WHERE DATE(created_at) = CURDATE();

-- Ver espacios disponibles para una especialidad
-- SELECT s.*, m.first_name, m.last_name, c.name as center_name
-- FROM schedules s
-- JOIN medics m ON s.medic_id = m.medic_id
-- JOIN medical_centers c ON s.center_id = c.center_id
-- WHERE s.specialty_id = 1 AND s.is_available = TRUE AND s.appointment_date > NOW()
-- ORDER BY s.appointment_date;

