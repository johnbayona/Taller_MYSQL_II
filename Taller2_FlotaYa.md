# Taller 2 · FlotaYa

Esta vez **tú diseñas la base completa**. No hay tablas dadas ni DDL para copiar: recibes lo que contaría el gerente de una empresa de alquiler de carros, con sus reglas y sus datos. A partir de ahí construyes el diagrama, lo normalizas, lo llevas a MySQL, lo llenas de datos que cuenten una historia, lo consultas, lo proteges con funciones, procedimientos y permisos y cierras un contrato con una transacción que es **todo o nada**.

**Información general:** modalidad individual · **sesión 4 de MySQL II** (seguridad y permisos, con los procedimientos y funciones de las sesiones 2 y 3\) · MySQL 8.0.16 o superior y Workbench · diagrama en Mermaid, DrawSQL o Workbench · tamaño orientativo: tu modelo debería quedar **entre 20 y 28 tablas**; el modelo de referencia tiene **25**. La fecha y hora de entrega las indica el trainer.

> Escenario empresarial ficticio con fines académicos. Las personas, placas, documentos, correos y códigos son inventados y no identifican a nadie real.

## Contenido

- [Cómo trabajar](#cómo-trabajar)  
- [1\. Contexto del negocio](#1-contexto-del-negocio)  
- [2\. Reglas de negocio](#2-reglas-de-negocio)  
- [Fase 1 · Diagrama ER y normalización](#fase-1--diagrama-er-y-normalización)  
- [Fase 2 · DDL](#fase-2--ddl)  
- [Fase 3 · DML](#fase-3--dml)  
- [Fase 4 · DQL](#fase-4--dql)  
- [Fase 5 · DQL avanzado: funciones, procedimientos y permisos](#fase-5--dql-avanzado-funciones-procedimientos-y-permisos)  
- [Fase 6 · TCL](#fase-6--tcl)  
- [Retos](#retos)  
- [Entregables y rúbrica](#entregables-y-rúbrica)

---

## Cómo trabajar

Las fases van **en este orden** y cada una se apoya en la anterior:

**diagrama ER → DDL → DML → DQL → DQL avanzado → TCL**

Crea una carpeta (o un repositorio) `taller2_apellido_nombre/` con estos archivos:

| Archivo | Fase | Qué contiene |
| :---- | :---- | :---- |
| `00_diagrama.md` (Mermaid) o `00_diagrama.png` \+ `00_diagrama.md` | 1 | Diagrama, cardinalidades, justificación de la normalización y respuestas a las preguntas guía |
| `01_ddl.sql` | 2 | Base, tablas y restricciones |
| `02_dml.sql` | 3 | Datos semilla, operaciones de mantenimiento y errores provocados |
| `03_dql.sql` | 4 | Las 12 preguntas de negocio (`-- Q-01` … `-- Q-12`) |
| `04_dql_avanzado.sql` | 5 | Funciones, procedimientos, roles, cuentas y sus pruebas |
| `05_tcl.sql` | 6 | Las dos operaciones todo o nada y la auditoría final |
| `06_retos.sql` | Retos | Los retos que alcances (opcional) |
| `evidencias/` | 5 | Capturas de las tres cuentas de base de datos |

**Regla del script reproducible.** Los archivos `01` a `05`, ejecutados en orden sobre un servidor sin la base, deben correr **completos**. El primero empieza así:

```sql
DROP DATABASE IF EXISTS flotaya;
CREATE DATABASE flotaya;
USE flotaya;
```

- La base se llama **`flotaya`**.  
- Toda sentencia que **debe fallar** va con su comentario `-- ⚠️ ESPERADO: ERROR <código> …` y se ejecuta sola (Ctrl \+ Enter). Cuando corras el archivo completo, coméntala para que no detenga el script.  
- ⚠️ Borrar la base **no** borra las cuentas ni los roles de MySQL: tu `04_dql_avanzado.sql` debe poder ejecutarse dos veces seguidas sin fallar.  
- **Fecha de corte del taller: lunes `2026-11-23`.** Úsala fija en consultas y datos; nunca `NOW()` ni `CURDATE()`.

---

## 1\. Contexto del negocio

> *"En FlotaYa S.A.S. alquilamos carros en Bogotá, Medellín, Rionegro, Cartagena y Cali, y estamos por abrir en Bucaramanga. Hoy todo vive en hojas de cálculo y ya nos costó plata: cotizaciones mal hechas, depósitos que nadie liberó y un carro que se le entregó a un conductor que no tenía la edad. Necesitamos una base de datos seria."*

**Cómo funciona un alquiler.** El cliente **reserva** un vehículo concreto (una placa, no "un SUV cualquiera") para unas fechas, y dice en qué sede lo recoge y en cuál lo devuelve; pueden ser distintas. El asesor le **cotiza** el valor en ese momento. El día de la recogida la reserva se **convierte** en un **contrato**: un empleado lo firma, se le **entrega** el carro (con fecha y hora, kilometraje y nivel de combustible), un inspector hace la **inspección de entrega** y se le **retiene un depósito** de garantía en la tarjeta. Al contrato se le pueden sumar **conductores adicionales** autorizados y **extras** (GPS, silla de bebé, seguro total…), y el cliente puede pagar en varios momentos.

Cuando el cliente **devuelve** el carro, se registra la devolución (fecha y hora, sede, kilometraje, combustible, empleado que la recibe) y una **inspección de devolución**. Si la inspección encuentra **daños**, se anotan con su descripción, severidad y costo de reparación. Los daños que ya estaban en la entrega se anotan también, pero **no se le cobran** a este cliente. Luego se **cierra** el contrato: se recalcula el alquiler con la fecha real, se cobran los extras y los daños, el depósito se aplica a los daños o se libera, y el carro queda disponible en la sede donde lo devolvieron.

**El precio depende del calendario.** Cada categoría de vehículo tiene una tarifa diaria para cada **tipo de temporada** (BAJA, MEDIA o ALTA), y el año está partido en temporadas con nombre y fechas. La misma categoría cuesta lo mismo en todas las temporadas del mismo tipo.

**El carro también se daña solo.** Los vehículos van a **mantenimiento** (preventivo, correctivo o de latonería) en talleres propios o externos; se registra qué se hizo, dónde, cuándo empezó, cuándo terminó y cuánto costó.

**Los tres perfiles de seguridad.** El área de seguridad pide que nadie use la cuenta de administrador para trabajar. Quiere tres perfiles con **privilegio mínimo**: el **asesor** de mostrador, el **taller** de mantenimiento y el **auditor** externo (detalle en la regla 24).

### 1.1 Geografía y sedes

| Departamento | Ciudad | Sede | Dirección | Teléfono | ¿Aeropuerto? |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Bogotá D.C. | Bogotá | FlotaYa Bogotá Calle 26 | Avenida Calle 26 \# 69-76 | 6017001001 | No |
| Bogotá D.C. | Bogotá | FlotaYa Aeropuerto El Dorado | Avenida El Dorado \# 103-09 | 6017001002 | Sí |
| Antioquia | Medellín | FlotaYa Medellín El Poblado | Carrera 43A \# 7-50 | 6047001003 | No |
| Antioquia | Rionegro | FlotaYa Aeropuerto José María Córdova | Vía Aeropuerto JMC km 1 | 6047001004 | Sí |
| Bolívar | Cartagena | FlotaYa Cartagena Bocagrande | Carrera 2 \# 8-120 | 6057001005 | No |
| Valle del Cauca | Cali | FlotaYa Cali Granada | Avenida 9N \# 15-20 | 6027001006 | No |
| Santander | Bucaramanga | *(todavía sin sede)* |  |  |  |
| Quindío | Armenia | *(sin sede)* |  |  |  |
| Magdalena | *(todavía sin ciudades registradas)* |  |  |  |  |

Cada sede tiene asesores; algunas tienen inspectores; hay una administradora (Mónica Gaitán, en Calle 26\) y un mecánico (Gustavo Pérez, en Calle 26). De cada empleado se conoce su nombre, correo corporativo, rol, fecha de contratación y sede.

### 1.2 Categorías, tarifas y temporadas

| Categoría | Edad mínima | Depósito | Tarifa diaria BAJA | MEDIA | ALTA |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Económico | 21 | 1.500.000 | 120.000 | 140.000 | 180.000 |
| Compacto | 21 | 1.500.000 | 150.000 | 175.000 | 220.000 |
| SUV | 23 | 2.500.000 | 230.000 | 270.000 | 340.000 |
| Camioneta 4x4 | 25 | 3.000.000 | 300.000 | 350.000 | 430.000 |
| Van | 25 | 3.000.000 | 320.000 | 370.000 | 460.000 |
| Lujo | 30 | 5.000.000 | 450.000 | 520.000 | 650.000 |

&nbsp;

| Temporada | Tipo | Desde | Hasta |
| :---- | :---- | :---- | :---- |
| Fin de año 2025 | ALTA | 2025-12-15 | 2026-01-15 |
| Baja de inicio de año | BAJA | 2026-01-16 | 2026-03-28 |
| Semana Santa | ALTA | 2026-03-29 | 2026-04-05 |
| Baja de abril a junio | BAJA | 2026-04-06 | 2026-06-12 |
| Vacaciones de mitad de año | ALTA | 2026-06-13 | 2026-07-19 |
| Baja de segundo semestre | BAJA | 2026-07-20 | 2026-10-02 |
| Receso escolar de octubre | MEDIA | 2026-10-03 | 2026-10-12 |
| Baja de noviembre | BAJA | 2026-10-13 | 2026-11-30 |
| Temporada de novenas | MEDIA | 2026-12-01 | 2026-12-14 |
| Fin de año 2026 | ALTA | 2026-12-15 | 2027-01-15 |

### 1.3 Marcas, modelos y flota

| Marca | Modelo | Categoría | Transmisión | Combustible | Puestos |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Renault | Kwid | Económico | MECANICA | GASOLINA | 5 |
| Kia | Picanto | Económico | AUTOMATICA | GASOLINA | 5 |
| Chevrolet | Onix | Compacto | AUTOMATICA | GASOLINA | 5 |
| Mazda | Mazda 2 | Compacto | AUTOMATICA | GASOLINA | 5 |
| Renault | Duster | SUV | MECANICA | GASOLINA | 5 |
| Kia | Sportage | SUV | AUTOMATICA | HIBRIDO | 5 |
| Toyota | Hilux | Camioneta 4x4 | MECANICA | DIESEL | 5 |
| Hyundai | Staria | Van | AUTOMATICA | DIESEL | 11 |
| Mazda | CX-30 | SUV | AUTOMATICA | GASOLINA | 5 |

La marca **Nissan** está registrada, pero todavía no tiene modelos. El **CX-30** está en el catálogo, pero no hay ninguno en la flota. La categoría **Lujo** tiene tarifas, pero todavía no tiene modelos.

| Placa | Modelo | Año | Color | Km | Estado al corte | Sede donde está |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| KWD101 | Kwid | 2024 | Blanco | 18.950 | DISPONIBLE | Bogotá Calle 26 |
| KWD102 | Kwid | 2024 | Gris | 22.100 | DISPONIBLE | Aeropuerto El Dorado |
| KWD103 | Kwid | 2021 | Blanco | 98.400 | FUERA\_DE\_SERVICIO | Cali Granada |
| PCN201 | Picanto | 2025 | Rojo | 10.450 | DISPONIBLE | Aeropuerto El Dorado |
| PCN202 | Picanto | 2025 | Blanco | 12.400 | DISPONIBLE | Medellín El Poblado |
| ONX301 | Onix | 2024 | Plata | 30.500 | ALQUILADO | Aeropuerto El Dorado |
| ONX302 | Onix | 2023 | Negro | 41.890 | MANTENIMIENTO | Cartagena Bocagrande |
| MZD401 | Mazda 2 | 2025 | Azul | 9.310 | DISPONIBLE | Aeropuerto JMC |
| MZD402 | Mazda 2 | 2024 | Rojo | 26.300 | ALQUILADO | Aeropuerto JMC |
| DST501 | Duster | 2023 | Blanco | 48.620 | DISPONIBLE | Bogotá Calle 26 |
| DST502 | Duster | 2024 | Gris | 22.710 | DISPONIBLE | Cali Granada |
| SPT601 | Sportage | 2025 | Negro | 11.500 | ALQUILADO | Aeropuerto El Dorado |
| SPT602 | Sportage | 2025 | Blanco | 9.600 | DISPONIBLE | Aeropuerto JMC |
| HLX701 | Hilux | 2023 | Plata | 64.380 | DISPONIBLE | Medellín El Poblado |
| HLX702 | Hilux | 2022 | Blanco | 88.100 | MANTENIMIENTO | Cali Granada |
| STR801 | Staria | 2024 | Gris | 35.700 | DISPONIBLE | Aeropuerto El Dorado |
| STR802 | Staria | 2025 | Blanco | 15.480 | DISPONIBLE | Cartagena Bocagrande |

Las dos que están en `MANTENIMIENTO` tienen un trabajo **en curso**: la HLX702, un cambio de embrague en *Diésel del Valle* desde el 2026-11-16, y la ONX302, una reparación de latonería en *Latonería Caribe* desde el 2026-10-26. La KWD103 tuvo un diagnóstico de motor que terminó en pérdida total.

### 1.4 Clientes y conductores

| Cliente | Documento | Nacimiento | Vive en | Estado | Licencias |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Andrea Salazar | CC | 1990-04-12 | Bogotá | ACTIVO | B1, vence 2028-05-10 |
| Carlos Mejía | CC | 1985-09-30 | Medellín | ACTIVO | B1, vence 2027-02-20 |
| Juliana Patiño | CC | 2004-07-15 | Bogotá | ACTIVO | B1, expedida 2022-08-01, vence 2032-08-01 |
| Lucas Ferreira | CE | 1979-02-02 | Cartagena | ACTIVO | B1 de Brasil, vence 2026-12-31 |
| Diana Rozo | CC | 1993-11-25 | Cali | ACTIVO | B1, vence 2029-11-30 |
| Emma Walker | PASAPORTE | 1988-06-18 | Cartagena | ACTIVO | B1 de Canadá, vence 2031-06-01 |
| Jorge Arango | CC | 1975-01-09 | Medellín | ACTIVO | **Dos:** C1 de 2000-01-15 a 2010-01-15 (vencida) y C1 de 2010-01-15 a 2030-01-15 |
| Paola Quintero | CC | 1999-12-03 | Bogotá | ACTIVO | B1, expedida 2016-12-10, **vence 2026-12-10** |
| Esteban Rueda | CC | 2002-05-21 | Bucaramanga | ACTIVO | B1, **venció 2026-08-01** |
| Martha Cifuentes | CC | 1968-03-14 | Bogotá | **BLOQUEADO** | B1, vence 2028-04-04 |
| Kevin Morales | CC | 2005-10-02 | Cali | ACTIVO | B1, expedida 2023-10-10, vence 2033-10-10 |
| Laura Benítez | CC | 1996-08-08 | Medellín | ACTIVO | **Ninguna registrada**; tampoco dio teléfono |
| Ricardo Lozano | CC | 1982-12-24 | Bogotá | ACTIVO | B1, vence 2027-12-24 |
| Sofía Herrera | CC | 2001-01-30 | Rionegro | ACTIVO | B1, vence 2029-02-01 |

Los números de documento, de licencia, los correos y los teléfonos los inventas tú (ficticios y sin repetir).

| Conductor adicional | Nacimiento | Licencia vence |
| :---- | :---- | :---- |
| Felipe Salazar | 1988-03-03 | 2029-03-03 |
| Mónica Arango | 1977-07-07 | 2028-07-07 |
| Tomás Ferreira | 2006-03-03 | 2030-03-03 |
| Natalia Rozo | 1995-05-05 | 2026-09-30 |

### 1.5 Extras

| Extra | Precio diario de lista |
| :---- | :---- |
| GPS | 15.000 |
| Silla de bebé | 12.000 |
| Seguro total | 45.000 |
| Conductor adicional | 20.000 |
| Wi-Fi portátil | 10.000 |
| Portabicicletas | 18.000 |

### 1.6 Lo que está pasando al corte (lunes 2026-11-23)

**Tres contratos abiertos:**

| Cliente | Vehículo | Recoge → devuelve | Desde | Fin esperado | Extras pactados | Conductor adicional | Pagado | Depósito |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Paola Quintero | SPT601 | Aeropuerto El Dorado → Aeropuerto El Dorado | 2026-11-15 | 2026-11-22 | Seguro total (45.000) y Conductor adicional (20.000) | Felipe Salazar | Alquiler 1.610.000 con tarjeta | 2.500.000 retenido |
| Ricardo Lozano | ONX301 | Aeropuerto El Dorado → Bogotá Calle 26 | 2026-11-17 | 2026-11-21 | GPS (15.000) | — | Alquiler 600.000 con tarjeta | 1.500.000 retenido |
| Carlos Mejía | MZD402 | Aeropuerto JMC → Aeropuerto JMC | 2026-11-18 | 2026-11-25 | Conductor adicional (20.000) y 2 sillas de bebé (12.000 c/u) | Mónica Arango | Nada todavía | 1.500.000 retenido |

**Reservas vivas para las próximas semanas:**

| Cliente | Vehículo | Recoge → devuelve | Desde | Hasta | Estado | Cotizado |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Juliana Patiño | KWD101 | Bogotá Calle 26 → Bogotá Calle 26 | 2026-11-27 | 2026-12-02 | CONFIRMADA | 620.000 |
| Diana Rozo | STR801 | Aeropuerto El Dorado → Aeropuerto El Dorado | 2026-12-18 | 2026-12-23 | CONFIRMADA | 2.300.000 |
| Kevin Morales | PCN202 | Medellín El Poblado → Medellín El Poblado | 2026-12-10 | 2026-12-17 | PENDIENTE | 980.000 |
| Sofía Herrera | SPT602 | Aeropuerto JMC → Aeropuerto JMC | 2026-12-05 | 2026-12-09 | PENDIENTE | 1.080.000 |

**Historia que la gerencia recuerda** (septiembre a noviembre de 2026): ver la sección *Casos que tus datos deben contener* en la fase 3\.

---

## 2\. Reglas de negocio

**Geografía y personal**

1. FlotaYa se organiza en **departamento → ciudad → sede**. Toda ciudad es de un departamento y toda sede es de una ciudad. Puede haber ciudades sin sede y departamentos sin ciudades. El nombre de la sede no se repite. Una sede puede ser de aeropuerto; si no se dice, **no** lo es. El teléfono de la sede es opcional.  
2. Cada empleado trabaja en una sede, tiene un correo corporativo que no se repite, una fecha de contratación y un rol: `ADMINISTRADOR`, `ASESOR`, `INSPECTOR` o `MECANICO`.

**Flota y precios**

3. Cada vehículo es de un modelo; cada modelo es de una marca y de una categoría. La placa no se repite. Un modelo tiene transmisión (`MECANICA` o `AUTOMATICA`), combustible (`GASOLINA`, `DIESEL`, `HIBRIDO` o `ELECTRICO`) y número de puestos. Puede haber marcas sin modelos y modelos sin vehículos.  
4. La **categoría** fija la edad mínima del conductor (nunca menor de 18\) y el valor del depósito de garantía. Su nombre no se repite.  
5. El estado de un vehículo es `DISPONIBLE`, `ALQUILADO`, `MANTENIMIENTO` o `FUERA_DE_SERVICIO`; un vehículo nuevo entra `DISPONIBLE` si no se dice otra cosa. Cada vehículo está en una sede, que cambia cuando lo devuelven en otra.  
6. El **calendario de temporadas** cubre todos los días del 2025-12-15 al 2027-01-15, **sin huecos ni cruces**. Cada temporada tiene nombre, tipo (`BAJA`, `MEDIA` o `ALTA`) y fechas; nunca termina antes de empezar.  
7. Cada categoría tiene **exactamente una** tarifa diaria por tipo de temporada, y esa tarifa es mayor que cero.  
8. El **valor del alquiler** se calcula **noche por noche**: se suma la tarifa de la temporada de cada día, desde el día de recogida hasta el día **anterior** a la devolución. Ejemplo: un Económico del 30 de noviembre al 2 de diciembre paga una noche BAJA (120.000) y una MEDIA (140.000) \= 260.000.  
9. Un **mantenimiento** es de un vehículo y tiene tipo (`PREVENTIVO`, `CORRECTIVO` o `LATONERIA`), descripción, taller, fecha de inicio, fecha de fin y costo. Si no tiene fecha de fin está **en curso**: su costo todavía no se conoce y el vehículo está en `MANTENIMIENTO`. Cuando termina, no puede terminar antes de empezar.

**Clientes y conductores**

10. Un cliente tiene tipo de documento (`CC` si no se dice, `CE` o `PASAPORTE`) y número que no se repite, nombres, apellidos, correo que no se repite, teléfono opcional, fecha de nacimiento, ciudad donde vive, fecha de registro y estado (`ACTIVO` si no se dice, o `BLOQUEADO`).  
11. Un cliente puede tener **varias licencias** (renovaciones, licencias de otro país) o ninguna registrada. Cada licencia tiene número que no se repite, categoría (`B1`, `B2`, `C1` o `C2`), fecha de expedición, fecha de vencimiento y país que la expidió. Una licencia está **vigente** en una fecha si ya se había expedido y todavía no ha vencido.  
12. Un **conductor adicional** no es necesariamente cliente de FlotaYa. Se conoce su documento (que no se repite), nombre, fecha de nacimiento, número de licencia y vencimiento de la licencia. Puede estar autorizado en varios contratos, pero no dos veces en el mismo.

**Reservas y contratos**

13. Una **reserva** es de un cliente para un vehículo concreto, con sede de recogida, sede de devolución (pueden ser distintas), fecha de recogida, fecha de devolución (siempre posterior), valor cotizado y el momento en que se creó (si no se dice, el momento en que se registra). Su estado es `PENDIENTE` (al crearla), `CONFIRMADA`, `CONVERTIDA` (ya es contrato) o `CANCELADA`. Las reservas se numeran desde **501**.  
14. Dos reservas **vivas** (`PENDIENTE`, `CONFIRMADA` o `CONVERTIDA`) del mismo vehículo **no pueden compartir ningún día**, ni siquiera el de devolución de una y el de recogida de la otra. Las canceladas no bloquean nada.  
15. Para reservar, el cliente debe estar `ACTIVO`, tener la **edad mínima** de la categoría el día de la recogida y una **licencia vigente hasta el día de la devolución**; el vehículo no puede estar `FUERA_DE_SERVICIO`.  
16. Un **contrato** nace de una reserva, y una reserva produce **como máximo un** contrato. Los contratos se numeran desde **9001**. El contrato registra el vehículo, el empleado que lo firma, la fecha de inicio, la fecha de fin esperada (posterior al inicio), la fecha real de devolución (vacía mientras está abierto), el valor del alquiler y su estado (`ABIERTO` al crearlo o `CERRADO`). El **cliente** del contrato es el de su reserva: no se vuelve a registrar.  
17. Un contrato puede llevar **varios extras** y un extra está en muchos contratos. Por cada extra del contrato se guarda la cantidad (al menos 1\) y el **precio pactado ese día**, que no cambia aunque después cambie el precio de lista. Un extra no aparece dos veces en el mismo contrato: se aumenta la cantidad.

**Entrega, devolución, inspección y daños**

18. Cada contrato tiene **como máximo una entrega y una devolución**. Cada una registra fecha y hora, kilometraje, porcentaje de combustible (de 0 a 100), sede y empleado.  
19. Cada contrato tiene **como máximo una inspección por etapa** (`ENTREGA` o `DEVOLUCION`). La inspección registra fecha y hora, si el exterior y el interior están bien, notas opcionales y el empleado que la hizo.  
20. Un **daño** se encuentra en una inspección y tiene descripción, severidad (`LEVE`, `MODERADO` o `GRAVE`), costo de reparación (no negativo) y si se le cobra al cliente. Los daños encontrados en la **entrega** son previos y **no** se cobran.

**Dinero**

21. Cada contrato tiene **un** depósito de garantía por el valor que fija la categoría del vehículo, con el momento en que se retuvo, el momento en que se liberó (vacío mientras siga retenido), el valor aplicado a daños (0 si no se dice; nunca negativo ni mayor que el depósito) y su estado: `RETENIDO` (al crearlo), `LIBERADO` o `APLICADO`.  
22. Un contrato puede tener **varios pagos**. Cada pago tiene concepto (`ALQUILER`, `EXTRAS`, `DAÑOS` o `CIERRE`), valor mayor que cero, medio de pago (`TARJETA`, `EFECTIVO`, `TRANSFERENCIA` o `DEPOSITO`; **FlotaYa no recibe cheques**), fecha y hora y, cuando aplica, los últimos 4 dígitos de la tarjeta y el código de autorización.  
23. Al **cerrar** un contrato: el alquiler se recalcula con la **fecha real** de devolución; los extras valen cantidad × precio pactado × noches; se suman los daños cobrables de la inspección de devolución; el depósito se **aplica** a esos daños (hasta su valor) y ese abono queda registrado como un pago de concepto `DAÑOS` con medio `DEPOSITO`, o se **libera** si no hay daños cobrables; el vehículo queda `DISPONIBLE` en la sede de devolución y con el kilometraje de la devolución. **Saldo \= alquiler \+ extras \+ daños − pagos.** El cierre es **todo o nada**. Después de cualquier cierre se cumple: ningún vehículo `ALQUILADO` sin un contrato abierto, ningún contrato cerrado sin devolución y ningún depósito `RETENIDO` de un contrato cerrado.

**Seguridad**

24. **Privilegio mínimo.** Cada perfil tiene su propia cuenta de base de datos y nadie trabaja con la cuenta de administrador:

| Perfil y cuenta | Qué puede hacer | Qué no puede hacer |
| :---- | :---- | :---- |
| **Asesor de mostrador** · `asesor_flotaya` | Ver las reservas, crearlas (siempre con el procedimiento de reservas, que valida las reglas 14 y 15\) y confirmarlas. Consultar los clientes y los vehículos. Calcular una cotización. | Borrar reservas. Ver los pagos. Ver las licencias de los clientes (aunque el procedimiento sí las revise por él). Ver contratos, depósitos o mantenimientos. |
| **Taller de mantenimiento** · `taller_flotaya` | Ver, registrar y actualizar mantenimientos. Del vehículo, ver **solo** su identificador, placa, estado, kilometraje y sede, y cambiar **solo** su estado (por ejemplo, devolverlo a `DISPONIBLE` cuando termina el arreglo). | Ver los demás datos del vehículo (modelo, año, color). Cambiar el kilometraje o la sede. Ver reservas, contratos, clientes o dinero. |
| **Auditor externo** · `auditor_flotaya` | Leer contratos, reservas, vehículos, mantenimientos, devoluciones, inspecciones, daños y depósitos. De los pagos, ver el número del pago, el contrato, el concepto, el valor y la fecha. | Cambiar cualquier dato. Ver el **medio de pago**, los **últimos 4 dígitos** de la tarjeta o el **código de autorización**. Ver los clientes. |

---

## Fase 1 · Diagrama ER y normalización

Entrega en `00_diagrama.md`:

1. **Entidades** con todos sus atributos, la **PK** de cada una y sus **FK**.  
2. **Cardinalidades** en las dos direcciones, con mínimo y máximo (0..1, 1..1, 0..N, 1..N). Cuidado con las relaciones **1:1** y con las entidades que se relacionan **dos veces** con la misma otra entidad.  
3. Las **tablas puente** que resuelven cada relación N:M, con los atributos propios de la relación.  
4. Una justificación breve de **1FN, 2FN y 3FN**: muestra una versión defectuosa de un dato (por ejemplo, una fila con varios extras en una celda o con la tarifa repetida) y cómo tu diseño la corrige. Di si hace falta 4FN y por qué.  
5. Tus respuestas, en dos o tres líneas cada una, a las **preguntas guía**.

### Preguntas guía

1. ¿La **reserva** y el **contrato** son la misma cosa? ¿Qué le pasa a una reserva cancelada? Si el contrato "sabe" de qué reserva viene, ¿necesita guardar otra vez al cliente?  
2. ¿Dónde guardas el precio de un extra para que el contrato de septiembre no cambie si mañana sube el GPS?  
3. Hay 6 categorías, 3 tipos de temporada y 10 temporadas. ¿Cuántas tarifas tienes que guardar? ¿La tarifa depende de la **temporada** o del **tipo** de temporada?  
4. La edad mínima y el depósito, ¿son del vehículo, del modelo o de la categoría? ¿Qué anomalía aparece si los pones en el lugar equivocado?  
5. Una reserva tiene **dos** sedes. Una entrega y una devolución también tienen sede y empleado. ¿Cómo se dibuja que dos relaciones distintas lleguen a la misma entidad?  
6. ¿Un **daño** es del contrato o de la inspección? ¿Cómo sabe tu modelo si un daño era previo o es nuevo?  
7. Un cliente renovó su licencia y conserva la vieja vencida. ¿Cabe eso en tu modelo sin borrar la historia? ¿Y un conductor adicional que no es cliente?  
8. ¿Qué datos se **guardan** y cuáles se **calculan**? Piensa en la edad del conductor, el valor cotizado, el valor del alquiler al cerrar y el saldo del contrato.

### Casos que tu diseño debe permitir

| \# | Caso | Resultado |
| :---- | :---- | :---- |
| 1 | Jorge Arango tiene dos licencias: una vencida y otra vigente | ✅ Se acepta |
| 2 | Carlos Mejía recoge en Medellín El Poblado y devuelve en el Aeropuerto JMC | ✅ Se acepta |
| 3 | Un contrato lleva 2 sillas de bebé y un conductor adicional; el GPS sube de precio y los contratos viejos conservan el precio pactado | ✅ Se acepta |
| 4 | El mismo conductor adicional autorizado en dos contratos distintos | ✅ Se acepta |
| 5 | Un daño encontrado en la inspección de entrega, que no se le cobra al cliente | ✅ Se acepta |
| 6 | Una marca sin modelos, un modelo sin vehículos, una categoría con tarifas y sin modelos, una ciudad sin sede, un departamento sin ciudades | ✅ Se acepta |
| 7 | Un mantenimiento en curso, sin fecha de fin y sin costo | ✅ Se acepta |
| 8 | Un pago en efectivo sin datos de tarjeta | ✅ Se acepta |
| 9 | Una cliente sin teléfono y sin licencia registrada | ✅ Se acepta |
| 10 | Dos vehículos con la misma placa | ❌ Debe rechazarse |
| 11 | Dos tarifas para la misma categoría y el mismo tipo de temporada, o una tarifa de \$0 | ❌ Debe rechazarse |
| 12 | Una temporada que termina antes de empezar; una reserva o un contrato que termina el mismo día o antes de empezar | ❌ Debe rechazarse |
| 13 | Dos contratos para la misma reserva | ❌ Debe rechazarse |
| 14 | Una segunda inspección de entrega para el mismo contrato | ❌ Debe rechazarse |
| 15 | El mismo extra dos veces en un contrato, o con cantidad 0 | ❌ Debe rechazarse |
| 16 | Un depósito con más valor aplicado que el depósito mismo | ❌ Debe rechazarse |
| 17 | Un pago con cheque, o un pago de \$0 | ❌ Debe rechazarse |
| 18 | Borrar una categoría que ya tiene modelos o tarifas | ❌ Debe rechazarse |
| 19 | Una reserva que se cruza un día con otra reserva viva del mismo vehículo | ❌ Debe rechazarse (fase 5\) |
| 20 | Una reserva de un cliente bloqueado, menor que la edad mínima o con la licencia vencida antes de devolver | ❌ Debe rechazarse (fase 5\) |

---

## Fase 2 · DDL

Escribe `01_ddl.sql` con la base y todas las tablas, en orden de dependencia (primero las que no dependen de nadie). Puedes escribir las restricciones directamente en el `CREATE TABLE`; si prefieres crear y luego ajustar con `ALTER TABLE`, también vale.

**Convenciones obligatorias** (las de clase):

- Tablas en **inglés, plural, `snake_case`**; columnas en inglés `snake_case`, con la unidad cuando aplica (`mileage_km`, `fuel_pct`); FK como `<tabla_padre_singular>_id`. Sin tildes ni ñ en los identificadores.  
- PK siempre `id BIGINT AUTO_INCREMENT PRIMARY KEY`.  
- `NOT NULL`, `UNIQUE` y `DEFAULT` **en línea**; `CHECK` y `UNIQUE` compuestos al final de la tabla (o con `ALTER TABLE … ADD`).  
- FK **sin nombre**: `FOREIGN KEY (<columna>) REFERENCES <tabla>(id)`.  
- Estados y catálogos cortos con **`ENUM` en español y MAYÚSCULAS**, exactamente con los valores de las reglas, y `DEFAULT` cuando la regla dice "si no se dice…".  
- Dinero `DECIMAL(12,2)`; fechas `DATE` o `DATETIME`; sí/no `BOOLEAN`.  
- **No** escribas `CHARACTER SET utf8mb4`, `COLLATE` ni `ENGINE`.  
- Cierra con `SHOW TABLES;` y un `DESCRIBE` de tus dos tablas principales.

**Lo que la estructura debe impedir por sí sola** (sin procedimientos): todo lo que en la tabla de casos dice "Debe rechazarse" del 10 al 18, más:

- que se repitan documentos, correos, placas, números de licencia, nombres de sede, de categoría, de marca o de extra;  
- que se registre algo con un estado, rol, etapa, severidad, concepto o medio fuera de los valores de las reglas;  
- que una hija apunte a un padre que no existe;  
- que un mantenimiento termine antes de empezar, un porcentaje de combustible salga de 0–100, un costo de daño sea negativo o una edad mínima sea menor de 18;  
- que las reservas empiecen en un número distinto de 501 y los contratos en uno distinto de 9001\.

**Lo que la estructura no alcanza a proteger.** Escribe al inicio de `01_ddl.sql` (comentado) o en `00_diagrama.md` una tabla *Regla \| ¿Se protege con la estructura? \| Cómo o por qué no* para las reglas 6, 8, 9, 14, 15, 20, 21 y 23\. Las que no se puedan proteger con `NOT NULL`, `UNIQUE`, `CHECK` o FK son trabajo de la fase 5\.

> 💡 Un `CHECK` solo puede mirar la **fila** que se está guardando. Pregúntate si la regla necesita mirar otras filas, otras tablas o "la fecha de hoy".

---

## Fase 3 · DML

Escribe `02_dml.sql`. `INSERT` siempre con lista de columnas y **sin el `id`**; varias filas por sentencia.

### Mínimos

| Tipo de dato | Mínimo |
| :---- | :---- |
| Catálogos (geografía, sedes, categorías, temporadas, tarifas, marcas, modelos, extras) | **Todos** los de la sección 1, sin faltar ninguno |
| Empleados | 10, con los cuatro roles y al menos un asesor por sede |
| Vehículos | Los 17 de la flota |
| Mantenimientos | 6, con los dos en curso |
| Clientes y licencias | Los 14 clientes y sus licencias; los 4 conductores adicionales |
| Reservas | 14, con los cuatro estados (incluidas las vivas de la sección 1.6) |
| Contratos | 8, con los tres abiertos de la sección 1.6; los demás cerrados |
| Entregas, devoluciones e inspecciones | Una entrega e inspección de entrega por contrato; devolución e inspección de devolución por contrato cerrado |
| Daños | 3 |
| Depósitos | Uno por contrato |
| Pagos | 12, con contratos de más de un pago y los cuatro medios |

### Datos obligatorios del negocio

Deben coincidir **exactamente** con la sección 1: geografía y sedes (1.1), categorías, tarifas y temporadas (1.2), marcas, modelos y flota con su estado y sede (1.3), clientes, licencias y conductores adicionales (1.4), extras (1.5) y los contratos abiertos y reservas vivas al corte (1.6), con sus extras, conductores, pagos y depósitos. Las cotizaciones de las reservas vivas se escriben tal cual aparecen en la tabla, **aunque alguna esté mal calculada**: los retos lo descubren.

### Casos que tus datos deben contener

Los contratos cerrados los inventas tú, entre septiembre y noviembre de 2026 (al menos **dos meses distintos**), respetando las reglas de precios. Además deben aparecer:

1. **Un daño previo:** el contrato de **Lucas Ferreira** en la Staria STR802 (Cartagena, del 2026-10-01 al 2026-10-06) tiene en su entrega un *rayón previo en el bómper trasero* (LEVE, 180.000) que no se cobra, y lleva como conductor adicional a **Tomás Ferreira**.  
2. **Un daño cubierto por el depósito:** el contrato de **Jorge Arango** en la Hilux HLX701 (Medellín El Poblado, del 2026-10-15 al 2026-10-20) volvió con un *rayón en la puerta del conductor* (LEVE, 350.000, cobrable) que se pagó con el depósito; lleva como conductora adicional a **Natalia Rozo**.  
3. **Un daño mayor que el depósito:** el contrato de **Emma Walker** en el Onix ONX302 (Cartagena, del 2026-10-20 al 2026-10-24, con GPS) volvió con un *golpe en la puerta trasera derecha* (GRAVE, 2.400.000, cobrable). El depósito de 1.500.000 se aplicó completo y la clienta pagó el alquiler y los extras, pero **quedó debiendo 900.000**.  
4. **Una devolución tardía:** el contrato de **Diana Rozo** en la Duster DST502 (Cali, recogida el 2026-10-08, fin esperado el 2026-10-12) se devolvió el 2026-10-13, y su reserva se había **cotizado como si todo fuera temporada BAJA** (920.000).  
5. **Reservas canceladas:** una de Martha Cifuentes (antes de que la bloquearan) y otra de Esteban Rueda.  
6. **Valores vacíos con significado:** contratos abiertos sin fecha real de devolución, mantenimientos en curso sin fecha de fin ni costo, pagos sin datos de tarjeta, una cliente sin teléfono.  
7. **Padres sin hijos:** Nissan sin modelos, el CX-30 sin vehículos, Lujo sin modelos, Armenia sin sede, Magdalena sin ciudades, Laura Benítez sin reservas, Wi-Fi portátil y Portabicicletas sin alquilar.  
8. **Vehículos que nunca han ido a mantenimiento** y otros que han ido más de una vez.

Cierra el archivo de semillas con un conteo por tabla y deja el resultado esperado en un comentario.

### Operaciones del día (después de las semillas)

Cada `UPDATE` y `DELETE` va con su `SELECT` **previo** (mismo `WHERE`) y su `SELECT` de comprobación, y con `WHERE` por clave.

1. **FlotaYa abre en Bucaramanga.** Registra la sede *FlotaYa Bucaramanga Cabecera* (Carrera 35 \# 48-20, teléfono 6077001007\) **sin decir si es de aeropuerto**, contrata al asesor **Daniel Rojas** (`daniel.rojas@flotaya.example.com`, desde el 2026-11-20) y asígnale una Duster nueva: placa **DST503**, modelo 2026, roja, 1.200 km, **sin decir su estado**. Muestra en una sola fila la sede, si es de aeropuerto, la ciudad, el asesor y el vehículo con su estado.  
2. **Ajustes de precios.** La tarifa **ALTA** de **Lujo** sube 5 %. El **GPS** sube a 16.000 por día; compara el precio de lista con el precio pactado de los contratos que lo tienen.  
3. **Confirmaciones.** Las reservas `PENDIENTE` que empiezan en diciembre pasan a `CONFIRMADA`. Intenta primero con el `WHERE` por estado y fecha (con *Safe Updates* activo) y luego hazlo por clave.  
4. **Limpieza.** Borra la marca Nissan y el extra Portabicicletas, comprobando antes que nada depende de ellos. Intenta borrar la categoría Económico (comprueba antes cuántos modelos y tarifas tiene).  
5. **Errores provocados.** Al menos **3** sentencias comentadas con su error esperado, tomadas de los casos 10 a 18 de la fase 1, de tipos distintos (por ejemplo, un duplicado, un `CHECK` y un valor fuera del catálogo).

---

## Fase 4 · DQL

Escribe `03_dql.sql`. Las preguntas no dicen qué instrucciones usar: tú decides cómo relacionar, filtrar, agrupar y ordenar. Supón que ya corriste la fase 3 completa, incluidas las operaciones del día. Montos, promedios y porcentajes con dos decimales; fechas de referencia las del caso, nunca la del sistema. **Se califica el resultado y el razonamiento, no una única manera de escribir SQL.**

### Q-01 · ¿Cómo está repartida la flota hoy?

Operaciones quiere un tablero rápido: cuántos vehículos hay en cada estado. Los estados con más vehículos van primero; si hay empate, en orden alfabético.

**Columnas esperadas, en este orden:** `estado`, `vehiculos`.

### Q-02 · ¿Cuánto duran las temporadas altas?

Comercial planea campañas para las temporadas ALTA y necesita cada una con sus fechas y su duración en días, **contando el primero y el último**. Ordénalas por fecha de inicio.

**Columnas esperadas, en este orden:** `temporada`, `desde`, `hasta`, `dias`.

### Q-03 · ¿Qué carros podemos ofrecer ya mismo?

El call center necesita la lista de vehículos `DISPONIBLE` con lo que el cliente pregunta: marca, modelo, categoría y dónde está (sede y ciudad). Ordena por categoría, en el orden del tarifario (de Económico a Lujo), y luego por placa.

**Columnas esperadas, en este orden:** `placa`, `marca`, `modelo`, `categoria`, `sede`, `ciudad`.

### Q-04 · ¿Qué contratos abiertos están atrasados o por vencer?

El jefe de operaciones revisa cada lunes los contratos `ABIERTO`. Para cada uno quiere el cliente, la placa, el modelo, la sede donde se recogió, el fin esperado, cuántos días faltan para la devolución contados desde la fecha de corte (negativo si ya está atrasado) y cuántos conductores adicionales tiene. Un contrato sin conductores adicionales también debe aparecer. Primero los más atrasados; desempata por número de contrato.

**Columnas esperadas, en este orden:** `contrato`, `cliente`, `placa`, `modelo`, `sede_recogida`, `fin_esperado`, `dias_para_devolver`, `conductores_adicionales`.

### Q-05 · ¿Qué sedes recaudan más?

Finanzas quiere saber cuánto dinero han traído los contratos según la **sede donde se recogió** el carro: cuántos contratos con pagos hay por sede y la suma de esos pagos. Solo le interesan las sedes que superan los 2.000.000. Un contrato con varios pagos cuenta **una sola vez**. Ordena de más a menos recaudo y desempata por nombre de sede.

**Columnas esperadas, en este orden:** `sede`, `contratos`, `recaudado`.

### Q-06 · ¿Qué modelos tenemos en el catálogo sin un solo carro?

Compras va a negociar con los concesionarios y quiere saber qué modelos están registrados pero no tienen ningún vehículo en la flota. Ordena por marca y modelo.

**Columnas esperadas, en este orden:** `marca`, `modelo`.

### Q-07 · ¿Qué clientes no podrían manejar hoy?

Antes de la temporada alta, el área comercial quiere llamar a los clientes que **no tienen ninguna licencia vigente** a la fecha de corte, para que la renueven. Un cliente con una licencia vencida y otra vigente **no** debe aparecer. Ordénalos en el orden en que se registraron en la base.

**Columnas esperadas, en este orden:** `id`, `cliente`.

### Q-08 · ¿Qué carros siguen libres para diciembre?

Para armar la promoción de diciembre, comercial necesita los vehículos `DISPONIBLE` que **no tienen ninguna reserva viva** que comparta al menos un día con el periodo del 1 al 31 de diciembre de 2026\. Una reserva que empieza en noviembre y termina en diciembre sí cuenta. Ordena por placa.

**Columnas esperadas, en este orden:** `placa`, `modelo`, `sede`.

### Q-09 · ¿Qué vehículos nos están costando más en el taller?

La gerencia sospecha que unos pocos carros se llevan la mayor parte del presupuesto de mantenimiento. Calcula el gasto total de mantenimiento de cada vehículo que ha ido al taller y muestra solo los que superan el **promedio de gasto por vehículo**. Ordena de mayor a menor gasto. Puedes resolverla con una tabla derivada o con una CTE.

**Columnas esperadas, en este orden:** `placa`, `gasto`.

En una segunda consulta muestra el promedio con el que comparaste, cuántos vehículos entraron en el cálculo y cuántos de ellos tenían gasto conocido: `promedio_por_vehiculo`, `vehiculos`, `con_gasto`. ¿Los mantenimientos en curso afectan el promedio? Explícalo en un comentario.

### Q-10 · ¿Cuál es el carro más rodado de cada categoría?

El jefe de flota decide qué vehículo vender primero en cada categoría: el de **mayor kilometraje**. Si una categoría no tiene vehículos, explica en un comentario por qué no aparece. Ordena por categoría, en el orden del tarifario.

**Columnas esperadas, en este orden:** `categoria`, `placa`, `kilometraje`.

### Q-11 · ¿Cuánto dejan los extras?

Mercadeo quiere saber qué extras se venden y cuánto han generado. Por cada extra del catálogo (incluidos los que nadie ha alquilado, con 0): en cuántos contratos está y cuánto ha generado, calculado como cantidad × **precio pactado** × noches del contrato. Las noches salen de la fecha real de devolución o, si el contrato sigue abierto, de la fecha esperada. Ordena de más a menos ingresos y desempata por nombre.

**Columnas esperadas, en este orden:** `extra`, `contratos`, `ingresos`.

### Q-12 · ¿Qué daños hemos encontrado?

La aseguradora pide el listado de todos los daños registrados en las inspecciones, con el contrato, la placa, el cliente, la etapa de la inspección, la descripción del daño, su severidad, el costo y si se le cobra al cliente (`Sí` o `No`). Ordena por contrato y, dentro de cada contrato, en el orden en que se registraron los daños.

**Columnas esperadas, en este orden:** `contrato`, `placa`, `cliente`, `etapa`, `dano`, `severidad`, `costo`, `se_cobra`.

---

## Fase 5 · DQL avanzado: funciones, procedimientos y permisos

Escribe `04_dql_avanzado.sql`. Reglas: `DROP … IF EXISTS` antes de cada `CREATE`, delimitador `$$`, prefijos `fn_`, `sp_`, `p_` (parámetros) y `v_` (variables), mensajes de error de negocio en español con `SQLSTATE '45000'`. **No** se piden triggers ni eventos.

### 5.1 Funciones

Cada función declara **explícitamente** si es determinista o no y si lee datos o no. En un comentario sobre cada una, justifica en una línea por qué elegiste esas características.

**Antes de empezar: `fn_prueba_1418`.** Intenta crear una función mínima que solo devuelva 1, **sin declarar ninguna característica**, y deja el error comentado. ¿Qué te está pidiendo MySQL y por qué?

| Función | Recibe | Devuelve | Qué valida y hace |
| :---- | :---- | :---- | :---- |
| `fn_edad_conductor` | Fecha de nacimiento y fecha de referencia | La edad **cumplida** en esa fecha (número entero) | La fecha de referencia **siempre** llega como parámetro; la función no consulta el reloj del servidor. |
| `fn_valor_alquiler` | Categoría, fecha de recogida y fecha de devolución | El valor del alquiler según la regla 8 | Recorre las noches una por una. Si la devolución no es posterior a la recogida, falla con *La fecha final debe ser posterior a la inicial*. Si un día no tiene temporada o tarifa, falla con *No hay temporada o tarifa para el día AAAA-MM-DD* (el día que falló). |
| `fn_licencia_vigente` | Cliente y fecha | Verdadero o falso | Verdadero si el cliente tiene **alguna** licencia vigente en esa fecha (regla 11). |

**Casos de prueba**

| Función | Llamada | Resultado esperado |
| :---- | :---- | :---- |
| `fn_edad_conductor` | Nacido el 2004-07-15, al 2026-07-14 | 21 |
| `fn_edad_conductor` | Nacido el 2004-07-15, al 2026-07-15 | 22 |
| `fn_valor_alquiler` | Económico, del 2026-11-27 al 2026-12-02 | 620.000 (4 noches BAJA \+ 1 MEDIA) |
| `fn_valor_alquiler` | Van, del 2026-12-18 al 2026-12-23 | 2.300.000 |
| `fn_valor_alquiler` | SUV, del 2026-10-08 al 2026-10-12 | 1.080.000 |
| `fn_valor_alquiler` | Lujo, del 2026-12-14 al 2026-12-16 | 1.202.500 (una noche MEDIA \+ una ALTA, ya con el alza de la fase 3\) |
| `fn_valor_alquiler` | Económico, del 2026-12-05 al 2026-12-05 | ❌ *La fecha final debe ser posterior a la inicial* |
| `fn_valor_alquiler` | Económico, del 2027-01-14 al 2027-01-18 | ❌ *No hay temporada o tarifa para el día 2027-01-16* |
| `fn_licencia_vigente` | Jorge Arango, al corte | Verdadero (aunque una de sus licencias esté vencida) |
| `fn_licencia_vigente` | Paola Quintero, al corte y al 2026-12-15 | Verdadero y falso |
| `fn_licencia_vigente` | Esteban Rueda y Laura Benítez, al 2026-12-15 | Falso |

**Usa las funciones en consultas:**

- Los clientes **menores de 25 años** al corte, con su edad y si pueden alquilar un SUV (23) o una Camioneta 4x4 o Van (25), del más joven al mayor. **Columnas esperadas:** `cliente`, `nacimiento`, `edad`, `puede_suv`, `puede_4x4_o_van` (`Sí`/`No`).  
- Los clientes que **no** podrían manejar el 2026-12-15, mostrando también si tienen licencia vigente al corte. **Columnas esperadas:** `id`, `cliente`, `vigente_al_corte`, `vigente_15_dic`.

### 5.2 Procedimientos

**`sp_crear_reserva`**

- **Recibe:** el cliente, el vehículo, la sede de recogida, la sede de devolución, la fecha de recogida y la fecha de devolución. **Devuelve** (parámetro de salida): el número de la reserva creada.  
- **Valida, en este orden**, y se detiene en la primera que falle:

| Orden | Validación | Mensaje |
| :---- | :---- | :---- |
| 1 | El cliente existe | *El cliente no existe* |
| 2 | El cliente no está bloqueado | *El cliente está bloqueado* |
| 3 | La devolución es posterior a la recogida | *La devolución debe ser posterior a la recogida* |
| 4 | El vehículo existe | *El vehículo no existe* |
| 5 | El vehículo no está fuera de servicio | *El vehículo está fuera de servicio* |
| 6 | No hay otra reserva viva del vehículo que comparta un día (regla 14\) | *El vehículo ya está reservado en esas fechas* |
| 7 | Edad mínima de la categoría el día de la recogida (usa `fn_edad_conductor`) | *El cliente tiene N años y la categoría exige M* |
| 8 | Licencia vigente hasta el día de la devolución (usa `fn_licencia_vigente`) | *El cliente no tiene licencia vigente durante todo el alquiler* |

- **Hace:** registra la reserva `PENDIENTE` con el valor cotizado que calcula `fn_valor_alquiler`.

| \# | Llamada | Debe |
| :---- | :---- | :---- |
| 1 | Jorge Arango, Hilux HLX701, El Poblado → El Poblado, del 2026-12-19 al 2026-12-22 | ✅ Funcionar: reserva `PENDIENTE` cotizada en 1.290.000 (3 noches ALTA de 4x4) |
| 2 | Carlos Mejía, Kwid KWD101, Calle 26 → Calle 26, del 2026-11-30 al 2026-12-04 | ❌ Fallar por cruce con la reserva de Juliana Patiño |
| 3 | Juliana Patiño, Sportage SPT602, Aeropuerto JMC → Aeropuerto JMC, del 2026-12-12 al 2026-12-14 | ❌ Fallar por edad (22 años; SUV exige 23\) |
| 4 | Paola Quintero, Kwid KWD102, El Dorado → El Dorado, del 2026-12-08 al 2026-12-12 | ❌ Fallar por licencia (vence el 10 de diciembre) |
| 5 | Martha Cifuentes, Kwid KWD102, del 2026-12-01 al 2026-12-03 | ❌ Fallar: cliente bloqueada |
| 6 | Andrea Salazar, Kwid KWD103, Cali Granada → Cali Granada, del 2026-12-01 al 2026-12-03 | ❌ Fallar: vehículo fuera de servicio |

> 💡 Revisa por qué el caso 2 solo puede fallar por el cruce: Carlos Mejía tiene la edad y la licencia en regla.

**`sp_cerrar_contrato`**

- **Recibe:** el contrato y la fecha de cierre. **Devuelve** (parámetro de salida): el saldo por cobrar.  
- **Valida, en este orden:**

| Orden | Validación | Mensaje |
| :---- | :---- | :---- |
| 1 | El contrato existe | *El contrato no existe* |
| 2 | Está `ABIERTO` | *El contrato no está abierto* |
| 3 | Tiene la devolución registrada | *El contrato no tiene devolución registrada* |
| 4 | Tiene la inspección de devolución | *Falta la inspección de devolución* |
| 5 | La fecha de cierre es posterior al inicio | *La fecha de cierre debe ser posterior al inicio* |

- **Hace:** todo lo de la regla 23 (recalcula el alquiler con `fn_valor_alquiler`, extras con el precio pactado, daños cobrables, depósito aplicado o liberado, pago `DAÑOS` por `DEPOSITO` si aplica, vehículo y contrato actualizados) y devuelve el saldo. No hace `COMMIT` por su cuenta: quien lo llama decide.

| \# | Caso | Debe |
| :---- | :---- | :---- |
| 1 | Cerrar un contrato que ya está cerrado | ❌ *El contrato no está abierto* |
| 2 | Cerrar el contrato de Carlos Mejía, que aún no ha devuelto el carro | ❌ *El contrato no tiene devolución registrada* |
| 3 | Registrar la devolución del Onix de **Ricardo Lozano** (Bogotá Calle 26, 2026-11-21 10:00, 30.910 km, tanque lleno) y su inspección sin novedades (10:10), y cerrar con fecha 2026-11-21 | ✅ Saldo **60.000** (4 noches de GPS al precio pactado). Contrato `CERRADO` con alquiler 600.000; ONX301 `DISPONIBLE` en Calle 26 con 30.910 km; depósito `LIBERADO` |

### 5.3 Usuarios, roles y privilegios

Implementa la **regla 24**:

1. Un **rol** por perfil (`rol_asesor_flotaya`, `rol_taller_flotaya`, `rol_auditor_flotaya`) con exactamente los privilegios de la matriz: de tabla, de **columna** cuando la matriz habla de ciertos datos y de **rutina** para lo que el asesor ejecuta (el procedimiento de reservas y la función de cotización).  
2. Las cuentas **`asesor_flotaya`**, **`taller_flotaya`** y **`auditor_flotaya`**, en `localhost`, con la clave de práctica `Practica_2026*`, cada una con su rol **activo al conectarse**.  
3. Revisa los privilegios del rol del taller y compara lo que muestra la cuenta del asesor con y sin su rol.  
4. El script se puede repetir: borrar la base no borra cuentas ni roles.

**Pruebas de acceso.** Abre en Workbench **una conexión por cuenta** (`127.0.0.1`, su usuario y su clave). Guarda lo que ejecutes en `04_dql_avanzado.sql`, en secciones comentadas (`-- Como asesor_flotaya`…), y deja una **captura por cuenta** en `evidencias/` donde se vean una operación permitida y un error. En cada cuenta, muestra primero quién eres y qué rol tienes activo, y qué tablas ves.

| Cuenta | Debe poder | Debe fallar |
| :---- | :---- | :---- |
| `asesor_flotaya` | Crear con el procedimiento una reserva de **Sofía Herrera** en la Sportage SPT602, Aeropuerto JMC → Aeropuerto JMC, del 2026-12-12 al 2026-12-15 (cotizada en 810.000), y confirmarla | Ver los pagos (1142) · Borrar esa reserva (1142) · Contar las licencias (1142) |
| `taller_flotaya` | Cerrar el cambio de embrague de la **HLX702** (terminó el 2026-11-23, costó 1.850.000) y dejarla `DISPONIBLE`; registrar un mantenimiento PREVENTIVO terminado de *Alineación y balanceo* para la SPT602 en el Taller FlotaYa Bogotá (2026-11-23, 120.000) | Ver todos los datos de los vehículos (1142) · Cambiar el kilometraje de la HLX702 (1143) · Contar los contratos (1142) |
| `auditor_flotaya` | Ver los pagos del contrato de **Emma Walker** sin los datos del medio de pago; contar los contratos por estado | Ver los últimos 4 dígitos de las tarjetas (1143) · Ver todos los datos de los pagos (1142) · Cambiar el estado de un contrato (1142) · Contar los clientes (1142) |

**Responde en comentarios:**

1. El asesor creó una reserva que valida licencias, pero no puede leer las licencias. ¿Cómo es posible? ¿Qué característica del procedimiento lo permite y qué riesgo tiene?  
2. ¿Por qué pedir **todos** los datos de los pagos da un error distinto (1142) que pedir solo los últimos 4 dígitos (1143)?  
3. ¿Qué pasa si una cuenta tiene el rol asignado pero no activo al conectarse?

---

## Fase 6 · TCL

Escribe `05_tcl.sql`. Cada operación va en **una sola transacción**, con un `SELECT` **antes** que muestre el estado inicial y otro **después** que muestre el estado final.

### 6.1 Cierre del contrato de Paola Quintero (con `SAVEPOINT`)

Paola devuelve la Sportage **SPT601** el **2026-11-23**, un día tarde, en el Aeropuerto El Dorado.

1. Registra la devolución (09:30, 12.480 km, tanque lleno, la recibe un inspector de la sede) y la inspección de devolución (09:40, exterior con novedad: *Rin delantero izquierdo rayado*).  
2. Guarda el número de la inspección en una variable **antes** de seguir.  
3. Marca un punto de guardado.  
4. Registra el daño (LEVE, cobrable) **por error** en 3.800.000. Míralo.  
5. Deshaz **solo** ese error y registra el daño bien: 380.000.  
6. Cierra el contrato con `sp_cerrar_contrato`.  
7. Cobra el saldo con tarjeta (concepto `CIERRE`, últimos dígitos `3307`, autorización `AUT-580114`, 10:00) y confirma.

**Resultado esperado:** el daño equivocado se ve con 3.800.000 y desaparece al volver al punto de guardado. Saldo del cierre **750.000**: 8 noches BAJA de SUV (1.840.000) \+ extras (65.000 × 8 \= 520.000) \+ daño (380.000) − pagado (1.610.000 \+ 380.000 del depósito). Al final: contrato `CERRADO` con alquiler 1.840.000; SPT601 `DISPONIBLE` con 12.480 km; depósito `APLICADO` por 380.000; tres pagos (`ALQUILER`, `DAÑOS` por `DEPOSITO` y `CIERRE`) y **un solo** daño en esa inspección.

> 💡 Pregunta para tu comentario: ¿qué habría pasado si, en el segundo registro del daño, usabas el último id generado en lugar de la variable del paso 2?

### 6.2 Un cierre que debe deshacerse completo

**Carlos Mejía** devuelve el Mazda 2 **MZD402** el **2026-11-23** en el Aeropuerto JMC: devolución a las 18:00 con 26.950 km y tanque a la mitad, inspección sin novedades a las 18:10 y cierre con `sp_cerrar_contrato`. El asesor intenta cobrar el saldo **con cheque**.

**Resultado esperado:** saldo **970.000** (5 noches BAJA de Compacto \+ 44.000 × 5 de extras − 0 pagado); el pago con cheque **falla**. Muestra el contrato y el vehículo **dentro** de la transacción (`CERRADO`, `DISPONIBLE`), deshaz **toda** la transacción y vuelve a mirarlos: contrato `ABIERTO`, vehículo `ALQUILADO`, depósito `RETENIDO`, **sin** devolución ni inspección de devolución. Nada quedó a medias.

### 6.3 Auditoría de consistencia

En una sola consulta, después de las dos operaciones: vehículos `ALQUILADO` sin contrato abierto, contratos cerrados sin devolución, depósitos `RETENIDO` de contratos cerrados, contratos abiertos y número total de pagos. Las tres primeras columnas deben dar **0** (regla 23).

**Columnas esperadas, en este orden:** `alquilados_sin_contrato`, `cerrados_sin_devolucion`, `depositos_retenidos_de_cerrados`, `contratos_abiertos`, `pagos`.

---

## Retos

Bonificación. Van en `06_retos.sql`, que se ejecuta después de los demás (usan tus funciones).

### R1 · ¿Cobramos según la temporada?

La gerencia sospecha que algunos asesores cotizan con la tarifa equivocada. Quiere ver las reservas cuya cotización no coincide con lo que dicen las temporadas, con la diferencia, empezando por la que más plata dejó de cobrar. Las reservas creadas con el procedimiento no deberían aparecer nunca: explica por qué.

**Columnas esperadas, en este orden:** `reserva`, `cliente`, `categoria`, `inicio`, `fin`, `cotizado`, `segun_temporada`, `diferencia`.

### R2 · ¿Quién nos debe?

Cartera necesita los contratos **cerrados** que todavía tienen saldo, con el cliente, el alquiler, los extras, los daños cobrables, lo pagado y el saldo. Ojo: un contrato con un extra, un daño y tres pagos no puede contar nada tres veces. Del saldo más alto al más bajo.

**Columnas esperadas, en este orden:** `contrato`, `cliente`, `alquiler`, `extras`, `danos`, `pagado`, `saldo`.

### R3 · ¿Quién manejó sin cumplir las reglas?

La aseguradora pide revisar **todos** los conductores de **todos** los contratos, titulares y adicionales: ¿alguno no tenía la edad mínima de la categoría el día de la recogida, o no tenía licencia vigente hasta el fin del contrato (real o, si sigue abierto, esperado)?

**Columnas esperadas, en este orden:** `contrato`, `conductor`, `rol` (`TITULAR` o `ADICIONAL`), `categoria`, `edad`, `edad_minima`, `licencia_vigente`.

---

## Entregables y rúbrica

**Entregable:** la carpeta o repositorio `taller2_apellido_nombre/` con los archivos `00` a `05` (más `06_retos.sql` si hiciste retos) y `evidencias/` (tres capturas, una por cuenta). Si es repositorio, envía el enlace y el hash del último commit antes de la hora que indique el trainer.

| Criterio | Puntos | Qué se revisa |
| :---- | :---- | :---- |
| **Diagrama y normalización** | **25** | Entidades y atributos completos (6) · PK, FK y cardinalidades con mínimo y máximo, incluidas las 1:1 y las relaciones dobles con sedes y empleados (8) · Tablas puente con sus atributos propios (4) · Justificación de 1FN–3FN con un ejemplo defectuoso y respuestas a las preguntas guía (7) |
| **DDL** | **15** | Convenciones · Todas las reglas que la estructura puede proteger, protegidas (`NOT NULL`, `UNIQUE` simples y compuestos, `CHECK`, `ENUM`, `DEFAULT`, FK, numeración 501/9001) · Tabla de reglas que no se protegen con estructura |
| **DML** | **10** | Datos obligatorios exactos y mínimos cumplidos · Casos que los datos deben contener · Operaciones del día con `SELECT` previo · 3 errores provocados comentados |
| **DQL** | **15** | 12 preguntas, 1,25 puntos cada una: resultado correcto con tus datos, columnas en el orden pedido, orden correcto y totales sin duplicar |
| **DQL avanzado** | **20** | Funciones, características justificadas y 1418 (6) · `sp_crear_reserva` y `sp_cerrar_contrato` con sus validaciones en orden y sus casos de prueba (7) · Roles, cuentas, privilegios de tabla, columna y rutina, pruebas 1142/1143 con capturas y respuestas sobre `SQL SECURITY` (7) |
| **TCL** | **10** | Cierre con `SAVEPOINT` correcto (6) · Cierre revertido completo con evidencia antes y después (4) |
| **Estilo y script reproducible** | **5** | Los archivos corren completos sobre un servidor sin la base, dos veces seguidas · Palabras clave en mayúsculas, alias en español, comentarios por pregunta |
| **Total** | **100** |  |
| Retos R1–R3 | \+3 cada uno | Bonificación que compensa puntos perdidos, sin pasar de 100 |

**Descuentos:** −10 si el script se detiene con un error no comentado · −5 si se usan temas que todavía no se han visto (triggers o eventos) · −5 si hay `UPDATE` o `DELETE` sin `WHERE`.

> Este documento propone una rúbrica; el trainer confirma si este taller se califica así o por cumplimiento.

---

La **versión guiada** (`Taller2_FlotaYa_25.md`, con el modelo de referencia de 25 tablas) se comparte **después** de que entregues tu diseño, para que compares tus decisiones con las de la referencia.