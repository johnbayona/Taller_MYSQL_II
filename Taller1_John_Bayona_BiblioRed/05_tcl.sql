-- 05_tcl.sql
USE bibliored;

-- T1: observar que el procedimiento sin transacción puede dejar el ejemplar cambiado
-- Seleccione un ejemplar DISPONIBLE, un socio ACTIVO sin multas y un employee_id inexistente.
-- Ejemplo didáctico: se recomienda probar en una copia de la base.
-- CALL sp_prestar_ejemplar(1,14,9999,'2026-11-10');
-- El UPDATE del ejemplar ocurre antes del INSERT; el error de FK no revierte por sí solo
-- el UPDATE cuando no hay una transacción que agrupe ambas sentencias.

-- T2: procedimiento transaccional: todo o nada.
DROP PROCEDURE IF EXISTS sp_prestar_ejemplar_tx;
DELIMITER $$
CREATE PROCEDURE sp_prestar_ejemplar_tx(
 IN p_copy_id BIGINT, IN p_member_id BIGINT,
 IN p_employee_id BIGINT, IN p_loan_date DATE
)
BEGIN
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  RESIGNAL;
 END;
 START TRANSACTION;
 CALL sp_prestar_ejemplar(p_copy_id,p_member_id,p_employee_id,p_loan_date);
 COMMIT;
END$$
DELIMITER ;

-- Prueba fallida: el empleado 9999 no existe. El ejemplar debe conservar DISPONIBLE.
-- CALL sp_prestar_ejemplar_tx(3,14,9999,'2026-11-10');

-- Prueba correcta: use ejemplar disponible, socio activo sin multas ni tope y empleado existente.
-- CALL sp_prestar_ejemplar_tx(3,14,1,'2026-11-10');

-- Verificación: cantidad de ejemplares PRESTADO sin préstamo ACTIVO debe ser cero.
SELECT c.id,c.barcode
FROM copies c LEFT JOIN loans l ON l.copy_id=c.id AND l.status='ACTIVO'
WHERE c.status='PRESTADO' AND l.id IS NULL;

-- Los cambios solo se confirman con COMMIT; ROLLBACK devuelve los cambios de la transacción.
