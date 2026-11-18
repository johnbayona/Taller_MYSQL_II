# Taller 1 · BiblioRed: enunciado de diseño

Esta vez **tú diseñas la base completa**. No hay modelo ni `CREATE TABLE` de partida: lees cómo funciona la red de bibliotecas, decides qué entidades necesitas y cómo se relacionan, y llevas tu diseño por todo el orden del módulo: **diagrama ER → DDL → DML → DQL → DQL avanzado (procedimientos) → TCL**. Al final, tu base debe poder responder las preguntas del negocio y proteger sus reglas, tanto por la estructura como con procedimientos almacenados.

**Información general**

| | |
|---|---|
| Modalidad | Individual |
| Cuándo se usa | Sesión 2 de MySQL II (procedimientos almacenados), como versión de diseño del Taller 1 |
| Herramientas | MySQL 8.0.16 o superior y Workbench. Diagrama en Mermaid, DrawSQL o Workbench |
| Tamaño orientativo | Tu modelo debería quedar entre **13 y 17 tablas**; el modelo de referencia tiene **15** |
| Base de datos | `bibliored` |
| Fecha de corte | **`2026-11-10`** (fija en todo el taller) |
| Temas permitidos | Todo MySQL I y, de MySQL II, **solo procedimientos almacenados**. No uses funciones propias, triggers, eventos ni usuarios: todavía no se han visto. No necesitas CTE |

> ⚠️ **No es BiblioNet.** El caso "BiblioNet" de la guía de MySQL I era una biblioteca **en línea** con reseñas y un solo catálogo. BiblioRed es una red **física** de cinco sedes: cada libro existe como **ejemplares** en una sede, los socios tienen **membresías** con topes y las demoras generan **multas**.

> Escenario empresarial ficticio: los nombres de la red, las personas, los autores, las editoriales y los ISBN no identifican entidades reales.

## Contenido

- [Cómo trabajar](#cómo-trabajar)
- [Contexto del negocio](#contexto-del-negocio)
- [Reglas de negocio](#reglas-de-negocio)
- [Fase 1 · Diagrama ER y normalización](#fase-1--diagrama-er-y-normalización)
- [Fase 2 · DDL](#fase-2--ddl)
- [Fase 3 · DML](#fase-3--dml)
- [Fase 4 · DQL](#fase-4--dql)
- [Fase 5 · DQL avanzado: procedimientos](#fase-5--dql-avanzado-procedimientos)
- [Fase 6 · TCL](#fase-6--tcl)
- [Retos](#retos)
- [Entregables y rúbrica](#entregables-y-rúbrica)

---

## Cómo trabajar

1. **Lee todo el documento antes de dibujar.** Subraya los sustantivos (candidatos a entidad), los verbos entre ellos (candidatos a relación) y todo lo que tenga un "solo", "único", "como máximo" o "no puede" (candidatos a restricción).
2. Trabaja **en orden**: no escribas DDL hasta tener el diagrama, ni consultas hasta tener datos. Si en una fase descubres un error de diseño, vuelve atrás, corrígelo y deja una nota en el diagrama.
3. Organiza tu entrega en una carpeta o repositorio `taller1_apellido_nombre/` con estos archivos numerados:

| Archivo | Contenido |
|---|---|
| `00_diagrama.md` o `00_diagrama.png` | Diagrama ER, cardinalidades y justificación de la normalización (si entregas `.png`, agrega el `.md` con la justificación) |
| `01_ddl.sql` | Base, tablas y restricciones |
| `02_dml.sql` | Datos, `UPDATE`/`DELETE` y errores provocados |
| `03_dql.sql` | Respuestas Q-01 a Q-12 |
| `04_dql_avanzado.sql` | Procedimientos y sus pruebas |
| `05_tcl.sql` | Operaciones "todo o nada" |

4. **Script reproducible.** Los archivos `01` a `05`, ejecutados en orden, deben correr completos sobre un servidor sin la base. `01_ddl.sql` empieza así:

```sql
DROP DATABASE IF EXISTS bibliored;
CREATE DATABASE bibliored;
USE bibliored;
```

5. Cada respuesta lleva un comentario con su código (`-- Q-01`, `-- sp_prestar_ejemplar · prueba 3`…). Las sentencias que **deben fallar** van precedidas de `-- ⚠️ ESPERADO: ERROR <código> …`; ejecútalas solas (Ctrl + Enter sobre la línea) para que Workbench no detenga el resto.

> 💡 Workbench trae *Safe Updates* activo: un `UPDATE` o `DELETE` cuyo `WHERE` no use una columna con índice da **1175**. Filtra por la clave primaria. Eso también aplica **dentro** de los procedimientos.

---

## Contexto del negocio

> *Habla Patricia Lemus, coordinadora de BiblioRed Sabana Centro.*

"Somos la red de bibliotecas públicas de cinco municipios de la Sabana de Bogotá. Compramos **títulos** a varias **editoriales**, los clasificamos por **categoría** y registramos a sus **autores**; muchos libros tienen un solo autor, pero algunos los escribieron dos personas y nos importa quién figura primero. De cada título compramos uno o varios **ejemplares** físicos y los repartimos entre las sedes; cada ejemplar lleva un código de barras pegado en el lomo, y así sabemos en qué sede está y en qué estado se encuentra.

Los vecinos se afilian como **socios** en una sede. Al afiliarse eligen una **membresía**, y la membresía decide todo: cuántos libros pueden tener a la vez, por cuántos días, cuántas veces pueden renovar y cuánto pagan de multa por cada día de retraso. Cada préstamo lo registra un empleado de la sede. Si alguien no puede ir por un libro que está prestado, puede **reservar** la obra para recogerla en la sede que prefiera.

Cuando un libro vuelve tarde, cobramos una **multa por mora**; si se pierde, cobramos lo que nos cuesta reponerlo. Mucha gente paga las multas por cuotas, así que necesitamos saber cuánto se ha abonado y cuánto falta. Y hay algo que nos ha pasado más de una vez con las planillas en papel: un libro aparece como prestado en el estante, pero nadie sabe a quién. Eso no puede volver a ocurrir."

**Las sedes**

| Sede | Municipio | Abrió | Lo que hay que saber |
|---|---|---|---|
| Sede Central Chía | Chía | 2012 | La más grande: tiene la mayor cantidad de ejemplares y allí trabaja la coordinadora de la red |
| Sede Cajicá | Cajicá | 2015 | Tiene préstamos activos que ya están vencidos |
| Sede Zipaquirá | Zipaquirá | 2017 | Guarda el ejemplar más antiguo de la red (adquirido en 2011) |
| Sede Cota | Cota | 2020 | Perdió un ejemplar de *Átomos para curiosos* |
| Sede Tabio | Tabio | octubre de 2026 | Recién abierta: tiene un auxiliar y un socio, pero **ningún** ejemplar |

**Las membresías**

| Membresía | Préstamos a la vez | Días de préstamo | Renovaciones | Multa por día | Cuota anual |
|---|---|---|---|---|---|
| Básica | 2 | 14 | 1 | $500 | $0 |
| Estudiante | 3 | 14 | 2 | $300 | $0 |
| Docente | 5 | 21 | 2 | $300 | $30.000 |
| Infantil | 2 | 7 | 1 | $200 | $0 |
| Institucional | 10 | 30 | 3 | $1.000 | $250.000 |

**Las categorías del catálogo:** Novela, Cuento, Poesía, Historia, Ciencia, Infantil, Referencia y Cómic (esta última todavía no tiene títulos).

---

## Reglas de negocio

Los valores en MAYÚSCULAS son datos del negocio: úsalos tal cual.

**Sedes y personal**

1. La red tiene varias sedes. Cada sede tiene un nombre único, el municipio, la dirección y la fecha en que abrió.
2. Cada empleado trabaja en **una sola** sede y una sede puede tener varios empleados. Del empleado se guarda el nombre completo, un correo único, la fecha de contratación y su rol: `COORDINADOR`, `BIBLIOTECARIO` o `AUXILIAR`. Si no se indica el rol, es `BIBLIOTECARIO`.

**Catálogo**

3. Un **título** es la obra: tiene un ISBN único, el nombre, el año de publicación, **una** categoría, **una** editorial y un costo de reposición. Si al catalogarlo no se informa el costo de reposición, se asume **$50.000**.
4. Las categorías y las editoriales tienen nombre único; de la editorial se guarda además la ciudad. Puede haber categorías y editoriales sin títulos.
5. De cada autor se guarda el nombre completo, la nacionalidad y el año de nacimiento. Un título puede tener varios autores y un autor puede haber escrito varios títulos. En cada título, los autores tienen un **orden de autoría** (1, 2…): el mismo autor no puede figurar dos veces en un título y dos autores no pueden ocupar el mismo lugar.
6. Un **ejemplar** es un libro físico de un título, ubicado en **una** sede, con un código de barras único y la fecha en que se adquirió. Su estado es `DISPONIBLE` (al llegar), `PRESTADO`, `EN_REPARACION`, `PERDIDO` o `DADO_DE_BAJA`.

**Socios**

7. Cada membresía tiene un nombre único, el tope de préstamos a la vez, los días de préstamo, las renovaciones permitidas, la multa por día y la cuota anual. El tope y los días son mayores que 0; las renovaciones y la multa por día, 0 o más.
8. Un **socio** tiene un número de documento único, nombres, apellidos, correo (si lo tiene, único), teléfono, fecha de nacimiento, fecha de afiliación, **una** membresía y **una** sede de afiliación. Su estado es `ACTIVO` (al afiliarse), `SUSPENDIDO` o `INACTIVO`. Los socios menores de edad pueden no tener correo ni teléfono.

**Circulación**

9. Un **préstamo** entrega un ejemplar a un socio y lo registra un empleado. Guarda la fecha del préstamo, la fecha de vencimiento y la fecha de devolución, que queda vacía mientras el libro no vuelva. Su estado es `ACTIVO` (al prestarse), `DEVUELTO` o `PERDIDO`. Los préstamos se numeran **desde el 1001**.
10. El vencimiento es la fecha del préstamo más los días de préstamo de la membresía del socio. El vencimiento siempre es posterior a la fecha del préstamo, y la devolución, si existe, no puede ser anterior a ella.
11. Solo se presta un ejemplar `DISPONIBLE` a un socio `ACTIVO`, **sin multas pendientes** y que no haya llegado al **tope** de préstamos activos de su membresía.
12. El préstamo y el estado del ejemplar van **juntos**: no puede existir un ejemplar `PRESTADO` sin un préstamo `ACTIVO` de ese ejemplar, ni al revés. Al devolverse, el ejemplar vuelve a `DISPONIBLE`.
13. Un préstamo está **vencido** cuando la fecha de referencia es posterior a su vencimiento. El mismo día del vencimiento todavía no está vencido.
14. Cada **renovación** suma otra vez los días de préstamo de la membresía al vencimiento actual. De cada renovación se conserva la fecha en que se hizo, el vencimiento anterior y el nuevo, que siempre es posterior al anterior.
15. Un préstamo se renueva solo si está `ACTIVO`, **no está vencido**, no ha agotado las renovaciones de la membresía y **nadie tiene una reserva `PENDIENTE` de ese título**, en cualquier sede.
16. Una **reserva** la hace un socio sobre un **título** (no sobre un ejemplar concreto), para recogerlo en una sede que él elige. Tiene fecha de reserva y fecha de expiración, que no puede ser anterior a la de reserva. Su estado es `PENDIENTE` (al crearse) hasta su expiración; luego queda `ATENDIDA`, `CANCELADA` o `VENCIDA`. Una reserva `PENDIENTE` cuya expiración ya pasó debe quedar `VENCIDA`.

**Multas**

17. Toda multa nace de un préstamo. Su motivo es `MORA`, `DAÑO` o `PERDIDA`, y su estado `PENDIENTE` (al generarse), `PAGADA` o `ANULADA`. Guarda los días de retraso (0 si no aplica), el valor, que siempre es mayor que 0, y la fecha en que se generó.
18. Al devolver un libro tarde se genera una multa `MORA` = días de retraso × multa por día de la membresía del socio. El valor de una multa **no cambia** si después la red cambia la tarifa.
19. Un libro perdido deja el préstamo y el ejemplar como `PERDIDO` y genera una multa `PERDIDA` por el costo de reposición del título.
20. Una multa se paga en **una o varias cuotas**. Cada cuota tiene un valor mayor que 0, la fecha y el medio de pago: `EFECTIVO`, `TARJETA` o `TRANSFERENCIA`. Ninguna cuota puede superar lo que falta por pagar. La multa queda `PAGADA` cuando sus cuotas suman su valor.
21. La red puede **anular** una multa (`ANULADA`): una multa anulada no se cobra ni cuenta en ningún saldo.

**Generales**

22. No se puede eliminar una sede, editorial, categoría, autor, título, ejemplar, socio o préstamo mientras otros registros dependan de él.
23. Todas las fechas de referencia del taller usan la fecha de corte **`2026-11-10`**, nunca la fecha del sistema.

---

## Fase 1 · Diagrama ER y normalización

Entrega en `00_diagrama`:

- **Entidades** con todos sus atributos, la **PK** de cada una y sus **FK**.
- **Cardinalidades** en ambos sentidos, con participación mínima y máxima (0..1, 1..1, 0..N, 1..N). Escribe cada relación en una frase: "una sede *emplea* a muchos empleados; un empleado *trabaja en* una sola sede".
- Las **tablas puente** que resuelven las relaciones N:M, con sus atributos propios si los tienen.
- Una **justificación breve de 1FN, 2FN y 3FN**: para cada forma normal, muestra un ejemplo de cómo quedarían mal los datos de BiblioRed y cómo lo resuelve tu diseño. Indica si hace falta algo para 4FN o por qué no.
- La lista de reglas que **no** se pueden proteger solo con PK, FK, `UNIQUE`, `CHECK` o `NOT NULL` (las resolverás en la fase 5).

**Preguntas guía.** Respóndelas con tu diagrama, no con texto suelto:

1. ¿El libro que está en el estante y la obra que aparece en el catálogo son la misma cosa? ¿Qué se repetiría si la red tiene tres copias de la misma obra en dos sedes y las guardas como una sola cosa?
2. En *Cuentos de la Sabana* hay un primer y un segundo autor. ¿Ese "primero" o "segundo" es un dato del autor, del título o de otra cosa?
3. Si mañana la red sube la multa por día de la membresía Básica, ¿cuántos registros deberías cambiar en tu diseño? Si la respuesta es "uno por socio", algo está mal ubicado.
4. ¿Dónde guardas el valor de una multa para que no cambie si mañana cambia la tarifa?
5. Una multa pertenece a un socio. ¿Necesitas guardar el socio en la multa o ya puedes llegar a él por otro camino? ¿Qué pasaría si los dos caminos dijeran personas distintas?
6. Si una renovación solo sobrescribe la fecha de vencimiento, ¿cómo sabrías cuántas veces se renovó un préstamo y cuál era el vencimiento anterior?
7. ¿Cómo sabes cuánto le falta por pagar a una multa sin mantener a mano un "saldo" que alguien pueda olvidar actualizar?
8. Cuando un socio reserva, ¿reserva un ejemplar o la obra? ¿Y la sede de la reserva es la misma que su sede de afiliación?

**Casos que tu diseño debe permitir**

| # | Caso | ¿Se acepta? |
|---|---|---|
| 1 | Registrar un título escrito por dos autores, indicando quién es el primero y quién el segundo | ✅ Sí |
| 2 | Tener tres ejemplares del mismo título repartidos en dos sedes | ✅ Sí |
| 3 | Una sede recién abierta con un empleado y un socio, pero sin ejemplares | ✅ Sí |
| 4 | Afiliar a un niño sin correo ni teléfono | ✅ Sí |
| 5 | Renovar dos veces un préstamo y consultar después los dos vencimientos anteriores | ✅ Sí |
| 6 | Pagar una multa en dos cuotas, con medios de pago distintos | ✅ Sí |
| 7 | Registrar una multa anulada que no cuente en el saldo del socio | ✅ Sí |
| 8 | Reservar una obra para recogerla en una sede distinta a la de afiliación del socio | ✅ Sí |
| 9 | Dos ejemplares con el mismo código de barras | ❌ Debe rechazarse |
| 10 | El mismo autor dos veces en el mismo título, o dos autores en el mismo lugar de autoría | ❌ Debe rechazarse |
| 11 | Un ejemplar en estado `EXTRAVIADO` | ❌ Debe rechazarse |
| 12 | Una cuota de $0 | ❌ Debe rechazarse |
| 13 | Un préstamo cuyo vencimiento sea el mismo día del préstamo o anterior | ❌ Debe rechazarse |
| 14 | Una reserva de un socio que no existe | ❌ Debe rechazarse |
| 15 | Eliminar una editorial que tiene títulos | ❌ Debe rechazarse |
| 16 | Prestar un ejemplar a un socio `SUSPENDIDO` | ❌ Debe rechazarse (fase 5) |
| 17 | Renovar un préstamo cuando otro socio tiene una reserva pendiente de ese título | ❌ Debe rechazarse (fase 5) |
| 18 | Un ejemplar `PRESTADO` sin un préstamo `ACTIVO` | ❌ Nunca debe quedar así (fases 5 y 6) |

---

## Fase 2 · DDL

Escribe `01_ddl.sql` con el **estilo de clase**:

- Identificadores en **inglés**, minúsculas y `snake_case`; tablas en plural; FK con el nombre `<padre_en_singular>_id`. Sin tildes ni ñ en los identificadores.
- PK siempre `id BIGINT AUTO_INCREMENT PRIMARY KEY`.
- Restricciones **en línea** (`NOT NULL`, `UNIQUE`, `DEFAULT`); `CHECK` y `UNIQUE` compuestos al final de la tabla o con `ALTER TABLE … ADD`.
- FK **sin nombre**: `FOREIGN KEY (<columna>) REFERENCES <tabla>(id)`.
- Estados y catálogos cortos con `ENUM` y valores en español, en MAYÚSCULAS, con su `DEFAULT` cuando la regla lo da.
- Dinero en `DECIMAL(12,2)` (la multa por día puede ir en `DECIMAL(10,2)`); fechas en `DATE`.
- **No** escribas `CHARACTER SET utf8mb4` ni `COLLATE`.
- Tablas en orden de dependencia (primero las que no tienen FK). Cierra con `SHOW TABLES;` y un `DESCRIBE` de tu tabla de préstamos.

Ejemplo de forma (de otra base, no de la tuya):

```sql
CREATE TABLE contacts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    status ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    client_id BIGINT NOT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(id)
);
```

**Reglas que deben quedar protegidas por la estructura** (las pruebas de la fase 3 lo comprobarán):

| Tipo de protección | Reglas |
|---|---|
| Unicidad | 1, 2, 3, 4, 6, 7 y 8 (nombres, correos, ISBN, código de barras, documento) y la doble restricción de la regla 5 (autor repetido, lugar repetido) |
| Catálogo de valores y valor por defecto | Roles, estados, motivos y medios de pago de las reglas 2, 6, 8, 9, 16, 17 y 20; el costo de reposición por defecto de la regla 3 |
| Obligatoriedad | Todo lo que la regla no permite dejar vacío; correo y teléfono del socio sí pueden quedar vacíos (regla 8), igual que la fecha de devolución (regla 9) |
| Comprobación por fila | Topes y tarifas de la regla 7; fechas de las reglas 10, 14 y 16; valores de multas y cuotas de las reglas 17 y 20 |
| Relaciones | Todas las "una sede", "una membresía", "un empleado"… y la regla 22 |
| Numeración | Préstamos desde el 1001 (regla 9) |

**Reglas que no se pueden proteger así** y quedan para la fase 5 (y la 12, también para la fase 6): 10 (cálculo del vencimiento), 11, 12, 15, 18, la segunda parte de la 16 (vencer reservas) y, de la 20, el tope de la cuota y el paso a `PAGADA`. La 19 tampoco cabe en la estructura; en este taller se registra con los datos de la fase 3. Explica en un comentario al final de `01_ddl.sql` por qué cada una no cabe en un `CHECK`.

---

## Fase 3 · DML

Escribe `02_dml.sql`: todos los `INSERT` con **lista de columnas y sin escribir el `id`**, varias filas por sentencia y **fechas fijas** (nunca `NOW()` ni `CURDATE()`).

**Mínimos de datos**

| Qué | Mínimo |
|---|---|
| Sedes, membresías y categorías | Exactamente las del contexto (5, 5 y 8) |
| Empleados | 6 (al menos uno por sede) |
| Editoriales | 6 |
| Autores | 10 |
| Títulos | 14 |
| Ejemplares | 25 |
| Socios | 14 |
| Préstamos | 20, entre septiembre y noviembre de 2026 |
| Renovaciones | 3 |
| Reservas | 6 |
| Multas | 5 |
| Cuotas de multas | 4 |

**Datos obligatorios del negocio** (deben coincidir exactamente):

- Las 5 sedes con su nombre, municipio y año de apertura (Sede Tabio abrió el `2026-10-01`).
- Las 5 membresías con todos sus valores de la tabla del contexto.
- Las 8 categorías, con **Cómic** sin títulos.
- Una coordinadora de la red, **Patricia Lemus**, en la Sede Central Chía. La Sede Tabio tiene un empleado `AUXILIAR` y **un** socio afiliado, pero ningún ejemplar.
- El título ***Átomos para curiosos*** (categoría Ciencia, costo de reposición $68.000) tiene un ejemplar en la Sede Cota que se perdió en un préstamo: el préstamo y el ejemplar quedan `PERDIDO` y el socio tiene la multa `PERDIDA` de $68.000 pendiente.
- La Sede Zipaquirá guarda un ejemplar adquirido en **2011**, el más antiguo de la red.
- La Sede Cajicá tiene **dos** préstamos activos ya vencidos a la fecha de corte.
- Nadie pertenece todavía a la membresía **Institucional**.
- Todos los socios, autores, editoriales, títulos e ISBN son ficticios.

**Casos que tus datos deben contener** (para que las consultas y los procedimientos "descubran" algo):

| # | Caso |
|---|---|
| D1 | Un título sin ejemplares, un autor sin títulos y una editorial sin títulos |
| D2 | Al menos tres títulos con dos autores |
| D3 | Socios menores con membresía Infantil, sin correo ni teléfono (un vacío con significado) |
| D4 | Un socio `SUSPENDIDO` que además tiene una multa pendiente, y un socio `INACTIVO` |
| D5 | Dos socios que nunca han pedido un préstamo; uno de ellos tiene una reserva pendiente |
| D6 | Préstamos devueltos a tiempo, devueltos tarde (con su multa `MORA`), activos vencidos al corte y **dos activos que vencen exactamente el `2026-11-10`** |
| D7 | Un socio Básico con 2 préstamos activos (en el tope) y ninguna multa pendiente |
| D8 | Un préstamo activo, sin vencer al corte, que ya agotó sus renovaciones; y otro préstamo, de cualquier estado, con una sola renovación |
| D9 | Reservas en los cuatro estados; una `PENDIENTE` que ya expiró antes del corte; una `PENDIENTE` que se puede entregar (hay un ejemplar `DISPONIBLE` del título en la sede de recogida); varias `PENDIENTE` que siguen en espera; y un préstamo activo, sin vencer y sin renovaciones usadas, de un título que tiene una reserva `PENDIENTE` |
| D10 | Multas en todos los estados: una `PAGADA` en una cuota, una `PAGADA` en **dos** cuotas, una `PENDIENTE` con un abono parcial, una `PENDIENTE` sin abonos y una `ANULADA` |
| D11 | Ejemplares en los cinco estados |
| D12 | Un empate: dos socios con el mismo número máximo de préstamos en la historia |
| D13 | Algunos títulos catalogados sin informar el costo de reposición (deben quedar en $50.000) |
| D14 | Cada ejemplar `PRESTADO` con exactamente un préstamo `ACTIVO`, y viceversa |

**Además, en `02_dml.sql`:**

1. **`UPDATE` con `SELECT` previo.** Antes de cada `UPDATE`, el `SELECT` con el mismo `WHERE`; después, el `SELECT` de comprobación. Casos: un ejemplar `EN_REPARACION` vuelve al estante; las reservas `PENDIENTE` que expiraron antes del corte pasan a `VENCIDA`; la cuota anual de la membresía Docente sube 10 %; un socio registra su celular.
2. **`DELETE` con `SELECT` previo.** Borra una reserva `CANCELADA` y la editorial sin títulos (comprueba antes que no tiene títulos).
3. **Tres errores provocados, comentados**, escogidos entre los casos 9 a 15 de la fase 1 (por ejemplo: código de barras repetido, cuota de $0, estado `EXTRAVIADO`, autor repetido en un título, reserva de un socio inexistente, borrar una editorial con títulos). Anota el código de error y explica qué restricción lo produjo.
4. **Verificación final:** el conteo de filas por tabla con el resultado esperado en comentario, y una consulta que compruebe el caso D14.

---

## Fase 4 · DQL

Escribe `03_dql.sql`. Actúas como analista de la red: cada caso describe una necesidad y **no dice qué instrucciones usar**.

**Criterio general:** dinero, promedios y porcentajes con dos decimales; la fecha de referencia es el corte `2026-11-10`; cuando una consulta una varias tablas con muchos registros relacionados, comprueba que los totales no se dupliquen. Los alias que ve el usuario van en español, minúsculas y `snake_case`. Con tus datos, **cada pregunta debe devolver al menos una fila**. Se califica el resultado y el razonamiento, no una única manera de escribir SQL.

### Q-01 · ¿A qué socios no podemos llamar o no podemos atender?

La secretaría va a actualizar datos. Necesita los socios que no tienen teléfono registrado **o** que no están activos, con su estado y su teléfono (vacío si no tiene).

**Columnas esperadas, en este orden:** `id`, `socio` (nombre y apellido), `estado`, `telefono`. Orden: por `id`.

### Q-02 · ¿Qué préstamos están vencidos al corte?

La coordinadora quiere la lista de préstamos activos vencidos al `2026-11-10`, con lo que ya se debería cobrar si el libro volviera hoy: días de mora × multa por día de la membresía del socio.

**Columnas esperadas, en este orden:** `prestamo`, `socio`, `membresia`, `titulo`, `ejemplar` (código de barras), `sede` (la del ejemplar), `vence`, `dias_mora`, `multa_estimada`. Orden: del más atrasado al menos atrasado; empate por número de préstamo.

### Q-03 · ¿Qué títulos tienen coautores?

Catalogación quiere revisar las fichas de los títulos escritos por más de una persona y cuántos autores tiene cada uno.

**Columnas esperadas, en este orden:** `titulo`, `autores`. Orden: por el número del título.

### Q-04 · ¿Qué sedes tienen más movimiento?

Para repartir personal, la red compara las sedes que han hecho **5 o más préstamos** en total. La sede de un préstamo es la del ejemplar prestado. Por sede: préstamos totales, préstamos activos hoy y cuántos socios distintos ha atendido.

**Columnas esperadas, en este orden:** `sede`, `prestamos_totales`, `prestamos_activos`, `socios_distintos`. Orden: más préstamos primero; empate por nombre de sede.

> 💡 Si con tus datos ninguna sede llega a 5, revisa tus mínimos de préstamos antes de cambiar la pregunta.

### Q-05 · ¿Qué socios se afiliaron y nunca han pedido un libro?

La red quiere llamar a los socios que no han usado nunca el préstamo, para invitarlos. Incluye su fecha de afiliación.

**Columnas esperadas, en este orden:** `id`, `socio`, `afiliado_desde`. Orden: por `id`.

### Q-06 · ¿Qué tenemos en el catálogo que no se está usando?

Compras quiere, **en un solo listado**, las categorías que no tienen ningún título y los autores que no tienen ningún título en el catálogo, indicando de qué tipo es cada fila.

**Columnas esperadas, en este orden:** `tipo` (`categoria` o `autor`), `nombre`.

### Q-07 · ¿Qué socios tienen al menos una multa pendiente?

Antes de la jornada de cobro, la red necesita saber qué socios tienen **al menos una** multa `PENDIENTE`, sin repetir socios aunque tengan varias, y en qué estado está cada uno.

**Columnas esperadas, en este orden:** `id`, `socio`, `estado`. Orden: por `id`.

### Q-08 · ¿Qué reservas pendientes siguen en espera?

Una reserva `PENDIENTE` se puede entregar si hay algún ejemplar `DISPONIBLE` del título **en la sede de recogida**. Circulación quiere las que **no** se pueden entregar todavía, para avisar a esos socios que siguen en lista.

**Columnas esperadas, en este orden:** `reserva`, `socio`, `titulo`, `sede`, `expira`. Orden: por número de reserva.

### Q-09 · ¿Qué títulos son más caros de reponer que el promedio?

Seguros quiere los títulos cuyo costo de reposición supera el promedio de todo el catálogo.

**Columnas esperadas, en este orden:** `titulo`, `costo_reposicion`. Orden: del más caro al más barato; empate por título.

### Q-10 · ¿Quiénes son los socios más asiduos?

La red va a premiar al socio con **más préstamos en toda la historia**. Si hay empate, todos los empatados reciben el premio.

**Columnas esperadas, en este orden:** `id`, `socio`, `prestamos`. Orden: por `id`.

### Q-11 · ¿Cuál es el ejemplar más antiguo de cada sede?

Conservación quiere revisar, en cada sede, el ejemplar que lleva más tiempo en la red. Las sedes sin ejemplares no aparecen.

**Columnas esperadas, en este orden:** `sede`, `ejemplar`, `titulo`, `adquirido`. Orden: por sede (en el orden en que se registraron) y luego por ejemplar.

### Q-12 · ¿Cuánto debe cada socio en multas?

Tesorería quiere, por socio, el total de sus multas no anuladas, lo que ha pagado en cuotas y el saldo. Solo los que deben algo, del que más debe al que menos.

**Columnas esperadas, en este orden:** `id`, `socio`, `total_multas`, `pagado`, `saldo`. Orden: saldo de mayor a menor; empate por `id`.

> ⚠️ Revisa el socio cuya multa se pagó en **dos** cuotas (caso D10): no debe aparecer.

---

## Fase 5 · DQL avanzado: procedimientos

Escribe `04_dql_avanzado.sql`. Para todos los procedimientos:

- `DROP PROCEDURE IF EXISTS` antes de cada `CREATE`, `DELIMITER $$` … `END $$` y regreso a `DELIMITER ;`.
- Parámetros con prefijo `p_`, variables con `v_`.
- Los errores de negocio se lanzan con `SQLSTATE '45000'` (MySQL los muestra como **1644**) y el **mensaje exacto** de cada tabla. Donde el mensaje lleva un dato entre `< >`, ese dato sale de la base.
- Toda fecha llega por parámetro: nada de `NOW()` ni `CURDATE()`.
- Cada prueba lleva su comentario; las que deben fallar, con `-- ⚠️ ESPERADO: ERROR 1644 …`. Elige en tus datos los registros que cumplan cada caso y anota por qué los elegiste.

### `sp_resumen_socio`

**Recibe:** un socio. **Devuelve:** cuántos préstamos activos tiene y cuánto debe en multas `PENDIENTE` (valor de cada multa menos lo abonado).

| Validación | Mensaje |
|---|---|
| El socio existe | `El socio no existe` |

| # | Prueba | Debe |
|---|---|---|
| 1 | El socio `SUSPENDIDO` del caso D4 | Funcionar: sus préstamos activos y su saldo pendiente, con los abonos ya descontados |
| 2 | Un socio con préstamos activos y sin multas | Funcionar: saldo 0.00 |
| 3 | Un socio que no existe | Fallar: *El socio no existe* |

### `sp_prestar_ejemplar`

**Recibe, en este orden:** el ejemplar, el socio, el empleado que atiende y la fecha del préstamo. **Devuelve:** el número del préstamo creado.

Valida **en este orden** (el orden cambia el mensaje cuando un caso incumple varias reglas):

| # | Validación | Mensaje |
|---|---|---|
| 1 | El socio existe | `El socio no existe` |
| 2 | El socio está `ACTIVO` | `El socio no está activo: <estado>` |
| 3 | El ejemplar existe | `El ejemplar no existe` |
| 4 | El ejemplar está `DISPONIBLE` | `El ejemplar no está disponible: <estado>` |
| 5 | El socio no tiene multas `PENDIENTE` | `El socio tiene multas pendientes` |
| 6 | El socio no ha llegado al tope de su membresía | `El socio alcanzó su tope de <tope> préstamos` |

Si todo está bien, **primero** marca el ejemplar `PRESTADO` y **después** registra el préstamo con vencimiento = fecha + días de la membresía. El procedimiento **no** valida al empleado: esa protección es de la estructura (la fase 6 la usa).

| # | Prueba (fecha `2026-11-10`) | Debe |
|---|---|---|
| 1 | Un socio activo sin préstamos ni multas lleva un ejemplar disponible | Funcionar: préstamo nuevo, ejemplar `PRESTADO`, vencimiento correcto |
| 2 | El socio `SUSPENDIDO` de D4 (que además debe una multa) pide un ejemplar disponible | Fallar: *El socio no está activo: SUSPENDIDO* |
| 3 | Un socio activo pide un ejemplar `PRESTADO` | Fallar: *El ejemplar no está disponible: PRESTADO* |
| 4 | Un socio activo con multa pendiente pide un ejemplar disponible | Fallar: *El socio tiene multas pendientes* |
| 5 | El socio de D7 pide un ejemplar disponible | Fallar: *El socio alcanzó su tope de 2 préstamos* |
| 6 | Un socio activo pide un ejemplar que no existe | Fallar: *El ejemplar no existe* |

### `sp_devolver_ejemplar`

**Recibe:** un préstamo y la fecha de devolución. **Devuelve:** el valor de la multa generada (0 si no hubo mora).

| Validación | Mensaje |
|---|---|
| El préstamo existe | `El préstamo no existe` |
| El préstamo está `ACTIVO` | `El préstamo no está activo` |
| La devolución no es anterior a la fecha del préstamo | `La fecha de devolución es anterior al préstamo` |

Calcula los días de mora con la **fecha de devolución recibida**. Si hay mora, genera la multa `MORA` (regla 18) con esa fecha. Marca el préstamo `DEVUELTO` con su fecha de devolución y el ejemplar `DISPONIBLE`.

| # | Prueba | Debe |
|---|---|---|
| 1 | Devolver el `2026-11-10` el préstamo más atrasado de Q-02 | Funcionar: multa = días × tarifa, nueva multa `PENDIENTE` |
| 2 | Devolver el `2026-11-10` un préstamo que aún no vence | Funcionar: 0.00 y ninguna multa nueva |
| 3 | Devolver un préstamo ya `DEVUELTO` | Fallar: *El préstamo no está activo* |
| 4 | Devolver un préstamo activo con una fecha anterior a su préstamo | Fallar: *La fecha de devolución es anterior al préstamo* |

### `sp_renovar_prestamo`

**Recibe:** un préstamo y la fecha de la renovación. **Devuelve:** el nuevo vencimiento.

| # | Validación (en este orden) | Mensaje |
|---|---|---|
| 1 | El préstamo existe | `El préstamo no existe` |
| 2 | Está `ACTIVO` | `El préstamo no está activo` |
| 3 | No está vencido a la fecha de la renovación (regla 13) | `El préstamo está vencido: primero debe devolverse` |
| 4 | No agotó las renovaciones de la membresía | `El préstamo ya usó sus <renovaciones> renovaciones` |
| 5 | No hay reservas `PENDIENTE` del título | `Hay reservas pendientes para este título` |

Si todo está bien, registra la renovación (regla 14) y actualiza el vencimiento del préstamo.

| # | Prueba (fecha `2026-11-10`) | Debe |
|---|---|---|
| 1 | Un préstamo activo, al día, sin renovaciones agotadas y sin reservas del título | Funcionar: nuevo vencimiento = anterior + días, renovación registrada |
| 2 | El préstamo de D8 que agotó sus renovaciones | Fallar: *El préstamo ya usó sus <n> renovaciones* |
| 3 | Un préstamo activo vencido | Fallar: *El préstamo está vencido: primero debe devolverse* |
| 4 | El préstamo de D9 cuyo título tiene una reserva pendiente | Fallar: *Hay reservas pendientes para este título* |

### `sp_reporte_sedes`

**Recibe:** una fecha de corte. **Devuelve:** un reporte con una fila por sede, todas incluidas.

Debe **recorrer las sedes una a una con un cursor** y calcular para cada una: ejemplares en circulación (sin `PERDIDO` ni `DADO_DE_BAJA`), préstamos activos de sus ejemplares, préstamos vencidos a la fecha de corte y porcentaje de ocupación (prestados × 100 / ejemplares, con 2 decimales). Arma el reporte en una tabla temporal y al final devuélvelo con las columnas `sede`, `ejemplares`, `prestados`, `vencidos`, `ocupacion_pct`, de mayor a menor ocupación y por nombre de sede.

| # | Prueba | Debe |
|---|---|---|
| 1 | Reporte al `2026-11-10` | Funcionar: 5 filas, una por sede; los vencidos coinciden con los que siguen activos en Q-02 |
| 2 | La Sede Tabio en el mismo reporte | Aparecer con `0 | 0 | 0` y la ocupación **vacía**, sin error de división por cero |

### `sp_pagar_multa`

**Recibe:** una multa, el valor del abono, el medio de pago y la fecha. **Devuelve:** el saldo que queda.

| Validación | Mensaje |
|---|---|
| La multa existe | `La multa no existe` |
| Está `PENDIENTE` | `La multa no está pendiente` |
| El abono es mayor que 0 y no supera el saldo | `El abono debe ser mayor que 0 y no superar el saldo` |
| El medio de pago es válido | `Medio de pago no válido: use EFECTIVO, TARJETA o TRANSFERENCIA` |

Registra la cuota y, si el saldo llega a 0, marca la multa `PAGADA`. El medio de pago **no** se valida con un `IF`: lo rechaza la propia base al guardar la cuota, y el procedimiento **atrapa ese error con un handler** y lo convierte en el mensaje de la tabla.

| # | Prueba (fecha `2026-11-10`) | Debe |
|---|---|---|
| 1 | El socio de la prueba 4 de `sp_prestar_ejemplar` paga completa su multa en `EFECTIVO` (elige un socio con **una sola** multa pendiente y sin abonos) | Funcionar: saldo 0.00, multa `PAGADA` |
| 2 | Ese mismo socio repite el préstamo de la prueba 4 | Funcionar: ahora sí se presta |
| 3 | Abono parcial con `TARJETA` a la multa de D10 que ya tenía un abono | Funcionar: devuelve el saldo restante |
| 4 | Abonar a una multa `PAGADA` | Fallar: *La multa no está pendiente* |
| 5 | Abonar más que el saldo de una multa pendiente | Fallar: *El abono debe ser mayor que 0 y no superar el saldo* |
| 6 | Pagar con `'CHEQUE'` | Fallar: *Medio de pago no válido: use EFECTIVO, TARJETA o TRANSFERENCIA* |

Cierra `04_dql_avanzado.sql` listando las rutinas de tu base: deben aparecer los 6 procedimientos.

---

## Fase 6 · TCL

Escribe `05_tcl.sql`. El problema que la coordinadora no quiere repetir: un ejemplar `PRESTADO` sin préstamo (regla 12).

### T1 · El ejemplar sin ficha

**Caso que debe revertirse:** un empleado que no existe intenta prestar un ejemplar `DISPONIBLE` a un socio activo sin multas.

1. **Sin transacción:** llama a `sp_prestar_ejemplar` con ese empleado inexistente. Anota el error. Luego busca los ejemplares `PRESTADO` que **no** tienen un préstamo `ACTIVO`, explica por qué apareció uno y corrígelo con un `UPDATE` (con su `SELECT` previo).
2. **Con transacción:** repite la misma llamada después de `START TRANSACTION`. Consulta el estado del ejemplar **antes** del `ROLLBACK` y **después**.

**Evidencia:** el estado del ejemplar antes de la llamada, después del error (paso 1), dentro de la transacción y después del `ROLLBACK`. Responde en un comentario: ¿por qué en el paso 1 no se deshizo solo el cambio del ejemplar si el procedimiento falló?

### T2 · `sp_prestar_ejemplar_tx`: todo o nada

Crea `sp_prestar_ejemplar_tx`, que **recibe y devuelve lo mismo** que `sp_prestar_ejemplar`. Abre una transacción, llama a `sp_prestar_ejemplar` y confirma. Si **cualquier** cosa falla (un error de negocio o un error de MySQL), deshace todo y deja que el **mismo error** llegue a quien llamó.

| # | Caso | Debe |
|---|---|---|
| 1 | El empleado no existe | Fallar con el error de la base; el ejemplar sigue `DISPONIBLE` |
| 2 | El ejemplar está prestado | Fallar: *El ejemplar no está disponible: PRESTADO* |
| 3 | El préstamo correcto, con un empleado que sí existe | Funcionar: préstamo nuevo y ejemplar `PRESTADO` |

**Evidencia:** el número de préstamos **antes** y **después** de las tres llamadas, el estado del ejemplar después del caso 1 y, al final, la comprobación de que la cantidad de ejemplares `PRESTADO` es igual a la de préstamos `ACTIVO`. Responde en un comentario: ¿por qué el número del préstamo del caso 3 no es el siguiente al último préstamo que existía?

---

## Retos

Bonificación. Resuélvelos en `06_retos.sql`.

### R1 · ¿A quién debemos llamar?

La secretaría va a llamar a los socios que le deben algo a la red: plata (multas con saldo) o libros (préstamos vencidos al corte). Por cada uno quiere el nombre, el teléfono, el saldo de multas, cuántos libros vencidos tiene y los días del vencimiento más antiguo. Primero los que más deben en multas y luego los que tienen más libros vencidos.

### R2 · ¿Qué se mueve en el catálogo?

Compras quiere saber qué categorías rotan más. Por categoría: cuántos títulos tiene, cuántos ejemplares en circulación (sin perdidos ni dados de baja), cuántos préstamos se hicieron desde el `2026-10-01` y cuántos préstamos por ejemplar (2 decimales). Las categorías sin movimiento, como Cómic, también deben aparecer.

### R3 · Cerrar el día

Todas las noches alguien debe vencer las reservas que expiraron. La red quiere poder hacerlo para cualquier fecha, sin escribir el `UPDATE` a mano, sabiendo cuántas reservas se vencieron y sin chocar con *Safe Updates*. Hazlo para el `2026-11-21` y repítelo: la segunda vez no debe vencer nada.

---

## Entregables y rúbrica

**Entregable:** la carpeta o repositorio `taller1_apellido_nombre/` con los archivos `00` a `05` (y `06_retos.sql` si los resuelves), entregada antes de la hora que indique el trainer, con el hash del último commit.

| Criterio | Puntos | Qué se revisa |
|---|---|---|
| Diagrama y normalización | 25 | Entidades y atributos justificados; PK y FK; cardinalidades en ambos sentidos con participación mínima; relaciones N:M resueltas; 1FN–3FN explicadas con ejemplos de BiblioRed; lista de reglas que no protege la estructura. La presentación bonita no compensa relaciones incorrectas |
| DDL | 15 | Estilo de clase; reglas protegidas por la estructura según la tabla de la fase 2; orden de dependencia; préstamos desde el 1001 |
| DML | 10 | Mínimos, datos obligatorios y casos D1–D14; `UPDATE`/`DELETE` con `SELECT` previo; tres errores provocados y explicados; verificación final |
| DQL | 15 | Q-01 a Q-12 con las columnas y el orden pedidos, sin totales duplicados |
| DQL avanzado | 20 | Los 6 procedimientos con sus validaciones en orden, mensajes exactos y todas las pruebas ejecutadas |
| TCL | 10 | T1 y T2 con su evidencia y las dos preguntas respondidas |
| Estilo y script reproducible | 5 | Convenciones de nombres, comentarios por respuesta, archivos numerados que corren desde cero |
| **Total** | **100** | |
| Retos (bonificación) | +3 cada uno | Compensan puntos perdidos, sin pasar de 100 |

**Descuentos:** −10 si el script se detiene por un error no comentado; −5 si se usan temas que todavía no se han visto (funciones propias, triggers, eventos o usuarios); −5 si hay `UPDATE` o `DELETE` sin `WHERE`.

> Este documento propone una rúbrica; el trainer confirma si este taller se califica así o por cumplimiento.

---

La **versión guiada** (`Taller1_BiblioRed_15.md`, con el modelo de referencia) se comparte después de que entregues tu diseño, para que compares.
