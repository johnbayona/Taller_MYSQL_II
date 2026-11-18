-- Taller 2 FlotaYa | Fase 5 - Funciones, procedimientos y seguridad
USE flotaya;
DELIMITER $$

DROP FUNCTION IF EXISTS fn_edad_conductor$$
CREATE FUNCTION fn_edad_conductor(p_birth DATE,p_reference DATE)
RETURNS INT DETERMINISTIC NO SQL
BEGIN
 RETURN TIMESTAMPDIFF(YEAR,p_birth,p_reference);
END$$

DROP FUNCTION IF EXISTS fn_licencia_vigente$$
CREATE FUNCTION fn_licencia_vigente(p_customer BIGINT,p_reference DATE)
RETURNS BOOLEAN NOT DETERMINISTIC READS SQL DATA
BEGIN
 DECLARE v_count INT DEFAULT 0;
 SELECT COUNT(*) INTO v_count FROM licenses
 WHERE customer_id=p_customer AND issued_on<=p_reference AND expires_on>=p_reference;
 RETURN v_count>0;
END$$

DROP FUNCTION IF EXISTS fn_valor_alquiler$$
CREATE FUNCTION fn_valor_alquiler(p_category BIGINT,p_start DATE,p_end DATE)
RETURNS DECIMAL(12,2) NOT DETERMINISTIC READS SQL DATA
BEGIN
 DECLARE v_day DATE;
 DECLARE v_total DECIMAL(12,2) DEFAULT 0;
 DECLARE v_rate DECIMAL(12,2);
 DECLARE v_type VARCHAR(10);
 IF p_end<=p_start THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La fecha final debe ser posterior a la inicial';
 END IF;
 SET v_day=p_start;
 WHILE v_day<p_end DO
  SET v_rate=NULL;
  SELECT s.season_type INTO v_type FROM seasons s
  WHERE v_day BETWEEN s.starts_on AND s.ends_on LIMIT 1;
  SELECT cr.daily_rate INTO v_rate FROM category_rates cr
  WHERE cr.category_id=p_category AND cr.season_type=v_type LIMIT 1;
  IF v_rate IS NULL THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No hay temporada o tarifa para el día solicitado';
  END IF;
  SET v_total=v_total+v_rate;
  SET v_day=DATE_ADD(v_day,INTERVAL 1 DAY);
 END WHILE;
 RETURN v_total;
END$$

DROP PROCEDURE IF EXISTS sp_crear_reserva$$
CREATE PROCEDURE sp_crear_reserva(
 IN p_customer BIGINT,IN p_vehicle BIGINT,IN p_pickup_branch BIGINT,
 IN p_return_branch BIGINT,IN p_start DATE,IN p_end DATE,OUT p_reservation_number BIGINT
)
SQL SECURITY DEFINER
BEGIN
 DECLARE v_status VARCHAR(20);
 DECLARE v_birth DATE;
 DECLARE v_min_age INT;
 DECLARE v_category BIGINT;
 DECLARE v_age INT;
 DECLARE v_reservation_id BIGINT;
 DECLARE v_quote DECIMAL(12,2);
 IF NOT EXISTS(SELECT 1 FROM customers WHERE id=p_customer) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El cliente no existe';
 END IF;
 SELECT status,birth_date INTO v_status,v_birth FROM customers WHERE id=p_customer;
 IF v_status='BLOQUEADO' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El cliente está bloqueado';
 END IF;
 IF p_end<=p_start THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La devolución debe ser posterior a la recogida';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM vehicles WHERE id=p_vehicle) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El vehículo no existe';
 END IF;
 IF (SELECT status FROM vehicles WHERE id=p_vehicle)='FUERA_DE_SERVICIO' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El vehículo está fuera de servicio';
 END IF;
 IF EXISTS(SELECT 1 FROM reservations r WHERE r.vehicle_id=p_vehicle
  AND r.status IN ('PENDIENTE','CONFIRMADA','CONVERTIDA')
  AND r.pickup_date<=p_end AND r.return_date>=p_start) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El vehículo ya está reservado en esas fechas';
 END IF;
 SELECT m.category_id,c.minimum_age INTO v_category,v_min_age
 FROM vehicles v JOIN models m ON m.id=v.model_id JOIN categories c ON c.id=m.category_id
 WHERE v.id=p_vehicle;
 SET v_age=fn_edad_conductor(v_birth,p_start);
 IF v_age<v_min_age THEN
  SET @msg=CONCAT('El cliente tiene ',v_age,' años y la categoría exige ',v_min_age);
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=@msg;
 END IF;
 IF fn_licencia_vigente(p_customer,p_end)=FALSE THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El cliente no tiene licencia vigente durante todo el alquiler';
 END IF;
 SET v_quote=fn_valor_alquiler(v_category,p_start,p_end);
 INSERT INTO reservations(customer_id,vehicle_id,pickup_branch_id,return_branch_id,pickup_date,return_date,quoted_amount,status)
 VALUES(p_customer,p_vehicle,p_pickup_branch,p_return_branch,p_start,p_end,v_quote,'PENDIENTE');
 SET v_reservation_id=LAST_INSERT_ID();
 SELECT reservation_number INTO p_reservation_number FROM reservations WHERE id=v_reservation_id;
END$$

DROP PROCEDURE IF EXISTS sp_cerrar_contrato$$
CREATE PROCEDURE sp_cerrar_contrato(IN p_contract BIGINT,IN p_close_date DATE,OUT p_balance DECIMAL(12,2))
SQL SECURITY DEFINER
BEGIN
 DECLARE v_status VARCHAR(20);
 DECLARE v_start DATE;
 DECLARE v_expected DATE;
 DECLARE v_reservation BIGINT;
 DECLARE v_vehicle BIGINT;
 DECLARE v_category BIGINT;
 DECLARE v_return_branch BIGINT;
 DECLARE v_rental DECIMAL(12,2);
 DECLARE v_extras DECIMAL(12,2) DEFAULT 0;
 DECLARE v_damages DECIMAL(12,2) DEFAULT 0;
 DECLARE v_paid DECIMAL(12,2) DEFAULT 0;
 DECLARE v_deposit DECIMAL(12,2) DEFAULT 0;
 DECLARE v_apply DECIMAL(12,2) DEFAULT 0;
 IF NOT EXISTS(SELECT 1 FROM contracts WHERE id=p_contract) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El contrato no existe';
 END IF;
 SELECT status,started_on,expected_return,reservation_id INTO v_status,v_start,v_expected,v_reservation
 FROM contracts WHERE id=p_contract;
 IF v_status<>'ABIERTO' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El contrato no está abierto'; END IF;
 IF NOT EXISTS(SELECT 1 FROM returns WHERE contract_id=p_contract) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El contrato no tiene devolución registrada';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM inspections WHERE contract_id=p_contract AND stage='DEVOLUCION') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Falta la inspección de devolución';
 END IF;
 IF p_close_date<=v_start THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La fecha de cierre debe ser posterior al inicio'; END IF;
 SELECT r.vehicle_id,r.return_branch_id,m.category_id INTO v_vehicle,v_return_branch,v_category
 FROM reservations r JOIN vehicles v ON v.id=r.vehicle_id JOIN models m ON m.id=v.model_id
 WHERE r.id=v_reservation;
 SET v_rental=fn_valor_alquiler(v_category,v_start,p_close_date);
 SELECT COALESCE(SUM(ce.quantity*ce.unit_daily_price*DATEDIFF(p_close_date,v_start)),0)
 INTO v_extras FROM contract_extras ce WHERE ce.contract_id=p_contract;
 SELECT COALESCE(SUM(d.repair_cost),0) INTO v_damages
 FROM damages d JOIN inspections i ON i.id=d.inspection_id
 WHERE i.contract_id=p_contract AND i.stage='DEVOLUCION' AND d.charge_customer=TRUE;
 SELECT amount INTO v_deposit FROM deposits WHERE contract_id=p_contract;
 SET v_apply=LEAST(v_damages,v_deposit);
 UPDATE deposits SET applied_amount=v_apply,
 status=IF(v_apply>0,'APLICADO','LIBERADO'),released_at=NOW()
 WHERE contract_id=p_contract;
 IF v_apply>0 THEN
  INSERT INTO payments(contract_id,concept,amount,payment_method,paid_at)
  VALUES(p_contract,'DAÑOS',v_apply,'DEPOSITO',NOW());
 END IF;
 SELECT COALESCE(SUM(amount),0) INTO v_paid FROM payments WHERE contract_id=p_contract;
 UPDATE contracts SET actual_return=p_close_date,rental_amount=v_rental,status='CERRADO' WHERE id=p_contract;
 UPDATE vehicles SET status='DISPONIBLE',branch_id=v_return_branch,
 mileage_km=(SELECT mileage_km FROM returns WHERE contract_id=p_contract)
 WHERE id=v_vehicle;
 SET p_balance=v_rental+v_extras+v_damages-v_paid;
END$$

DELIMITER ;

-- Pruebas de funciones.
SELECT fn_edad_conductor('2004-07-15','2026-07-14') AS edad_antes,
       fn_edad_conductor('2004-07-15','2026-07-15') AS edad_cumplida;
SELECT fn_valor_alquiler(1,'2026-11-27','2026-12-02') AS valor_economico;
SELECT fn_licencia_vigente(7,'2026-11-23') AS licencia_jorge_vigente;

-- Ejemplo de creación de reserva; se deja comentado para no alterar los datos semilla.
-- SET @nueva_reserva = NULL;
-- CALL sp_crear_reserva(7,14,3,3,'2026-12-19','2026-12-22',@nueva_reserva);
-- SELECT @nueva_reserva;

-- Roles y usuarios: ejecutar con una cuenta administradora de MySQL.
DROP ROLE IF EXISTS rol_asesor_flotaya;
DROP ROLE IF EXISTS rol_taller_flotaya;
DROP ROLE IF EXISTS rol_auditor_flotaya;
CREATE ROLE rol_asesor_flotaya,rol_taller_flotaya,rol_auditor_flotaya;

GRANT SELECT ON flotaya.reservations TO rol_asesor_flotaya;
GRANT SELECT ON flotaya.customers TO rol_asesor_flotaya;
GRANT SELECT ON flotaya.vehicles TO rol_asesor_flotaya;
GRANT EXECUTE ON PROCEDURE flotaya.sp_crear_reserva TO rol_asesor_flotaya;
GRANT EXECUTE ON FUNCTION flotaya.fn_valor_alquiler TO rol_asesor_flotaya;
GRANT UPDATE(status) ON flotaya.reservations TO rol_asesor_flotaya;

GRANT SELECT ON flotaya.maintenances TO rol_taller_flotaya;
GRANT INSERT,UPDATE ON flotaya.maintenances TO rol_taller_flotaya;
GRANT SELECT(id,plate,status,mileage_km,branch_id) ON flotaya.vehicles TO rol_taller_flotaya;
GRANT UPDATE(status) ON flotaya.vehicles TO rol_taller_flotaya;

GRANT SELECT ON flotaya.contracts TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.reservations TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.vehicles TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.maintenances TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.returns TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.inspections TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.damages TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.deposits TO rol_auditor_flotaya;
GRANT SELECT(id,contract_id,concept,amount,paid_at) ON flotaya.payments TO rol_auditor_flotaya;

CREATE USER IF NOT EXISTS 'asesor_flotaya'@'localhost' IDENTIFIED BY 'Practica_2026*';
CREATE USER IF NOT EXISTS 'taller_flotaya'@'localhost' IDENTIFIED BY 'Practica_2026*';
CREATE USER IF NOT EXISTS 'auditor_flotaya'@'localhost' IDENTIFIED BY 'Practica_2026*';
GRANT rol_asesor_flotaya TO 'asesor_flotaya'@'localhost';
GRANT rol_taller_flotaya TO 'taller_flotaya'@'localhost';
GRANT rol_auditor_flotaya TO 'auditor_flotaya'@'localhost';
SET DEFAULT ROLE rol_asesor_flotaya TO 'asesor_flotaya'@'localhost';
SET DEFAULT ROLE rol_taller_flotaya TO 'taller_flotaya'@'localhost';
SET DEFAULT ROLE rol_auditor_flotaya TO 'auditor_flotaya'@'localhost';

-- Revisar identidad y privilegios:
-- SELECT CURRENT_USER(), CURRENT_ROLE();
-- SHOW GRANTS;
