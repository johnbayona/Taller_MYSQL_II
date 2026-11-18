-- 02_dml.sql
USE bibliored;

INSERT INTO branches (name,municipality,address,opened_on) VALUES
('Sede Central Chía','Chía','Carrera 10 # 8-20','2012-01-01'),
('Sede Cajicá','Cajicá','Calle 5 # 4-18','2015-01-01'),
('Sede Zipaquirá','Zipaquirá','Carrera 8 # 6-30','2017-01-01'),
('Sede Cota','Cota','Calle 4 # 3-15','2020-01-01'),
('Sede Tabio','Tabio','Carrera 3 # 2-11','2026-10-01');

INSERT INTO membership_types (name,loan_limit,loan_days,max_renewals,daily_fine,annual_fee) VALUES
('Básica',2,14,1,500,0),
('Estudiante',3,14,2,300,0),
('Docente',5,21,2,300,30000),
('Infantil',2,7,1,200,0),
('Institucional',10,30,3,1000,250000);

INSERT INTO categories (name) VALUES
('Novela'),('Cuento'),('Poesía'),('Historia'),('Ciencia'),('Infantil'),('Referencia'),('Cómic');

INSERT INTO publishers (name,city) VALUES
('Ediciones Horizonte','Bogotá'),('Letras del Valle','Cali'),('Editorial Andina','Medellín'),
('Papel y Tinta','Tunja'),('Aula Abierta','Bogotá'),('Universo Lector','Bucaramanga');

INSERT INTO authors (full_name,nationality,birth_year) VALUES
('Gabriela Ríos','Colombiana',1978),('Mateo Salcedo','Colombiano',1982),
('Lucía Herrera','Colombiana',1975),('Tomás Cárdenas','Colombiano',1969),
('Elena Pardo','Colombiana',1988),('Samuel Ortega','Mexicano',1972),
('Nora Castillo','Colombiana',1990),('Diego Beltrán','Peruano',1980),
('Amalia Torres','Colombiana',1965),('Julián Vega','Colombiano',1985);

INSERT INTO employees (full_name,email,hired_on,role,branch_id) VALUES
('Patricia Lemus','patricia.lemus@bibliored.test','2012-02-01','COORDINADOR',1),
('Camilo Duarte','camilo.duarte@bibliored.test','2016-03-15','BIBLIOTECARIO',2),
('Mariana Gil','mariana.gil@bibliored.test','2018-06-01','BIBLIOTECARIO',3),
('Andrés Rojas','andres.rojas@bibliored.test','2020-02-10','BIBLIOTECARIO',4),
('Sofía Niño','sofia.nino@bibliored.test','2026-10-02','AUXILIAR',5),
('Felipe Mora','felipe.mora@bibliored.test','2019-07-01','AUXILIAR',1);

INSERT INTO titles (isbn,title,publication_year,category_id,publisher_id,replacement_cost) VALUES
('9780000000001','Cuentos de la Sabana',2018,2,1,45000),
('9780000000002','El río de las garzas',2016,1,2,52000),
('9780000000003','Cartas desde el páramo',2012,3,3,38000),
('9780000000004','Diccionario escolar ilustrado',2017,7,4,75000),
('9780000000005','El dragón de Guatavita',2020,6,5,42000),
('9780000000006','La ciudad de los faroles',2021,1,1,56000),
('9780000000007','Memorias del altiplano',2014,4,3,61000),
('9780000000008','Pequeños científicos',2022,5,5,68000),
('9780000000009','Átomos para curiosos',2023,5,6,68000),
('9780000000010','Versos para la lluvia',2019,3,2,35000),
('9780000000011','La casa de los mapas',2015,1,4,59000),
('9780000000012','Historias del viento',2011,2,1,48000),
('9780000000013','Guía de aves andinas',2020,7,6,82000),
('9780000000014','El jardín de los secretos',2024,6,5,50000);

-- Un título con dos autores y tres obras coescritas en total.
INSERT INTO title_authors (title_id,author_id,author_order) VALUES
(1,1,1),(1,2,2),(2,3,1),(3,4,1),(4,5,1),(5,6,1),
(6,7,1),(7,8,1),(8,9,1),(9,9,1),(9,10,2),
(10,1,1),(11,2,1),(12,3,1),(13,4,1),(14,5,1);

INSERT INTO copies (barcode,title_id,branch_id,acquired_on,status) VALUES
('CH-001',2,1,'2016-02-10','DISPONIBLE'),
('CH-002',1,1,'2018-04-01','DISPONIBLE'),
('CH-003',3,1,'2012-04-01','DISPONIBLE'),
('CH-004',6,1,'2021-09-15','DISPONIBLE'),
('CH-005',1,1,'2018-10-05','DISPONIBLE'),
('CH-006',5,1,'2020-12-01','DISPONIBLE'),
('CA-001',2,2,'2017-01-10','DISPONIBLE'),
('CA-002',3,2,'2018-02-12','DISPONIBLE'),
('CA-003',4,2,'2019-03-13','DISPONIBLE'),
('CA-004',6,2,'2021-04-14','DISPONIBLE'),
('CA-005',7,2,'2022-05-15','DISPONIBLE'),
('ZP-001',12,3,'2011-01-15','DISPONIBLE'),
('ZP-002',8,3,'2022-03-10','DISPONIBLE'),
('ZP-003',10,3,'2020-04-11','DISPONIBLE'),
('ZP-004',13,3,'2021-05-12','DISPONIBLE'),
('CT-001',9,4,'2023-01-10','PERDIDO'),
('CT-002',11,4,'2016-02-10','DISPONIBLE'),
('CT-003',14,4,'2024-03-10','DISPONIBLE'),
('CT-004',1,4,'2019-04-10','DISPONIBLE'),
('TB-001',2,1,'2017-07-07','DISPONIBLE'),
('TB-002',5,1,'2020-08-08','DISPONIBLE'),
('TB-003',6,2,'2021-09-09','DISPONIBLE'),
('TB-004',7,2,'2022-10-10','DISPONIBLE'),
('TB-005',8,3,'2023-11-11','DISPONIBLE'),
('TB-006',10,4,'2024-12-12','DISPONIBLE');

INSERT INTO members
(document_number,first_name,last_name,email,phone,birth_date,joined_on,membership_type_id,branch_id,status) VALUES
('10010001','Andrés','Peña','andres.pena@test.co','3001110001','1985-02-10','2024-01-10',1,1,'ACTIVO'),
('10010002','Mariana','López','mariana.lopez@test.co','3001110002','1998-05-12','2024-02-12',2,2,'ACTIVO'),
('10010003','Laura','Gómez','laura.gomez@test.co','3001110003','1990-03-15','2024-03-15',3,1,'ACTIVO'),
('10010004','Santiago','Méndez','santiago.mendez@test.co','3001110004','1988-07-20','2024-04-20',1,2,'ACTIVO'),
('10010005','Isabela','Torres','isabela.torres@test.co','3001110005','2001-09-01','2024-05-01',2,3,'ACTIVO'),
('10010006','Juan Pablo','Herrera','juan.herrera@test.co','3001110006','1982-11-11','2024-06-11',3,2,'ACTIVO'),
('10010007','Felipe','Ramírez','felipe.ramirez@test.co','3001110007','1995-12-12','2024-07-12',1,4,'ACTIVO'),
('10010008','Felipe','Ramírez','felipe.ramirez2@test.co','3001110008','1995-12-12','2024-07-13',1,4,'ACTIVO'),
('10010009','Nicolás','Vargas',NULL,NULL,'2015-04-01','2025-01-10',4,1,'ACTIVO'),
('10010010','Valentina','Cruz',NULL,NULL,'2016-06-05','2025-02-10',4,3,'ACTIVO'),
('10010011','Daniela','Pérez','daniela.perez@test.co',NULL,'1999-01-01','2025-03-10',2,1,'SUSPENDIDO'),
('10010012','Óscar','León','oscar.leon@test.co','3001110012','1979-02-02','2025-04-10',3,4,'INACTIVO'),
('10010013','Paula','Soto','paula.soto@test.co','3001110013','2000-03-03','2026-10-05',1,5,'ACTIVO'),
('10010014','Martín','Reyes','martin.reyes@test.co','3001110014','1997-04-04','2026-10-06',1,1,'ACTIVO');

-- Préstamos con numeración desde 1001. Se insertan primero los registros históricos.
INSERT INTO loans (member_id,copy_id,employee_id,loan_date,due_date,return_date,status) VALUES
(1,1,1,'2026-09-01','2026-09-15','2026-09-14','DEVUELTO'),
(2,7,2,'2026-09-05','2026-09-19','2026-09-25','DEVUELTO'),
(3,2,1,'2026-09-10','2026-10-01',NULL,'ACTIVO'),
(4,8,2,'2026-10-01','2026-10-15',NULL,'ACTIVO'),
(2,9,2,'2026-10-02','2026-10-16',NULL,'ACTIVO'),
(5,12,3,'2026-10-03','2026-10-17','2026-10-16','DEVUELTO'),
(6,13,3,'2026-10-04','2026-10-25','2026-10-28','DEVUELTO'),
(7,17,4,'2026-10-05','2026-10-19',NULL,'ACTIVO'),
(8,18,4,'2026-10-06','2026-10-20','2026-10-20','DEVUELTO'),
(1,19,1,'2026-10-07','2026-10-21','2026-10-21','DEVUELTO'),
(4,10,2,'2026-10-08','2026-10-22',NULL,'ACTIVO'),
(5,14,3,'2026-10-09','2026-10-23','2026-10-22','DEVUELTO'),
(6,15,3,'2026-10-10','2026-10-31','2026-11-02','DEVUELTO'),
(7,16,4,'2026-10-11','2026-10-25',NULL,'PERDIDO'),
(10,20,1,'2026-10-12','2026-10-19','2026-10-19','DEVUELTO'),
(11,21,1,'2026-10-13','2026-10-27',NULL,'ACTIVO'),
(12,22,2,'2026-10-14','2026-10-28','2026-10-27','DEVUELTO'),
(1,23,2,'2026-10-15','2026-10-29',NULL,'ACTIVO'),
(2,24,3,'2026-10-16','2026-10-30',NULL,'ACTIVO'),
(3,25,4,'2026-10-17','2026-10-31',NULL,'ACTIVO');

-- Ajuste: los dos préstamos de Cajicá que vencen el 10 de noviembre exacto no se consideran vencidos al corte.
-- Los préstamos 1004 y 1005 son los dos vencidos de Cajicá.
UPDATE copies SET status='PRESTADO' WHERE id IN (2,8,9,17,10,21,23,24,25);
UPDATE copies SET status='PERDIDO' WHERE id=16;

INSERT INTO renewals (loan_id,renewed_on,previous_due_date,new_due_date) VALUES
(1003,'2026-09-25','2026-10-01','2026-10-22'),
(1003,'2026-10-15','2026-10-22','2026-11-12'),
(1008,'2026-10-15','2026-10-19','2026-11-02');

INSERT INTO reservations (member_id,title_id,pickup_branch_id,reserved_on,expires_on,status) VALUES
(9,1,1,'2026-11-01','2026-11-15','PENDIENTE'),
(10,2,3,'2026-11-02','2026-11-20','PENDIENTE'),
(13,3,5,'2026-11-03','2026-11-09','PENDIENTE'),
(14,4,1,'2026-11-04','2026-11-18','CANCELADA'),
(5,5,2,'2026-11-05','2026-11-19','ATENDIDA'),
(6,6,2,'2026-11-06','2026-11-10','VENCIDA');

INSERT INTO fines (loan_id,reason,status,late_days,amount,generated_on) VALUES
(1002,'MORA','PAGADA',6,1800,'2026-09-25'),
(1007,'MORA','PAGADA',3,900,'2026-10-28'),
(1013,'MORA','PENDIENTE',2,600,'2026-11-02'),
(1014,'PERDIDA','PENDIENTE',0,68000,'2026-10-25'),
(1008,'DAÑO','ANULADA',0,2500,'2026-10-20');

INSERT INTO fine_payments (fine_id,amount,paid_on,payment_method) VALUES
(1,1800,'2026-09-25','EFECTIVO'),
(2,400,'2026-10-28','TARJETA'),
(2,500,'2026-10-30','TRANSFERENCIA'),
(3,200,'2026-11-05','EFECTIVO');

-- Un abono parcial deja saldo pendiente en la multa 3.
-- Ejemplos controlados de UPDATE/DELETE: verificar antes y después.
SELECT * FROM copies WHERE id = 3;
UPDATE copies SET status='EN_REPARACION' WHERE id=3;
SELECT * FROM copies WHERE id = 3;

SELECT * FROM reservations WHERE id=3;
UPDATE reservations SET status='VENCIDA' WHERE id=3;
SELECT * FROM reservations WHERE id=3;

SELECT * FROM membership_types WHERE id=3;
UPDATE membership_types SET annual_fee = annual_fee * 1.10 WHERE id=3;
SELECT * FROM membership_types WHERE id=3;

SELECT * FROM members WHERE id=14;
UPDATE members SET phone='3005551414' WHERE id=14;
SELECT * FROM members WHERE id=14;

SELECT * FROM reservations WHERE id=4;
DELETE FROM reservations WHERE id=4;
SELECT * FROM reservations WHERE id=4;

SELECT * FROM publishers WHERE id=6;
SELECT * FROM titles WHERE publisher_id=6;
-- Solo eliminar si la editorial no tiene títulos asociados.
DELETE FROM publishers WHERE id=6 AND NOT EXISTS
 (SELECT 1 FROM titles WHERE publisher_id=6);

-- Tres errores esperados: ejecutar cada sentencia por separado.
-- ⚠️ ESPERADO: error por código de barras duplicado.
-- INSERT INTO copies (barcode,title_id,branch_id,acquired_on) VALUES ('CH-001',1,1,'2026-11-10');
-- ⚠️ ESPERADO: error por CHECK amount > 0.
-- INSERT INTO fine_payments (fine_id,amount,paid_on,payment_method) VALUES (3,0,'2026-11-10','EFECTIVO');
-- ⚠️ ESPERADO: error por valor ENUM no permitido.
-- UPDATE copies SET status='EXTRAVIADO' WHERE id=1;

SELECT 'branches' tabla, COUNT(*) total FROM branches
UNION ALL SELECT 'members',COUNT(*) FROM members
UNION ALL SELECT 'titles',COUNT(*) FROM titles
UNION ALL SELECT 'copies',COUNT(*) FROM copies
UNION ALL SELECT 'loans',COUNT(*) FROM loans
UNION ALL SELECT 'fines',COUNT(*) FROM fines;

-- Comprobación de ejemplares PRESTADO y préstamos ACTIVO.
SELECT c.id,c.barcode
FROM copies c
LEFT JOIN loans l ON l.copy_id=c.id AND l.status='ACTIVO'
WHERE c.status='PRESTADO' AND l.id IS NULL;
