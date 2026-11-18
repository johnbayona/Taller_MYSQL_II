-- Taller 2 FlotaYa | Fase 3 - DML
USE flotaya;

INSERT INTO departments (name) VALUES
('Bogotá D.C.'),('Antioquia'),('Bolívar'),('Valle del Cauca'),('Santander'),('Quindío'),('Magdalena');
INSERT INTO cities (department_id,name) VALUES
(1,'Bogotá'),(2,'Medellín'),(2,'Rionegro'),(3,'Cartagena'),(4,'Cali'),(5,'Bucaramanga'),(6,'Armenia');
INSERT INTO branches (city_id,name,address,phone,is_airport) VALUES
(1,'FlotaYa Bogotá Calle 26','Avenida Calle 26 # 69-76','6017001001',FALSE),
(1,'FlotaYa Aeropuerto El Dorado','Avenida El Dorado # 103-09','6017001002',TRUE),
(2,'FlotaYa Medellín El Poblado','Carrera 43A # 7-50','6047001003',FALSE),
(3,'FlotaYa Aeropuerto José María Córdova','Vía Aeropuerto JMC km 1','6047001004',TRUE),
(4,'FlotaYa Cartagena Bocagrande','Carrera 2 # 8-120','6057001005',FALSE),
(5,'FlotaYa Cali Granada','Avenida 9N # 15-20','6027001006',FALSE);
INSERT INTO employees (branch_id,first_name,last_name,corporate_email,role,hired_on) VALUES
(1,'Mónica','Gaitán','monica.gaitan@flotaya.example.com','ADMINISTRADOR','2022-01-10'),
(1,'Gustavo','Pérez','gustavo.perez@flotaya.example.com','MECANICO','2021-04-05'),
(1,'Camila','Torres','camila.torres@flotaya.example.com','ASESOR','2023-02-01'),
(2,'Andrés','Vargas','andres.vargas@flotaya.example.com','ASESOR','2023-03-01'),
(3,'Natalia','López','natalia.lopez@flotaya.example.com','ASESOR','2022-07-01'),
(4,'Sergio','Díaz','sergio.diaz@flotaya.example.com','ASESOR','2023-08-01'),
(5,'Valentina','Ríos','valentina.rios@flotaya.example.com','ASESOR','2024-01-15'),
(6,'Felipe','Cruz','felipe.cruz@flotaya.example.com','ASESOR','2024-02-15'),
(1,'Laura','Méndez','laura.mendez@flotaya.example.com','INSPECTOR','2022-06-10'),
(4,'Diego','Pardo','diego.pardo@flotaya.example.com','INSPECTOR','2023-09-10');
INSERT INTO categories (name,minimum_age,deposit_amount) VALUES
('Económico',21,1500000),('Compacto',21,1500000),('SUV',23,2500000),
('Camioneta 4x4',25,3000000),('Van',25,3000000),('Lujo',30,5000000);
INSERT INTO seasons (name,season_type,starts_on,ends_on) VALUES
('Fin de año 2025','ALTA','2025-12-15','2026-01-15'),
('Baja de inicio de año','BAJA','2026-01-16','2026-03-28'),
('Semana Santa','ALTA','2026-03-29','2026-04-05'),
('Baja de abril a junio','BAJA','2026-04-06','2026-06-12'),
('Vacaciones de mitad de año','ALTA','2026-06-13','2026-07-19'),
('Baja de segundo semestre','BAJA','2026-07-20','2026-10-02'),
('Receso escolar de octubre','MEDIA','2026-10-03','2026-10-12'),
('Baja de noviembre','BAJA','2026-10-13','2026-11-30'),
('Temporada de novenas','MEDIA','2026-12-01','2026-12-14'),
('Fin de año 2026','ALTA','2026-12-15','2027-01-15');
INSERT INTO category_rates (category_id,season_type,daily_rate) VALUES
(1,'BAJA',120000),(1,'MEDIA',140000),(1,'ALTA',180000),
(2,'BAJA',150000),(2,'MEDIA',175000),(2,'ALTA',220000),
(3,'BAJA',230000),(3,'MEDIA',270000),(3,'ALTA',340000),
(4,'BAJA',300000),(4,'MEDIA',350000),(4,'ALTA',430000),
(5,'BAJA',320000),(5,'MEDIA',370000),(5,'ALTA',460000),
(6,'BAJA',450000),(6,'MEDIA',520000),(6,'ALTA',650000);
INSERT INTO brands (name) VALUES ('Renault'),('Kia'),('Chevrolet'),('Mazda'),('Toyota'),('Hyundai'),('Nissan');
INSERT INTO models (brand_id,category_id,name,transmission,fuel_type,seats) VALUES
(1,1,'Kwid','MECANICA','GASOLINA',5),(2,1,'Picanto','AUTOMATICA','GASOLINA',5),
(3,2,'Onix','AUTOMATICA','GASOLINA',5),(4,2,'Mazda 2','AUTOMATICA','GASOLINA',5),
(1,3,'Duster','MECANICA','GASOLINA',5),(2,3,'Sportage','AUTOMATICA','HIBRIDO',5),
(5,4,'Hilux','MECANICA','DIESEL',5),(6,5,'Staria','AUTOMATICA','DIESEL',11),
(4,3,'CX-30','AUTOMATICA','GASOLINA',5);
INSERT INTO vehicles (model_id,branch_id,plate,model_year,color,mileage_km,status) VALUES
(1,1,'KWD101',2024,'Blanco',18950,'DISPONIBLE'),
(1,2,'KWD102',2024,'Gris',22100,'DISPONIBLE'),
(1,6,'KWD103',2021,'Blanco',98400,'FUERA_DE_SERVICIO'),
(2,2,'PCN201',2025,'Rojo',10450,'DISPONIBLE'),
(2,3,'PCN202',2025,'Blanco',12400,'DISPONIBLE'),
(3,2,'ONX301',2024,'Plata',30500,'ALQUILADO'),
(3,5,'ONX302',2023,'Negro',41890,'MANTENIMIENTO'),
(4,4,'MZD401',2025,'Azul',9310,'DISPONIBLE'),
(4,4,'MZD402',2024,'Rojo',26300,'ALQUILADO'),
(5,1,'DST501',2023,'Blanco',48620,'DISPONIBLE'),
(5,6,'DST502',2024,'Gris',22710,'DISPONIBLE'),
(6,2,'SPT601',2025,'Negro',11500,'ALQUILADO'),
(6,4,'SPT602',2025,'Blanco',9600,'DISPONIBLE'),
(7,3,'HLX701',2023,'Plata',64380,'DISPONIBLE'),
(7,6,'HLX702',2022,'Blanco',88100,'MANTENIMIENTO'),
(8,2,'STR801',2024,'Gris',35700,'DISPONIBLE'),
(8,5,'STR802',2025,'Blanco',15480,'DISPONIBLE');
INSERT INTO maintenances (vehicle_id,maintenance_type,description,workshop_name,started_at,ended_at,cost) VALUES
(3,'CORRECTIVO','Diagnóstico de motor; pérdida total','Centro Motor Bogotá','2026-09-10','2026-09-15',320000),
(15,'CORRECTIVO','Cambio de embrague','Diésel del Valle','2026-11-16',NULL,NULL),
(7,'LATONERIA','Reparación de latonería','Latonería Caribe','2026-10-26',NULL,NULL),
(10,'PREVENTIVO','Cambio de aceite y filtros','Taller FlotaYa Bogotá','2026-09-02','2026-09-02',280000),
(10,'PREVENTIVO','Alineación y balanceo','Taller FlotaYa Bogotá','2026-10-01','2026-10-01',150000),
(14,'PREVENTIVO','Revisión de frenos','Taller Medellín','2026-08-10','2026-08-11',410000);
INSERT INTO customers (document_type,document_number,first_name,last_name,email,phone,birth_date,city_id,registered_on,status) VALUES
('CC','1001001001','Andrea','Salazar','andrea.salazar@example.com','3001110001','1990-04-12',1,'2025-01-10','ACTIVO'),
('CC','1001001002','Carlos','Mejía','carlos.mejia@example.com','3001110002','1985-09-30',2,'2025-02-10','ACTIVO'),
('CC','1001001003','Juliana','Patiño','juliana.patino@example.com','3001110003','2004-07-15',1,'2025-03-10','ACTIVO'),
('CE','1001001004','Lucas','Ferreira','lucas.ferreira@example.com','3001110004','1979-02-02',4,'2025-04-10','ACTIVO'),
('CC','1001001005','Diana','Rozo','diana.rozo@example.com','3001110005','1993-11-25',5,'2025-05-10','ACTIVO'),
('PASAPORTE','P1001006','Emma','Walker','emma.walker@example.com','3001110006','1988-06-18',4,'2025-06-10','ACTIVO'),
('CC','1001001007','Jorge','Arango','jorge.arango@example.com','3001110007','1975-01-09',2,'2025-07-10','ACTIVO'),
('CC','1001001008','Paola','Quintero','paola.quintero@example.com','3001110008','1999-12-03',1,'2025-08-10','ACTIVO'),
('CC','1001001009','Esteban','Rueda','esteban.rueda@example.com','3001110009','2002-05-21',6,'2025-09-10','ACTIVO'),
('CC','1001001010','Martha','Cifuentes','martha.cifuentes@example.com','3001110010','1968-03-14',1,'2025-10-10','BLOQUEADO'),
('CC','1001001011','Kevin','Morales','kevin.morales@example.com','3001110011','2005-10-02',5,'2025-11-10','ACTIVO'),
('CC','1001001012','Laura','Benítez','laura.benitez@example.com',NULL,'1996-08-08',2,'2025-12-10','ACTIVO'),
('CC','1001001013','Ricardo','Lozano','ricardo.lozano@example.com','3001110013','1982-12-24',1,'2026-01-10','ACTIVO'),
('CC','1001001014','Sofía','Herrera','sofia.herrera@example.com','3001110014','2001-01-30',3,'2026-02-10','ACTIVO');
INSERT INTO licenses (customer_id,license_number,license_category,issued_on,expires_on,issuing_country) VALUES
(1,'LIC-AND-001','B1','2023-05-10','2028-05-10','Colombia'),
(2,'LIC-CAR-001','B1','2022-02-20','2027-02-20','Colombia'),
(3,'LIC-JUL-001','B1','2022-08-01','2032-08-01','Colombia'),
(4,'LIC-LUC-001','B1','2020-01-01','2026-12-31','Brasil'),
(5,'LIC-DIA-001','B1','2024-01-01','2029-11-30','Colombia'),
(6,'LIC-EMM-001','B1','2021-06-01','2031-06-01','Canadá'),
(7,'LIC-JOR-OLD','C1','2000-01-15','2010-01-15','Colombia'),
(7,'LIC-JOR-NEW','C1','2010-01-15','2030-01-15','Colombia'),
(8,'LIC-PAO-001','B1','2016-12-10','2026-12-10','Colombia'),
(9,'LIC-EST-001','B1','2023-10-10','2026-08-01','Colombia'),
(10,'LIC-MAR-001','B1','2020-04-04','2028-04-04','Colombia'),
(11,'LIC-KEV-001','B1','2023-10-10','2033-10-10','Colombia'),
(13,'LIC-RIC-001','B1','2022-12-24','2027-12-24','Colombia'),
(14,'LIC-SOF-001','B1','2024-02-01','2029-02-01','Colombia');
INSERT INTO additional_drivers (document_number,full_name,birth_date,license_number,license_expires_on) VALUES
('AD-2001','Felipe Salazar','1988-03-03','ADLIC-2001','2029-03-03'),
('AD-2002','Mónica Arango','1977-07-07','ADLIC-2002','2028-07-07'),
('AD-2003','Tomás Ferreira','2006-03-03','ADLIC-2003','2030-03-03'),
('AD-2004','Natalia Rozo','1995-05-05','ADLIC-2004','2026-09-30');
INSERT INTO extras (name,daily_list_price) VALUES
('GPS',15000),('Silla de bebé',12000),('Seguro total',45000),
('Conductor adicional',20000),('Wi-Fi portátil',10000),('Portabicicletas',18000);

-- Reservas de referencia (IDs generados desde 501).
INSERT INTO reservations (customer_id,vehicle_id,pickup_branch_id,return_branch_id,pickup_date,return_date,quoted_amount,status) VALUES
(3,1,1,1,'2026-11-27','2026-12-02',620000,'CONFIRMADA'),
(5,16,2,2,'2026-12-18','2026-12-23',2300000,'CONFIRMADA'),
(11,5,3,3,'2026-12-10','2026-12-17',980000,'PENDIENTE'),
(14,13,4,4,'2026-12-05','2026-12-09',1080000,'PENDIENTE'),
(10,2,1,1,'2026-09-10','2026-09-12',240000,'CANCELADA'),
(9,2,1,1,'2026-09-20','2026-09-22',240000,'CANCELADA'),
(1,10,1,1,'2026-12-01','2026-12-03',460000,'PENDIENTE'),
(2,9,4,4,'2026-11-18','2026-11-25',0+1050000,'CONVERTIDA'),
(8,12,2,2,'2026-11-15','2026-11-22',1610000,'CONVERTIDA'),
(13,6,2,1,'2026-11-17','2026-11-21',600000,'CONVERTIDA'),
(4,17,5,5,'2026-10-01','2026-10-06',2300000,'CONVERTIDA'),
(7,14,3,3,'2026-10-15','2026-10-20',1500000,'CONVERTIDA'),
(6,7,5,5,'2026-10-20','2026-10-24',960000,'CONVERTIDA'),
(5,11,6,6,'2026-10-08','2026-10-12',920000,'CONVERTIDA');
-- Reserva adicional para completar el octavo contrato cerrado.
INSERT INTO reservations (customer_id,vehicle_id,pickup_branch_id,return_branch_id,pickup_date,return_date,quoted_amount,status) VALUES
(1,1,1,1,'2026-09-05','2026-09-08',360000,'CONVERTIDA');
UPDATE reservations SET reservation_number=id+500 WHERE reservation_number IS NULL;
-- Contratos: 3 abiertos y 5 cerrados; el vínculo reserva-contrato es único.
INSERT INTO contracts (reservation_id,employee_id,started_on,expected_return,actual_return,rental_amount,status) VALUES
(8,5,'2026-11-18','2026-11-25',NULL,1050000,'ABIERTO'),
(9,4,'2026-11-15','2026-11-22',NULL,1610000,'ABIERTO'),
(10,4,'2026-11-17','2026-11-21',NULL,600000,'ABIERTO'),
(11,6,'2026-10-01','2026-10-06','2026-10-06',2300000,'CERRADO'),
(12,5,'2026-10-15','2026-10-20','2026-10-20',1500000,'CERRADO'),
(13,6,'2026-10-20','2026-10-24','2026-10-24',960000,'CERRADO'),
(14,8,'2026-10-08','2026-10-12','2026-10-13',920000,'CERRADO'),
(15,3,'2026-09-05','2026-09-08','2026-09-08',360000,'CERRADO');
UPDATE contracts SET contract_number=id+9000 WHERE contract_number IS NULL;
-- Vincular conductor y extras a contratos.
INSERT INTO contract_additional_drivers (contract_id,additional_driver_id) VALUES
(2,1),(4,3),(5,4),(1,2);
INSERT INTO contract_extras (contract_id,extra_id,quantity,unit_daily_price) VALUES
(1,3,1,45000),(1,4,1,20000),(2,1,1,15000),(3,4,1,20000),(3,2,2,12000),
(4,1,1,15000);
-- Entregas para los contratos.
INSERT INTO deliveries (contract_id,delivered_at,mileage_km,fuel_pct,branch_id,employee_id) VALUES
(1,'2026-11-18 09:00:00',26300,100,4,10),(2,'2026-11-15 08:00:00',11500,100,2,9),
(3,'2026-11-17 10:00:00',30500,100,2,9),(4,'2026-10-01 09:00:00',15480,100,5,10),
(5,'2026-10-15 09:00:00',64380,100,3,9),(6,'2026-10-20 09:00:00',41890,100,5,10),
(7,'2026-10-08 09:00:00',22710,100,6,9),
(8,'2026-09-05 09:00:00',18000,100,1,9);
INSERT INTO returns (contract_id,returned_at,mileage_km,fuel_pct,branch_id,employee_id) VALUES
(4,'2026-10-06 10:00:00',16000,90,5,10),(5,'2026-10-20 10:00:00',65000,90,3,9),
(6,'2026-10-24 10:00:00',43000,80,5,10),(7,'2026-10-13 10:00:00',23500,70,6,9),
(8,'2026-09-08 10:00:00',18300,90,1,9);
INSERT INTO inspections (contract_id,stage,inspected_at,exterior_ok,interior_ok,notes,employee_id) VALUES
(1,'ENTREGA','2026-11-18 09:10:00',TRUE,TRUE,'Sin novedades',9),
(2,'ENTREGA','2026-11-15 08:10:00',TRUE,TRUE,'Sin novedades',9),
(3,'ENTREGA','2026-11-17 10:10:00',TRUE,TRUE,'Sin novedades',9),
(4,'ENTREGA','2026-10-01 09:10:00',FALSE,TRUE,'Rayón previo en bómper trasero',10),
(4,'DEVOLUCION','2026-10-06 10:10:00',TRUE,TRUE,'Sin novedades adicionales',10),
(5,'ENTREGA','2026-10-15 09:10:00',TRUE,TRUE,'Sin novedades',9),
(5,'DEVOLUCION','2026-10-20 10:10:00',FALSE,TRUE,'Rayón en puerta del conductor',9),
(6,'ENTREGA','2026-10-20 09:10:00',TRUE,TRUE,'Sin novedades',10),
(6,'DEVOLUCION','2026-10-24 10:10:00',FALSE,TRUE,'Golpe en puerta trasera derecha',10),
(7,'ENTREGA','2026-10-08 09:10:00',TRUE,TRUE,'Sin novedades',9),
(7,'DEVOLUCION','2026-10-13 10:10:00',TRUE,TRUE,'Sin novedades',9),
(8,'ENTREGA','2026-09-05 09:10:00',TRUE,TRUE,'Sin novedades',9),
(8,'DEVOLUCION','2026-09-08 10:10:00',TRUE,TRUE,'Sin novedades',9);
INSERT INTO damages (inspection_id,description,severity,repair_cost,charge_customer) VALUES
(4,'Rayón previo en el bómper trasero','LEVE',180000,FALSE),
(7,'Rayón en la puerta del conductor','LEVE',350000,TRUE),
(9,'Golpe en la puerta trasera derecha','GRAVE',2400000,TRUE);
INSERT INTO deposits (contract_id,amount,held_at,released_at,applied_amount,status) VALUES
(1,1500000,'2026-11-18 09:00:00',NULL,0,'RETENIDO'),
(2,2500000,'2026-11-15 08:00:00',NULL,0,'RETENIDO'),
(3,1500000,'2026-11-17 10:00:00',NULL,0,'RETENIDO'),
(4,3000000,'2026-10-01 09:00:00','2026-10-06 10:30:00',0,'LIBERADO'),
(5,3000000,'2026-10-15 09:00:00','2026-10-20 10:30:00',350000,'APLICADO'),
(6,1500000,'2026-10-20 09:00:00','2026-10-24 10:30:00',1500000,'APLICADO'),
(7,2500000,'2026-10-08 09:00:00','2026-10-13 10:30:00',0,'LIBERADO'),
(8,1500000,'2026-09-05 09:00:00','2026-09-08 10:30:00',0,'LIBERADO');
INSERT INTO payments (contract_id,concept,amount,payment_method,paid_at,card_last4,authorization_code) VALUES
(2,'ALQUILER',1610000,'TARJETA','2026-11-15 08:05:00','1122','AUT-PAO-01'),
(3,'ALQUILER',600000,'TARJETA','2026-11-17 10:05:00','3344','AUT-RIC-01'),
(4,'ALQUILER',1300000,'TRANSFERENCIA','2026-10-05 16:00:00',NULL,NULL),
(4,'ALQUILER',1000000,'TRANSFERENCIA','2026-10-06 10:20:00',NULL,NULL),
(5,'ALQUILER',1000000,'EFECTIVO','2026-10-19 15:00:00',NULL,NULL),
(5,'ALQUILER',500000,'EFECTIVO','2026-10-20 10:20:00',NULL,NULL),
(5,'DAÑOS',350000,'DEPOSITO','2026-10-20 10:30:00',NULL,NULL),
(6,'ALQUILER',960000,'TARJETA','2026-10-24 10:20:00','5566','AUT-EMM-01'),
(6,'DAÑOS',1500000,'DEPOSITO','2026-10-24 10:30:00',NULL,NULL),
(6,'EXTRAS',60000,'TARJETA','2026-10-24 10:25:00','7788','AUT-EMM-02'),
(7,'ALQUILER',920000,'TRANSFERENCIA','2026-10-13 10:20:00',NULL,NULL),
(8,'ALQUILER',360000,'EFECTIVO','2026-09-08 10:20:00',NULL,NULL);

-- Operaciones de día: apertura de Bucaramanga.
INSERT INTO branches (city_id,name,address,phone) VALUES
(6,'FlotaYa Bucaramanga Cabecera','Carrera 35 # 48-20','6077001007');
INSERT INTO employees (branch_id,first_name,last_name,corporate_email,role,hired_on)
VALUES (7,'Daniel','Rojas','daniel.rojas@flotaya.example.com','ASESOR','2026-11-20');
INSERT INTO vehicles (model_id,branch_id,plate,model_year,color,mileage_km)
VALUES (5,7,'DST503',2026,'Rojo',1200);

-- Ajustes de lista: tarifa ALTA de Lujo +5 % y GPS a 16.000.
UPDATE category_rates SET daily_rate = ROUND(daily_rate * 1.05,2)
WHERE category_id = 6 AND season_type = 'ALTA';
UPDATE extras SET daily_list_price = 16000 WHERE name = 'GPS';

-- Confirmación de reservas pendientes de diciembre.
UPDATE reservations SET status = 'CONFIRMADA'
WHERE status = 'PENDIENTE' AND pickup_date >= '2026-12-01';

-- Limpieza segura de catálogos sin dependencias.
DELETE FROM brands WHERE name = 'Nissan';
DELETE FROM extras WHERE name = 'Portabicicletas';
-- No se borra Económico: tiene modelos y tarifas vinculados.

-- Errores esperados: ejecutar individualmente y dejar comentados en la corrida completa.
-- ⚠️ ESPERADO: ERROR 1062 - placa duplicada.
-- INSERT INTO vehicles (model_id,branch_id,plate,model_year,color,mileage_km) VALUES (1,1,'KWD101',2026,'Negro',0);
-- ⚠️ ESPERADO: ERROR 3819 - CHECK de combustible o kilometraje.
-- INSERT INTO vehicles (model_id,branch_id,plate,model_year,color,mileage_km) VALUES (1,1,'BAD999',2026,'Negro',-5);
-- ⚠️ ESPERADO: ERROR 1265 - valor fuera del ENUM.
-- INSERT INTO payments (contract_id,concept,amount,payment_method,paid_at) VALUES (1,'ALQUILER',1000,'CHEQUE','2026-11-23 12:00:00');

-- Conteos rápidos para revisar el cargue.
SELECT 'vehicles' AS tabla, COUNT(*) AS registros FROM vehicles
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'reservations', COUNT(*) FROM reservations
UNION ALL SELECT 'contracts', COUNT(*) FROM contracts
UNION ALL SELECT 'payments', COUNT(*) FROM payments;
