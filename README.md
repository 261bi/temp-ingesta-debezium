# CDC MySQL -> PostgreSQL con Debezium y Kafka

Este proyecto levanta una base mínima de infraestructura para trabajar Change Data Capture (CDC) con Debezium sobre Kafka.

La intención del stack es servir como laboratorio o punto de partida para una migración desde MySQL hacia PostgreSQL, manteniendo ambos sistemas sincronizados mientras se realiza la carga histórica inicial.

## Objetivo

Separar la migración en dos flujos:

- Bulk load: mover el histórico grande desde MySQL hacia PostgreSQL.
- CDC: capturar cambios nuevos en MySQL y propagarlos hacia PostgreSQL mediante Debezium y Kafka.

Arquitectura objetivo:

```text
MySQL
 ├── Bulk load (histórico)
 │       ↓
 │   PostgreSQL
 │
 └── CDC (Debezium)
         ↓
      Kafka
         ↓
   PostgreSQL (sync)
```

Arquitectura analítica sugerida con `dbt`:

```text
MySQL OLTP
   ↓
Debezium MySQL Source
   ↓
Kafka
   ↓
PostgreSQL raw replica
   ↓
dbt staging
   ↓
dbt marts
   ↓
BI / consumo analítico
```

## Qué contiene hoy

El archivo [docker-compose.yml](c:/261bigdata/cdc/docker-compose.yml) levanta estos servicios:

- Zookeeper
- MySQL 8 de laboratorio como origen simulado
- Kafka
- Kafka Connect con Debezium
- PostgreSQL de laboratorio como destino de pruebas
- script MySQL para poblar `farmadb` como origen del lab
- configuraciones de conectores MySQL source y PostgreSQL sink

Versiones actuales:

- `debezium/zookeeper:2.7.3.Final`
- `debezium/kafka:2.7.3.Final`
- `debezium/connect:2.7.3.Final`

## Qué hace este stack

- Provee Kafka y Kafka Connect para registrar conectores de Debezium.
- Permite conectar una fuente MySQL para CDC.
- Permite publicar eventos de cambios en topics de Kafka.
- Sirve como base para luego consumir esos eventos y aplicarlos en PostgreSQL.
- Puede reemplazar la capa `MySQL -> PostgreSQL raw` que antes resolvías con Airbyte, con menor latencia para cambios nuevos.

## Qué no hace todavía

Este repositorio no incluye aún:

- Conectores auto-registrados en el arranque.
- Carga histórica inicial masiva.
- Persistencia de volúmenes para Kafka Connect o Kafka.
- Observabilidad o monitoreo.
- Una raw histórica orientada a eventos; el sink actual deja una réplica operacional de tablas.

## Origen MySQL

El origen de esta maqueta ahora es MySQL 8. El compose levanta una base `farmadb` y la inicializa automáticamente con el esquema de farmacia entregado para el lab.

Tablas iniciales del origen:

- `familias`;
- `clientes`;
- `vendedores`;
- `categorias`;
- `productos`;
- `pedidos`;
- `pedido_detalles`.

Script de inicialización del origen:

- [mysql/init/01_farmadb.sql](c:/261bigdata/cdc/mysql/init/01_farmadb.sql)

## Conectores incluidos

Archivos de configuración:

- [connectors/mysql-source.config.json](c:/261bigdata/cdc/connectors/mysql-source.config.json)
- [connectors/postgres-sink.config.json](c:/261bigdata/cdc/connectors/postgres-sink.config.json)
- [scripts/register-source.ps1](c:/261bigdata/cdc/scripts/register-source.ps1)
- [scripts/register-sink.ps1](c:/261bigdata/cdc/scripts/register-sink.ps1)
- [scripts/register-connectors.ps1](c:/261bigdata/cdc/scripts/register-connectors.ps1)

## Cuándo usar este enfoque

Este patrón sirve cuando:

- MySQL es el sistema actual y no puede apagarse de inmediato.
- PostgreSQL será el destino final, local o en la nube.
- Se necesita mantener sincronía entre ambos durante la transición.
- El histórico es demasiado grande para moverlo solo con CDC.

## Bulk Load vs CDC

### Bulk load

Bulk load no es una librería ni un contenedor específico. Es la carga inicial masiva del histórico.

Normalmente se implementa con herramientas o procesos externos, por ejemplo:

- extracción por lotes o rangos desde MySQL;
- archivos intermedios CSV o Parquet;
- carga en PostgreSQL con `COPY`;
- procesos paralelos por tabla o por partición.

En volúmenes de terabytes, esta suele ser la forma correcta de mover el histórico.

### CDC

CDC se usa después o durante la carga inicial para replicar cambios nuevos:

- inserts;
- updates;
- deletes.

Debezium lee cambios desde MySQL y los publica en Kafka. Luego un sink o proceso consumidor aplica esos eventos en PostgreSQL.

## Componentes

### Zookeeper

Se usa como dependencia del broker Kafka en esta composición actual.

### MySQL 8

Se agrega un MySQL 8 de laboratorio como fuente del CDC.

Puerto expuesto:

- `33306`

Credenciales por defecto:

- usuario administrador: `root`
- password administrador: `root`
- base de datos: `farmadb`

Credenciales usadas por el conector source en este laboratorio:

- usuario: `root`
- password: `root`

Inicializacion automatica:

- crea la base `farmadb`;
- ejecuta [mysql/init/01_farmadb.sql](c:/261bigdata/cdc/mysql/init/01_farmadb.sql);
- deja disponible el acceso del usuario `root` para el conector source.

Nota de laboratorio:

- la imagen usada es `mysql:8.0`;
- el origen ya trae binlog en formato `ROW` y `binlog_row_image=FULL` para Debezium;
- PostgreSQL sigue arrancando vacío y el sink crea las tablas al recibir el snapshot inicial y los cambios posteriores.

### Por qué este MySQL sí habilita CDC real

En este laboratorio, la base MySQL se levanta con esta configuración:

```yaml
mysql:
  image: mysql:8.0
  command:
    - --server-id=223344
    - --log-bin=mysql-bin
    - --binlog-format=ROW
    - --binlog-row-image=FULL
    - --gtid-mode=ON
    - --enforce-gtid-consistency=ON
    - --default-authentication-plugin=mysql_native_password
```

Esto es lo que habilita CDC real con Debezium:

- `--log-bin=mysql-bin`: activa el binary log de MySQL;
- `--binlog-format=ROW`: registra cambios por fila y no solo por sentencia SQL;
- `--binlog-row-image=FULL`: incluye la imagen completa de la fila para updates y deletes;
- `--server-id=223344`: identifica la instancia dentro del mecanismo de replicación/binlog;
- `--gtid-mode=ON` y `--enforce-gtid-consistency=ON`: ayudan a mantener una posición consistente en el log.

En otras palabras:

```text
MySQL escribe cambios en binlog
   ↓
Debezium lee binlog
   ↓
Kafka publica eventos
   ↓
PostgreSQL replica cambios
```

Eso no depende de una columna de auditoría como `fecha_modificacion`.

Comparación práctica con el enfoque incremental por cursor:

- con Airbyte por cursor, normalmente consultas `todo lo que cambió después de X` usando una columna como `fecha_modificacion`;
- con Debezium, se leen cambios reales del motor desde el binlog;
- por eso este enfoque suele tener menos latencia y menos riesgo de perder cambios cuando el timestamp no se actualiza correctamente.

Si en otro proyecto quieres que Airbyte haga CDC real sobre MySQL, también necesitas que el servicio MySQL arranque con estos flags de binlog y replicación. Sin eso, lo normal es terminar usando sincronización incremental por cursor con una columna como `fecha_modificacion`.

### Kafka

Recibe los eventos de cambio publicados por los conectores.

Puerto expuesto:

- `39092`

### Kafka Connect / Debezium

Es el runtime donde se registran conectores como:

- MySQL source connector;
- PostgreSQL sink connector o un flujo consumidor alternativo.

Puerto expuesto:

- `38083`

### PostgreSQL de laboratorio

Se incorpora un PostgreSQL local como destino de laboratorio para probar bulk load, validaciones y etapas previas al CDC real.

Por defecto debe estar vacío. En este laboratorio, el destino no trae tablas ni datos precargados: el sink JDBC crea las tablas automáticamente a partir de los eventos MySQL.

Puerto expuesto:

- `35432`

Credenciales por defecto:

- base de datos: `farmacia_dw`
- esquema de aterrizaje: `raw`
- usuario: `postgres`
- password: `postgres`

Comportamiento esperado:

- base creada automáticamente: `farmacia_dw`;
- esquema `raw` creado al inicializar PostgreSQL;
- sin tablas de negocio al inicio dentro de `raw`;
- el conector sink crea tablas como `raw.familias`, `raw.clientes`, `raw.productos`, `raw.pedidos` y `raw.pedido_detalles`.

## Requisitos

- Docker Desktop o Docker Engine con Compose.
- Acceso de red hacia la base MySQL fuente.
- Usuario MySQL con permisos de replicación y lectura para Debezium.
- Si no usas el contenedor MySQL del compose, una instancia MySQL compatible con binlog en formato `ROW`.

## Cómo levantar el stack

Desde la raíz del proyecto:

```powershell
docker compose up -d
```

Para revisar el estado:

```powershell
docker compose ps
```

Para ver logs de Connect:

```powershell
docker compose logs -f connect
```

Para detener todo:

```powershell
docker compose down
```

Si quieres recrear también los datos de laboratorio desde cero, elimina los volúmenes de MySQL y PostgreSQL:

```powershell
docker compose down -v
docker compose up -d
```

## Cómo poblar el origen MySQL

Si usas el contenedor MySQL del compose, la carga ocurre automáticamente en el primer arranque mediante [mysql/init/01_farmadb.sql](c:/261bigdata/cdc/mysql/init/01_farmadb.sql).

Si quieres cargarla manualmente sobre otro MySQL:

```powershell
mysql -u root -p < mysql/init/01_farmadb.sql
```

## Ejecución manual desde cero

Si quieres iniciar el laboratorio desde cero y dejar PostgreSQL vacío para poblarlo manualmente después, usa este orden.

### 1. Borrar datos previos y levantar el stack

```powershell
docker compose down -v
docker compose up -d
docker compose ps
```

En este punto:

- MySQL se inicializa con los datos del laboratorio;
- PostgreSQL crea la base `farmacia_dw` y el esquema `raw`, pero sigue sin tablas de negocio dentro de `raw`;
- Kafka y Connect quedan listos, pero todavía sin replicar datos a PostgreSQL.

### 2. Confirmar que PostgreSQL sigue vacío

```powershell
docker compose exec postgres psql -U postgres -d farmacia_dw -c "select schemaname, tablename from pg_tables where schemaname = 'raw' order by tablename;"
```

Lo esperado aquí es que no aparezcan tablas de negocio como `familias`, `clientes` o `productos`.

### 3. Registrar solo el conector source de MySQL

No ejecutes `scripts/register-connectors.ps1` todavía, porque ese script registra source y sink juntos.

Para dejar PostgreSQL vacío y empezar solo con la captura hacia Kafka, registra únicamente el source:

```powershell
.\scripts\register-source.ps1
```

### 4. Verificar que el source quedó activo

```powershell
Invoke-RestMethod http://localhost:38083/connectors/mysql-farmadb-source/status
```

El conector debe quedar en `RUNNING`.

### 5. Ver los eventos en Kafka

Listar topics:

```powershell
docker exec cdc-kafka-1 bash -lc "kafka-topics.sh --bootstrap-server kafka:9092 --list"
```

Ver eventos de una tabla, por ejemplo `familias`:

```powershell
docker exec cdc-kafka-1 bash -lc "kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic farmadb.farmadb.familias --from-beginning"
```

Si el source quedó activo, aquí verás los eventos del snapshot inicial y luego los cambios nuevos.

### 6. Poblar PostgreSQL manualmente cuando tú decidas

Mientras no registres el sink, PostgreSQL seguirá vacío de tablas de negocio. Eso te permite:

- revisar eventos en Kafka;
- hacer tus propias validaciones;
- poblar PostgreSQL manualmente por otra vía si quieres.

### 7. Activar el sink cuando quieras empezar la réplica a PostgreSQL

Cuando ya quieras que Kafka empiece a escribir en PostgreSQL, registra el sink manualmente:

```powershell
.\scripts\register-sink.ps1
```

Verifica su estado:

```powershell
Invoke-RestMethod http://localhost:38083/connectors/postgres-cdc-sink/status
```

Desde ese momento:

- el sink crea las tablas destino en PostgreSQL;
- aplica el snapshot inicial publicado por el source;
- y luego sigue consumiendo cambios nuevos por CDC.

## Registro de conectores

Cuando `mysql`, `kafka`, `connect` y `postgres` estén arriba, registra ambos conectores:

```powershell
.\scripts\register-connectors.ps1
```

Ese script combinado ahora llama internamente a:

- `register-source.ps1`
- `register-sink.ps1`

Nota: si recreas el contenedor `connect`, es normal tener que volver a ejecutar este registro.

Consulta el estado:

```powershell
Invoke-RestMethod http://localhost:38083/connectors
Invoke-RestMethod http://localhost:38083/connectors/mysql-farmadb-source/status
Invoke-RestMethod http://localhost:38083/connectors/postgres-cdc-sink/status
```

Ejemplo con `mysql`:

```powershell
mysql -u root -proot -h localhost -P 33306 -D farmadb -e "show tables;"
```

El script crea y carga estas entidades en MySQL:

- `familias`
- `clientes`
- `vendedores`
- `categorias`
- `productos`
- `pedidos`
- `pedido_detalles`

## Cómo validar que quedó operativo

Validaciones básicas:

1. Confirmar que los tres servicios están arriba con `docker compose ps`.
2. Confirmar que MySQL responde en `localhost:33306`.
3. Verificar que Kafka Connect responde en `http://localhost:38083/`.
4. Confirmar que el endpoint de conectores responde en `http://localhost:38083/connectors`.
5. Confirmar que PostgreSQL responde y que no tiene tablas de negocio antes de registrar el sink.
6. Registrar conectores y validar que PostgreSQL empieza a crear tablas destino.
7. Validar que el snapshot inicial copie las tablas de `farmadb` hacia PostgreSQL.

Ejemplo:

```powershell
Invoke-RestMethod http://localhost:38083/connectors
```

Ejemplo para validar PostgreSQL:

```powershell
docker compose exec postgres psql -U postgres -d farmacia_dw -c "select schemaname, tablename from pg_tables where schemaname = 'raw' order by tablename;"
docker compose exec postgres psql -U postgres -d farmacia_dw -c "select count(*) as productos from raw.productos;"
docker compose exec postgres psql -U postgres -d farmacia_dw -c "select count(*) as detalles from raw.pedido_detalles;"
```

Ejemplo para validar MySQL:

```powershell
docker compose exec mysql mysql -uroot -proot -D farmadb -e "select count(*) as productos from productos; select count(*) as pedidos from pedidos;"
```

## Flujo recomendado de migración

## Integración con dbt

Si ya tienes el proyecto `dw-dbt` de [farmacia-bi](https://github.com/261bi/farmacia-bi/tree/main/dw-dbt), el encaje recomendado queda así:

1. MySQL sigue siendo la fuente OLTP.
2. Debezium captura snapshot inicial y cambios nuevos.
3. Kafka recibe los eventos de CDC.
4. El sink JDBC aterriza las tablas en PostgreSQL como capa `raw replica`.
5. `dbt` consume esa capa en PostgreSQL y construye `staging` y `marts`.

En otras palabras, para este laboratorio la arquitectura pasa de:

```text
MySQL -> Airbyte -> PostgreSQL raw -> dbt staging -> dbt marts
```

a esta variante más liviana:

```text
MySQL -> Debezium/Kafka -> PostgreSQL raw replica -> dbt staging -> dbt marts
```

Diferencia importante:

- Airbyte suele dejar una capa `raw` más pensada para ingesta ELT.
- El sink actual de Debezium deja una réplica casi 1:1 de las tablas fuente.
- Para `staging` y `marts` en `dbt`, esa réplica suele ser suficiente y reduce la latencia frente a Airbyte.

Si el objetivo es analytics con menor demora para ver cambios nuevos, este stack encaja bien como reemplazo de Airbyte en la parte `MySQL OLTP -> PostgreSQL raw replica`.

Para una migración MySQL -> PostgreSQL a gran escala, el orden recomendado es:

1. Analizar esquema, tipos y tablas críticas.
2. Ejecutar bulk load del histórico hacia PostgreSQL.
3. Levantar CDC desde MySQL con Debezium.
4. Publicar eventos en Kafka.
5. Aplicar cambios en PostgreSQL mediante sink o consumidor.
6. Validar conteos, checksums y lag.
7. Hacer cutover final cuando PostgreSQL esté al día.

## Limitaciones actuales del proyecto

- El `docker-compose` actual es una base mínima de laboratorio.
- El MySQL incluido es una base de laboratorio y no reemplaza afinamiento de una instancia productiva.
- El snapshot inicial del conector source sirve para esta maqueta, pero no es la estrategia recomendada para una migración de terabytes.
- No hay persistencia declarada para datos o configuraciones.
- No hay tuning de Kafka Connect para producción.
- No hay manejo de secretos ni variables externas.

## Próximos pasos sugeridos

1. Agregar volúmenes persistentes.
2. Añadir ejemplos de configuración de conectores MySQL y PostgreSQL.
3. Definir estrategia de bulk load fuera de Kafka.
4. Preparar una variante orientada a nube.

## Referencias

- Debezium MySQL Connector: https://debezium.io/documentation/reference/2.7/connectors/mysql.html
- Debezium JDBC Sink Connector: https://debezium.io/documentation/reference/2.7/connectors/jdbc.html