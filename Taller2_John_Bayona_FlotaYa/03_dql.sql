-- Taller 2 FlotaYa | Fase 4 - DQL
USE flotaya;

-- Q-01 Estado de la flota.
SELECT status AS estado, COUNT(*) AS vehiculos
FROM vehicles GROUP BY status ORDER BY vehiculos DESC, estado;

-- Q-02 Duración inclusiva de temporadas altas.
SELECT name AS temporada, starts_on AS desde, ends_on AS hasta,
DATEDIFF(ends_on,starts_on)+1 AS dias
FROM seasons WHERE season_type='ALTA' ORDER BY starts_on;

-- Q-03 Vehículos disponibles con ubicación.
SELECT v.plate AS placa,b.name AS marca,m.name AS modelo,c.name AS categoria,
br.name AS sede,ci.name AS ciudad
FROM vehicles v JOIN models m ON m.id=v.model_id
JOIN brands b ON b.id=m.brand_id JOIN categories c ON c.id=m.category_id
JOIN branches br ON br.id=v.branch_id JOIN cities ci ON ci.id=br.city_id
WHERE v.status='DISPONIBLE'
ORDER BY FIELD(c.name,'Económico','Compacto','SUV','Camioneta 4x4','Van','Lujo'),v.plate;

-- Q-04 Contratos abiertos y días para devolver.
SELECT co.contract_number AS contrato,CONCAT(cu.first_name,' ',cu.last_name) AS cliente,
v.plate AS placa,m.name AS modelo,br.name AS sede_recogida,co.expected_return AS fin_esperado,
DATEDIFF(co.expected_return,'2026-11-23') AS dias_para_devolver,
COUNT(cad.id) AS conductores_adicionales
FROM contracts co JOIN reservations r ON r.id=co.reservation_id
JOIN customers cu ON cu.id=r.customer_id JOIN vehicles v ON v.id=r.vehicle_id
JOIN models m ON m.id=v.model_id JOIN branches br ON br.id=r.pickup_branch_id
LEFT JOIN contract_additional_drivers cad ON cad.contract_id=co.id
WHERE co.status='ABIERTO'
GROUP BY co.id,co.contract_number,cu.first_name,cu.last_name,v.plate,m.name,br.name,co.expected_return
ORDER BY dias_para_devolver,co.contract_number;

-- Q-05 Recaudo por sede de recogida, sin multiplicar contratos.
SELECT br.name AS sede,COUNT(DISTINCT co.id) AS contratos,SUM(p.amount) AS recaudado
FROM contracts co JOIN reservations r ON r.id=co.reservation_id
JOIN branches br ON br.id=r.pickup_branch_id JOIN payments p ON p.contract_id=co.id
GROUP BY br.id,br.name HAVING SUM(p.amount)>2000000
ORDER BY recaudado DESC,sede;

-- Q-06 Modelos sin vehículos.
SELECT b.name AS marca,m.name AS modelo
FROM models m JOIN brands b ON b.id=m.brand_id
LEFT JOIN vehicles v ON v.model_id=m.id
WHERE v.id IS NULL ORDER BY marca,modelo;

-- Q-07 Clientes sin licencia vigente a la fecha de corte.
SELECT cu.id,CONCAT(cu.first_name,' ',cu.last_name) AS cliente
FROM customers cu
WHERE NOT EXISTS (
 SELECT 1 FROM licenses l
 WHERE l.customer_id=cu.id AND l.issued_on<='2026-11-23' AND l.expires_on>='2026-11-23'
)
ORDER BY cu.registered_on;

-- Q-08 Disponibles sin reserva viva que se cruce con diciembre.
SELECT v.plate AS placa,m.name AS modelo,br.name AS sede
FROM vehicles v JOIN models m ON m.id=v.model_id JOIN branches br ON br.id=v.branch_id
WHERE v.status='DISPONIBLE'
AND NOT EXISTS (
 SELECT 1 FROM reservations r
 WHERE r.vehicle_id=v.id AND r.status IN ('PENDIENTE','CONFIRMADA','CONVERTIDA')
 AND r.pickup_date<='2026-12-31' AND r.return_date>'2026-12-01'
)
ORDER BY v.plate;

-- Q-09 Vehículos cuyo gasto conocido supera el promedio por vehículo con gasto conocido.
WITH gastos AS (
 SELECT vehicle_id,SUM(cost) AS gasto FROM maintenances
 WHERE cost IS NOT NULL GROUP BY vehicle_id
)
SELECT v.plate AS placa,g.gasto
FROM gastos g JOIN vehicles v ON v.id=g.vehicle_id
WHERE g.gasto>(SELECT AVG(gasto) FROM gastos)
ORDER BY g.gasto DESC;

-- Promedio, vehículos con registro de mantenimiento y vehículos con costo conocido.
SELECT (SELECT AVG(x.gasto) FROM
 (SELECT vehicle_id,SUM(cost) gasto FROM maintenances WHERE cost IS NOT NULL GROUP BY vehicle_id) x
) AS promedio_por_vehiculo,
COUNT(DISTINCT vehicle_id) AS vehiculos,
COUNT(DISTINCT CASE WHEN cost IS NOT NULL THEN vehicle_id END) AS con_gasto
FROM maintenances;

-- Q-10 Mayor kilometraje por categoría.
WITH ranking AS (
 SELECT c.name AS categoria,v.plate AS placa,v.mileage_km AS kilometraje,
 ROW_NUMBER() OVER(PARTITION BY c.id ORDER BY v.mileage_km DESC,v.plate) AS rn
 FROM vehicles v JOIN models m ON m.id=v.model_id JOIN categories c ON c.id=m.category_id
)
SELECT categoria,placa,kilometraje FROM ranking WHERE rn=1
ORDER BY FIELD(categoria,'Económico','Compacto','SUV','Camioneta 4x4','Van','Lujo');

-- Q-11 Ingresos por extra con precio histórico pactado.
SELECT e.name AS extra,COUNT(DISTINCT ce.contract_id) AS contratos,
COALESCE(SUM(ce.quantity*ce.unit_daily_price*DATEDIFF(
 COALESCE(co.actual_return,co.expected_return),co.started_on)),0) AS ingresos
FROM extras e LEFT JOIN contract_extras ce ON ce.extra_id=e.id
LEFT JOIN contracts co ON co.id=ce.contract_id
GROUP BY e.id,e.name ORDER BY ingresos DESC,extra;

-- Q-12 Daños registrados en inspecciones.
SELECT co.contract_number AS contrato,v.plate AS placa,
CONCAT(cu.first_name,' ',cu.last_name) AS cliente,i.stage AS etapa,
d.description AS dano,d.severity AS severidad,d.repair_cost AS costo,
IF(d.charge_customer,'Sí','No') AS se_cobra
FROM damages d JOIN inspections i ON i.id=d.inspection_id
JOIN contracts co ON co.id=i.contract_id JOIN reservations r ON r.id=co.reservation_id
JOIN customers cu ON cu.id=r.customer_id JOIN vehicles v ON v.id=r.vehicle_id
ORDER BY co.contract_number,d.id;
