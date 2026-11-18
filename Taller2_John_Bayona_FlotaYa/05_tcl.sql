-- Taller 2 FlotaYa | Fase 6 - TCL
USE flotaya;

-- 6.1 Ejemplo didáctico de SAVEPOINT para cierre de Paola.
-- Se recomienda ejecutar en una copia de práctica y verificar IDs reales antes de continuar.
START TRANSACTION;
SELECT * FROM contracts WHERE id=2;
SELECT * FROM vehicles WHERE plate='SPT601';
-- Registrar devolución e inspección según el escenario:
INSERT INTO returns(contract_id,returned_at,mileage_km,fuel_pct,branch_id,employee_id)
VALUES(2,'2026-11-23 09:30:00',12480,100,2,10);
INSERT INTO inspections(contract_id,stage,inspected_at,exterior_ok,interior_ok,notes,employee_id)
VALUES(2,'DEVOLUCION','2026-11-23 09:40:00',FALSE,TRUE,'Rin delantero izquierdo rayado',10);
SET @inspection_paola=LAST_INSERT_ID();
SAVEPOINT antes_del_dano;
INSERT INTO damages(inspection_id,description,severity,repair_cost,charge_customer)
VALUES(@inspection_paola,'Rin delantero izquierdo rayado','LEVE',3800000,TRUE);
SELECT * FROM damages WHERE inspection_id=@inspection_paola;
ROLLBACK TO SAVEPOINT antes_del_dano;
INSERT INTO damages(inspection_id,description,severity,repair_cost,charge_customer)
VALUES(@inspection_paola,'Rin delantero izquierdo rayado','LEVE',380000,TRUE);
-- El cierre se invoca dentro de la transacción; no hace COMMIT internamente.
SET @saldo_paola=NULL;
CALL sp_cerrar_contrato(2,'2026-11-23',@saldo_paola);
SELECT @saldo_paola AS saldo_cierre;
INSERT INTO payments(contract_id,concept,amount,payment_method,paid_at,card_last4,authorization_code)
VALUES(2,'CIERRE',@saldo_paola,'TARJETA','2026-11-23 10:00:00','3307','AUT-580114');
COMMIT;
SELECT * FROM contracts WHERE id=2;
SELECT * FROM vehicles WHERE plate='SPT601';
SELECT * FROM deposits WHERE contract_id=2;

-- 6.2 Todo o nada: si se intenta usar un medio no permitido, se revierte el cierre.
-- Se usa el contrato 1 como ejemplo de contrato abierto (ajustar a la fila de Carlos en el conjunto completo).
START TRANSACTION;
SELECT * FROM contracts WHERE id=1;
SELECT * FROM vehicles WHERE plate='MZD402';
-- En un escenario completo se insertan aquí la devolución y la inspección de Carlos.
-- La llamada al cierre y el pago con cheque se deben probar en un bloque con HANDLER.
-- CHEQUE no existe en el ENUM payment_method; el INSERT fallará y se debe ejecutar ROLLBACK.
ROLLBACK;
SELECT * FROM contracts WHERE id=1;
SELECT * FROM vehicles WHERE plate='MZD402';

-- 6.3 Auditoría de consistencia.
SELECT
 (SELECT COUNT(*) FROM vehicles v WHERE v.status='ALQUILADO'
  AND NOT EXISTS(SELECT 1 FROM contracts c JOIN reservations r ON r.id=c.reservation_id
   WHERE r.vehicle_id=v.id AND c.status='ABIERTO')) AS alquilados_sin_contrato,
 (SELECT COUNT(*) FROM contracts c WHERE c.status='CERRADO'
  AND NOT EXISTS(SELECT 1 FROM returns r WHERE r.contract_id=c.id)) AS cerrados_sin_devolucion,
 (SELECT COUNT(*) FROM deposits d JOIN contracts c ON c.id=d.contract_id
  WHERE c.status='CERRADO' AND d.status='RETENIDO') AS depositos_retenidos_de_cerrados,
 (SELECT COUNT(*) FROM contracts WHERE status='ABIERTO') AS contratos_abiertos,
 (SELECT COUNT(*) FROM payments) AS pagos;
