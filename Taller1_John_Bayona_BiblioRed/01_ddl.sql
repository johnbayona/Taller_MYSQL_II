-- 01_ddl.sql
DROP DATABASE IF EXISTS bibliored;
CREATE DATABASE bibliored;
USE bibliored;

CREATE TABLE branches (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(100) NOT NULL UNIQUE,
 municipality VARCHAR(100) NOT NULL,
 address VARCHAR(150) NOT NULL,
 opened_on DATE NOT NULL
);

CREATE TABLE membership_types (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(50) NOT NULL UNIQUE,
 loan_limit INT NOT NULL CHECK (loan_limit > 0),
 loan_days INT NOT NULL CHECK (loan_days > 0),
 max_renewals INT NOT NULL CHECK (max_renewals >= 0),
 daily_fine DECIMAL(10,2) NOT NULL CHECK (daily_fine >= 0),
 annual_fee DECIMAL(12,2) NOT NULL CHECK (annual_fee >= 0)
);

CREATE TABLE categories (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE publishers (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(120) NOT NULL UNIQUE,
 city VARCHAR(100) NOT NULL
);

CREATE TABLE authors (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 full_name VARCHAR(150) NOT NULL,
 nationality VARCHAR(80) NOT NULL,
 birth_year INT NOT NULL CHECK (birth_year BETWEEN 1800 AND 2026)
);

CREATE TABLE employees (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 full_name VARCHAR(150) NOT NULL,
 email VARCHAR(120) NOT NULL UNIQUE,
 hired_on DATE NOT NULL,
 role ENUM('COORDINADOR','BIBLIOTECARIO','AUXILIAR') NOT NULL DEFAULT 'BIBLIOTECARIO',
 branch_id BIGINT NOT NULL,
 FOREIGN KEY (branch_id) REFERENCES branches(id)
);

CREATE TABLE titles (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 isbn VARCHAR(20) NOT NULL UNIQUE,
 title VARCHAR(180) NOT NULL,
 publication_year INT NOT NULL,
 category_id BIGINT NOT NULL,
 publisher_id BIGINT NOT NULL,
 replacement_cost DECIMAL(12,2) NOT NULL DEFAULT 50000.00 CHECK (replacement_cost > 0),
 FOREIGN KEY (category_id) REFERENCES categories(id),
 FOREIGN KEY (publisher_id) REFERENCES publishers(id)
);

CREATE TABLE title_authors (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 title_id BIGINT NOT NULL,
 author_id BIGINT NOT NULL,
 author_order INT NOT NULL CHECK (author_order > 0),
 UNIQUE (title_id, author_id),
 UNIQUE (title_id, author_order),
 FOREIGN KEY (title_id) REFERENCES titles(id),
 FOREIGN KEY (author_id) REFERENCES authors(id)
);

CREATE TABLE copies (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 barcode VARCHAR(40) NOT NULL UNIQUE,
 title_id BIGINT NOT NULL,
 branch_id BIGINT NOT NULL,
 acquired_on DATE NOT NULL,
 status ENUM('DISPONIBLE','PRESTADO','EN_REPARACION','PERDIDO','DADO_DE_BAJA') NOT NULL DEFAULT 'DISPONIBLE',
 FOREIGN KEY (title_id) REFERENCES titles(id),
 FOREIGN KEY (branch_id) REFERENCES branches(id)
);

CREATE TABLE members (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 document_number VARCHAR(30) NOT NULL UNIQUE,
 first_name VARCHAR(80) NOT NULL,
 last_name VARCHAR(80) NOT NULL,
 email VARCHAR(120) UNIQUE,
 phone VARCHAR(30),
 birth_date DATE NOT NULL,
 joined_on DATE NOT NULL,
 membership_type_id BIGINT NOT NULL,
 branch_id BIGINT NOT NULL,
 status ENUM('ACTIVO','SUSPENDIDO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
 FOREIGN KEY (membership_type_id) REFERENCES membership_types(id),
 FOREIGN KEY (branch_id) REFERENCES branches(id)
);

CREATE TABLE loans (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 member_id BIGINT NOT NULL,
 copy_id BIGINT NOT NULL,
 employee_id BIGINT NOT NULL,
 loan_date DATE NOT NULL,
 due_date DATE NOT NULL,
 return_date DATE NULL,
 status ENUM('ACTIVO','DEVUELTO','PERDIDO') NOT NULL DEFAULT 'ACTIVO',
 CHECK (due_date > loan_date),
 CHECK (return_date IS NULL OR return_date >= loan_date),
 FOREIGN KEY (member_id) REFERENCES members(id),
 FOREIGN KEY (copy_id) REFERENCES copies(id),
 FOREIGN KEY (employee_id) REFERENCES employees(id),
 INDEX idx_loans_member_status (member_id, status),
 INDEX idx_loans_copy_status (copy_id, status)
);

CREATE TABLE renewals (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 loan_id BIGINT NOT NULL,
 renewed_on DATE NOT NULL,
 previous_due_date DATE NOT NULL,
 new_due_date DATE NOT NULL,
 CHECK (new_due_date > previous_due_date),
 FOREIGN KEY (loan_id) REFERENCES loans(id)
);

CREATE TABLE reservations (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 member_id BIGINT NOT NULL,
 title_id BIGINT NOT NULL,
 pickup_branch_id BIGINT NOT NULL,
 reserved_on DATE NOT NULL,
 expires_on DATE NOT NULL,
 status ENUM('PENDIENTE','ATENDIDA','CANCELADA','VENCIDA') NOT NULL DEFAULT 'PENDIENTE',
 CHECK (expires_on >= reserved_on),
 FOREIGN KEY (member_id) REFERENCES members(id),
 FOREIGN KEY (title_id) REFERENCES titles(id),
 FOREIGN KEY (pickup_branch_id) REFERENCES branches(id)
);

CREATE TABLE fines (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 loan_id BIGINT NOT NULL,
 reason ENUM('MORA','DAÑO','PERDIDA') NOT NULL,
 status ENUM('PENDIENTE','PAGADA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
 late_days INT NOT NULL DEFAULT 0 CHECK (late_days >= 0),
 amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
 generated_on DATE NOT NULL,
 FOREIGN KEY (loan_id) REFERENCES loans(id)
);

CREATE TABLE fine_payments (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 fine_id BIGINT NOT NULL,
 amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
 paid_on DATE NOT NULL,
 payment_method ENUM('EFECTIVO','TARJETA','TRANSFERENCIA') NOT NULL,
 FOREIGN KEY (fine_id) REFERENCES fines(id)
);

-- Los préstamos empiezan en 1001.
ALTER TABLE loans AUTO_INCREMENT = 1001;

SHOW TABLES;
DESCRIBE loans;
