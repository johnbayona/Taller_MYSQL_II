-- 03_dql.sql
USE bibliored;

-- Q-01 Socios sin teléfono o que no están activos.
SELECT id, CONCAT(first_name,' ',last_name) socio, status estado, phone telefono
FROM members
WHERE phone IS NULL OR status <> 'ACTIVO'
ORDER BY id;

-- Q-02 Préstamos activos vencidos al corte 2026-11-10.
SELECT l.id prestamo, CONCAT(m.first_name,' ',m.last_name) socio,
 mt.name membresia, t.title titulo, c.barcode ejemplar, b.name sede,
 l.due_date vence, DATEDIFF('2026-11-10',l.due_date) dias_mora,
 DATEDIFF('2026-11-10',l.due_date)*mt.daily_fine multa_estimada
FROM loans l
JOIN members m ON m.id=l.member_id
JOIN membership_types mt ON mt.id=m.membership_type_id
JOIN copies c ON c.id=l.copy_id
JOIN titles t ON t.id=c.title_id
JOIN branches b ON b.id=c.branch_id
WHERE l.status='ACTIVO' AND l.due_date<'2026-11-10'
ORDER BY dias_mora DESC,l.id;

-- Q-03 Títulos con más de un autor.
SELECT t.title titulo, COUNT(ta.author_id) autores
FROM titles t JOIN title_authors ta ON ta.title_id=t.id
GROUP BY t.id,t.title
HAVING COUNT(ta.author_id)>1
ORDER BY t.id;

-- Q-04 Sedes con cinco o más préstamos históricos.
SELECT b.name sede, COUNT(l.id) prestamos_totales,
 SUM(l.status='ACTIVO') prestamos_activos,
 COUNT(DISTINCT l.member_id) socios_distintos
FROM branches b
JOIN copies c ON c.branch_id=b.id
JOIN loans l ON l.copy_id=c.id
GROUP BY b.id,b.name
HAVING COUNT(l.id)>=5
ORDER BY prestamos_totales DESC,b.name;

-- Q-05 Socios que nunca han solicitado préstamos.
SELECT m.id,CONCAT(m.first_name,' ',m.last_name) socio,m.joined_on afiliado_desde
FROM members m LEFT JOIN loans l ON l.member_id=m.id
WHERE l.id IS NULL
ORDER BY m.id;

-- Q-06 Categorías y autores sin títulos asociados.
SELECT 'categoria' tipo,c.name nombre
FROM categories c LEFT JOIN titles t ON t.category_id=c.id
WHERE t.id IS NULL
UNION ALL
SELECT 'autor',a.full_name
FROM authors a LEFT JOIN title_authors ta ON ta.author_id=a.id
WHERE ta.id IS NULL;

-- Q-07 Socios con al menos una multa pendiente.
SELECT DISTINCT m.id,CONCAT(m.first_name,' ',m.last_name) socio,m.status estado
FROM members m
JOIN loans l ON l.member_id=m.id
JOIN fines f ON f.loan_id=l.id
WHERE f.status='PENDIENTE'
ORDER BY m.id;

-- Q-08 Reservas pendientes que no tienen ejemplar disponible en la sede elegida.
SELECT r.id reserva,CONCAT(m.first_name,' ',m.last_name) socio,
 t.title titulo,b.name sede,r.expires_on expira
FROM reservations r
JOIN members m ON m.id=r.member_id
JOIN titles t ON t.id=r.title_id
JOIN branches b ON b.id=r.pickup_branch_id
WHERE r.status='PENDIENTE'
AND NOT EXISTS (
 SELECT 1 FROM copies c
 WHERE c.title_id=r.title_id AND c.branch_id=r.pickup_branch_id
 AND c.status='DISPONIBLE'
)
ORDER BY r.id;

-- Q-09 Títulos con costo superior al promedio.
SELECT title titulo,replacement_cost costo_reposicion
FROM titles
WHERE replacement_cost > (SELECT AVG(replacement_cost) FROM titles)
ORDER BY replacement_cost DESC,title;

-- Q-10 Socios con el máximo número histórico de préstamos (incluye empates).
SELECT m.id,CONCAT(m.first_name,' ',m.last_name) socio,COUNT(l.id) prestamos
FROM members m JOIN loans l ON l.member_id=m.id
GROUP BY m.id,m.first_name,m.last_name
HAVING COUNT(l.id) = (
 SELECT MAX(total_prestamos) FROM (
  SELECT COUNT(*) total_prestamos FROM loans GROUP BY member_id
 ) x
)
ORDER BY m.id;

-- Q-11 Ejemplar más antiguo de cada sede.
SELECT b.name sede,c.barcode ejemplar,t.title titulo,c.acquired_on adquirido
FROM copies c
JOIN branches b ON b.id=c.branch_id
JOIN titles t ON t.id=c.title_id
WHERE c.acquired_on = (
 SELECT MIN(c2.acquired_on) FROM copies c2 WHERE c2.branch_id=c.branch_id
)
ORDER BY b.id,c.barcode;

-- Q-12 Total de multas no anuladas, abonado y saldo por socio.
SELECT m.id,CONCAT(m.first_name,' ',m.last_name) socio,
 SUM(CASE WHEN f.status<>'ANULADA' THEN f.amount ELSE 0 END) total_multas,
 SUM(COALESCE(p.pagado,0)) pagado,
 SUM(CASE WHEN f.status<>'ANULADA' THEN f.amount-COALESCE(p.pagado,0) ELSE 0 END) saldo
FROM members m
JOIN loans l ON l.member_id=m.id
JOIN fines f ON f.loan_id=l.id
LEFT JOIN (
 SELECT fine_id,SUM(amount) pagado FROM fine_payments GROUP BY fine_id
) p ON p.fine_id=f.id
GROUP BY m.id,m.first_name,m.last_name
HAVING saldo>0
ORDER BY saldo DESC,m.id;
