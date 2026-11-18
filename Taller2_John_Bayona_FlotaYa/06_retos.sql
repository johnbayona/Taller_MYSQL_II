-- Taller 2 FlotaYa | Retos opcionales
USE flotaya;

-- R1: comparar cotización almacenada con cálculo por temporadas.
SELECT r.reservation_number AS reserva,CONCAT(c.first_name,' ',c.last_name) AS cliente,
cat.name AS categoria,r.pickup_date AS inicio,r.return_date AS fin,r.quoted_amount AS cotizado,
fn_valor_alquiler(cat.id,r.pickup_date,r.return_date) AS segun_temporada,
fn_valor_alquiler(cat.id,r.pickup_date,r.return_date)-r.quoted_amount AS diferencia
FROM reservations r JOIN customers c ON c.id=r.customer_id
JOIN vehicles v ON v.id=r.vehicle_id JOIN models m ON m.id=v.model_id
JOIN categories cat ON cat.id=m.category_id
WHERE r.quoted_amount<>fn_valor_alquiler(cat.id,r.pickup_date,r.return_date)
ORDER BY diferencia DESC;

-- R2: cartera de contratos cerrados; agregaciones separadas evitan multiplicar filas.
WITH extras_total AS (
 SELECT contract_id,SUM(quantity*unit_daily_price*DATEDIFF(COALESCE(actual_return,expected_return),started_on)) AS extras
 FROM contract_extras ce JOIN contracts c ON c.id=ce.contract_id GROUP BY contract_id
), danos_total AS (
 SELECT i.contract_id,SUM(d.repair_cost) AS danos FROM damages d JOIN inspections i ON i.id=d.inspection_id
 WHERE d.charge_customer=TRUE GROUP BY i.contract_id
), pagos_total AS (
 SELECT contract_id,SUM(amount) AS pagado FROM payments GROUP BY contract_id
)
SELECT c.contract_number AS contrato,CONCAT(cu.first_name,' ',cu.last_name) AS cliente,
c.rental_amount AS alquiler,COALESCE(e.extras,0) AS extras,COALESCE(d.danos,0) AS danos,
COALESCE(p.pagado,0) AS pagado,
c.rental_amount+COALESCE(e.extras,0)+COALESCE(d.danos,0)-COALESCE(p.pagado,0) AS saldo
FROM contracts c JOIN reservations r ON r.id=c.reservation_id JOIN customers cu ON cu.id=r.customer_id
LEFT JOIN extras_total e ON e.contract_id=c.id LEFT JOIN danos_total d ON d.contract_id=c.id
LEFT JOIN pagos_total p ON p.contract_id=c.id
WHERE c.status='CERRADO'
AND c.rental_amount+COALESCE(e.extras,0)+COALESCE(d.danos,0)-COALESCE(p.pagado,0)>0
ORDER BY saldo DESC;

-- R3: revisión de conductores titulares y adicionales.
-- Esta consulta de referencia presenta titulares y adicionales por separado.
SELECT c.contract_number AS contrato,CONCAT(cu.first_name,' ',cu.last_name) AS conductor,
'TITULAR' AS rol,cat.name AS categoria,
fn_edad_conductor(cu.birth_date,c.started_on) AS edad,cat.minimum_age AS edad_minima,
fn_licencia_vigente(cu.id,COALESCE(c.actual_return,c.expected_return)) AS licencia_vigente
FROM contracts c JOIN reservations r ON r.id=c.reservation_id
JOIN customers cu ON cu.id=r.customer_id JOIN vehicles v ON v.id=r.vehicle_id
JOIN models m ON m.id=v.model_id JOIN categories cat ON cat.id=m.category_id
WHERE fn_edad_conductor(cu.birth_date,c.started_on)<cat.minimum_age
   OR fn_licencia_vigente(cu.id,COALESCE(c.actual_return,c.expected_return))=FALSE
UNION ALL
SELECT c.contract_number,ad.full_name,'ADICIONAL',cat.name,
fn_edad_conductor(ad.birth_date,c.started_on),cat.minimum_age,
(ad.license_expires_on>=COALESCE(c.actual_return,c.expected_return))
FROM contracts c JOIN contract_additional_drivers cad ON cad.contract_id=c.id
JOIN additional_drivers ad ON ad.id=cad.additional_driver_id
JOIN reservations r ON r.id=c.reservation_id JOIN vehicles v ON v.id=r.vehicle_id
JOIN models m ON m.id=v.model_id JOIN categories cat ON cat.id=m.category_id
WHERE fn_edad_conductor(ad.birth_date,c.started_on)<cat.minimum_age
   OR ad.license_expires_on<COALESCE(c.actual_return,c.expected_return);
