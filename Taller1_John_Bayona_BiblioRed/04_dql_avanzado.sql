-- 04_dql_avanzado.sql
USE bibliored;

DROP PROCEDURE IF EXISTS sp_resumen_socio;
DELIMITER $$
CREATE PROCEDURE sp_resumen_socio(IN p_member_id BIGINT)
BEGIN
 DECLARE v_exists INT;
 SELECT COUNT(*) INTO v_exists FROM members WHERE id=p_member_id;
 IF v_exists=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El socio no existe';
 END IF;
 SELECT
  (SELECT COUNT(*) FROM loans WHERE member_id=p_member_id AND status='ACTIVO') prestamos_activos,
  COALESCE((
   SELECT SUM(f.amount-COALESCE(x.paid,0))
   FROM fines f
   JOIN loans l ON l.id=f.loan_id
   LEFT JOIN (SELECT fine_id,SUM(amount) paid FROM fine_payments GROUP BY fine_id) x ON x.fine_id=f.id
   WHERE l.member_id=p_member_id AND f.status='PENDIENTE'
  ),0) deuda_pendiente;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_prestar_ejemplar;
DELIMITER $$
CREATE PROCEDURE sp_prestar_ejemplar(
 IN p_copy_id BIGINT, IN p_member_id BIGINT,
 IN p_employee_id BIGINT, IN p_loan_date DATE
)
BEGIN
 DECLARE v_member_exists INT;
 DECLARE v_member_status VARCHAR(20);
 DECLARE v_copy_exists INT;
 DECLARE v_copy_status VARCHAR(20);
 DECLARE v_type_id BIGINT;
 DECLARE v_limit INT;
 DECLARE v_days INT;
 DECLARE v_active INT;
 DECLARE v_fines INT;
 DECLARE v_due DATE;

 SELECT COUNT(*),MAX(status),MAX(membership_type_id)
 INTO v_member_exists,v_member_status,v_type_id
 FROM members WHERE id=p_member_id;
 IF v_member_exists=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El socio no existe'; END IF;
 IF v_member_status<>'ACTIVO' THEN
  SET @msg=CONCAT('El socio no está activo: ',v_member_status);
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=@msg;
 END IF;

 SELECT COUNT(*),MAX(status) INTO v_copy_exists,v_copy_status
 FROM copies WHERE id=p_copy_id;
 IF v_copy_exists=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El ejemplar no existe'; END IF;
 IF v_copy_status<>'DISPONIBLE' THEN
  SET @msg=CONCAT('El ejemplar no está disponible: ',v_copy_status);
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=@msg;
 END IF;

 SELECT COUNT(*) INTO v_fines
 FROM fines f JOIN loans l ON l.id=f.loan_id
 WHERE l.member_id=p_member_id AND f.status='PENDIENTE';
 IF v_fines>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El socio tiene multas pendientes'; END IF;

 SELECT loan_limit,loan_days INTO v_limit,v_days
 FROM membership_types WHERE id=v_type_id;
 SELECT COUNT(*) INTO v_active FROM loans
 WHERE member_id=p_member_id AND status='ACTIVO';
 IF v_active>=v_limit THEN
  SET @msg=CONCAT('El socio alcanzó su tope de ',v_limit,' préstamos');
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=@msg;
 END IF;

 SET v_due=DATE_ADD(p_loan_date,INTERVAL v_days DAY);
 UPDATE copies SET status='PRESTADO' WHERE id=p_copy_id;
 INSERT INTO loans(member_id,copy_id,employee_id,loan_date,due_date,status)
 VALUES(p_member_id,p_copy_id,p_employee_id,p_loan_date,v_due,'ACTIVO');
 SELECT LAST_INSERT_ID() prestamo_creado;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_devolver_ejemplar;
DELIMITER $$
CREATE PROCEDURE sp_devolver_ejemplar(IN p_loan_id BIGINT,IN p_return_date DATE)
BEGIN
 DECLARE v_exists INT;
 DECLARE v_status VARCHAR(20);
 DECLARE v_copy BIGINT;
 DECLARE v_due DATE;
 DECLARE v_member BIGINT;
 DECLARE v_daily DECIMAL(10,2);
 DECLARE v_days INT;
 DECLARE v_fine DECIMAL(12,2);
 SELECT COUNT(*),MAX(status),MAX(copy_id),MAX(due_date),MAX(member_id)
 INTO v_exists,v_status,v_copy,v_due,v_member
 FROM loans WHERE id=p_loan_id;
 IF v_exists=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El préstamo no existe'; END IF;
 IF v_status<>'ACTIVO' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El préstamo no está activo'; END IF;
 IF p_return_date < (SELECT loan_date FROM loans WHERE id=p_loan_id) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La fecha de devolución es anterior al préstamo';
 END IF;
 SELECT mt.daily_fine INTO v_daily FROM members m
 JOIN membership_types mt ON mt.id=m.membership_type_id WHERE m.id=v_member;
 SET v_days=GREATEST(DATEDIFF(p_return_date,v_due),0);
 SET v_fine=v_days*v_daily;
 UPDATE loans SET status='DEVUELTO',return_date=p_return_date WHERE id=p_loan_id;
 UPDATE copies SET status='DISPONIBLE' WHERE id=v_copy;
 IF v_fine>0 THEN
  INSERT INTO fines(loan_id,reason,status,late_days,amount,generated_on)
  VALUES(p_loan_id,'MORA','PENDIENTE',v_days,v_fine,p_return_date);
 END IF;
 SELECT v_fine multa_generada;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_renovar_prestamo;
DELIMITER $$
CREATE PROCEDURE sp_renovar_prestamo(IN p_loan_id BIGINT,IN p_renewal_date DATE)
BEGIN
 DECLARE v_exists INT;
 DECLARE v_status VARCHAR(20);
 DECLARE v_due DATE;
 DECLARE v_member BIGINT;
 DECLARE v_title BIGINT;
 DECLARE v_type BIGINT;
 DECLARE v_days INT;
 DECLARE v_max INT;
 DECLARE v_used INT;
 DECLARE v_count INT;
 SELECT COUNT(*),MAX(status),MAX(due_date),MAX(member_id)
 INTO v_exists,v_status,v_due,v_member FROM loans WHERE id=p_loan_id;
 IF v_exists=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El préstamo no existe'; END IF;
 IF v_status<>'ACTIVO' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El préstamo no está activo'; END IF;
 IF p_renewal_date>v_due THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El préstamo está vencido: primero debe devolverse'; END IF;
 SELECT membership_type_id INTO v_type FROM members WHERE id=v_member;
 SELECT max_renewals,loan_days INTO v_max,v_days FROM membership_types WHERE id=v_type;
 SELECT COUNT(*) INTO v_used FROM renewals WHERE loan_id=p_loan_id;
 IF v_used>=v_max THEN
  SET @msg=CONCAT('El préstamo ya usó sus ',v_max,' renovaciones');
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=@msg;
 END IF;
 SELECT t.id INTO v_title FROM loans l JOIN copies c ON c.id=l.copy_id
 JOIN titles t ON t.id=c.title_id WHERE l.id=p_loan_id;
 SELECT COUNT(*) INTO v_count FROM reservations
 WHERE title_id=v_title AND status='PENDIENTE';
 IF v_count>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Hay reservas pendientes para este título'; END IF;
 INSERT INTO renewals(loan_id,renewed_on,previous_due_date,new_due_date)
 VALUES(p_loan_id,p_renewal_date,v_due,DATE_ADD(v_due,INTERVAL v_days DAY));
 UPDATE loans SET due_date=DATE_ADD(v_due,INTERVAL v_days DAY) WHERE id=p_loan_id;
 SELECT DATE_ADD(v_due,INTERVAL v_days DAY) nuevo_vencimiento;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_reporte_sedes;
DELIMITER $$
CREATE PROCEDURE sp_reporte_sedes(IN p_cutoff DATE)
BEGIN
 DECLARE v_done INT DEFAULT 0;
 DECLARE v_branch BIGINT;
 DECLARE v_name VARCHAR(100);
 DECLARE v_total INT;
 DECLARE v_borrowed INT;
 DECLARE v_overdue INT;
 DECLARE cur CURSOR FOR SELECT id,name FROM branches ORDER BY id;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=1;
 DROP TEMPORARY TABLE IF EXISTS tmp_report;
 CREATE TEMPORARY TABLE tmp_report(
  sede VARCHAR(100),ejemplares INT,prestados INT,vencidos INT,ocupacion_pct DECIMAL(6,2)
 );
 OPEN cur;
 read_loop: LOOP
  FETCH cur INTO v_branch,v_name;
  IF v_done=1 THEN LEAVE read_loop; END IF;
  SELECT COUNT(*) INTO v_total FROM copies
   WHERE branch_id=v_branch AND status NOT IN ('PERDIDO','DADO_DE_BAJA');
  SELECT COUNT(*) INTO v_borrowed FROM copies
   WHERE branch_id=v_branch AND status='PRESTADO';
  SELECT COUNT(*) INTO v_overdue FROM loans l JOIN copies c ON c.id=l.copy_id
   WHERE c.branch_id=v_branch AND l.status='ACTIVO' AND l.due_date<p_cutoff;
  INSERT INTO tmp_report VALUES(v_name,v_total,v_borrowed,v_overdue,
   IF(v_total=0,NULL,ROUND(v_borrowed*100/v_total,2)));
 END LOOP;
 CLOSE cur;
 SELECT * FROM tmp_report ORDER BY ocupacion_pct DESC,sede;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_pagar_multa;
DELIMITER $$
CREATE PROCEDURE sp_pagar_multa(
 IN p_fine_id BIGINT,IN p_amount DECIMAL(12,2),
 IN p_method VARCHAR(30),IN p_payment_date DATE
)
BEGIN
 DECLARE v_exists INT;
 DECLARE v_status VARCHAR(20);
 DECLARE v_amount DECIMAL(12,2);
 DECLARE v_paid DECIMAL(12,2);
 DECLARE v_balance DECIMAL(12,2);
 DECLARE EXIT HANDLER FOR 1644 RESIGNAL;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  RESIGNAL;
 END;
 SELECT COUNT(*),MAX(status),MAX(amount)
 INTO v_exists,v_status,v_amount FROM fines WHERE id=p_fine_id;
 IF v_exists=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La multa no existe'; END IF;
 IF v_status<>'PENDIENTE' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La multa no está pendiente'; END IF;
 SELECT COALESCE(SUM(amount),0) INTO v_paid FROM fine_payments WHERE fine_id=p_fine_id;
 SET v_balance=v_amount-v_paid;
 IF p_amount<=0 OR p_amount>v_balance THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El abono debe ser mayor que 0 y no superar el saldo';
 END IF;
 IF p_method NOT IN ('EFECTIVO','TARJETA','TRANSFERENCIA') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Medio de pago no válido: use EFECTIVO, TARJETA o TRANSFERENCIA';
 END IF;
 INSERT INTO fine_payments(fine_id,amount,paid_on,payment_method)
 VALUES(p_fine_id,p_amount,p_payment_date,p_method);
 SET v_balance=v_balance-p_amount;
 IF v_balance=0 THEN UPDATE fines SET status='PAGADA' WHERE id=p_fine_id; END IF;
 SELECT v_balance saldo_restante;
END$$
DELIMITER ;

SHOW PROCEDURE STATUS WHERE Db='bibliored';
