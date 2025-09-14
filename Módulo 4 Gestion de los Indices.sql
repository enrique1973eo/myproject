--Indexing in SQL Server
--Which is Faster: Index Access or Table Scan?
use tempdb
go

--1
create table miTabla (
	i int identity primary key clustered,
	b char(1),
	u uniqueidentifier default newid())
	
create index ix_t10entries_b on miTabla(b)

sp_helpindex 'miTabla'

--2
insert miTabla (b)
	select char(number)
	from master..spt_values
	where type='P' 
	and number between 65 and 74

--3 Incluir plan de ejecucion
select * from miTabla

--4
select i, u from miTabla 
where b = 'G'
GO


--SQL Server Index Basics: Clustered Indexes
use tempdb
go

--1
create table testIndice
(
codigo int not null,
nombre varchar (100)
)

--2
insert into testIndice values (2, 'Cadena')
insert into testIndice values (16, 'Reloj')
insert into testIndice values (8, 'Anillo')
insert into testIndice values (10, 'Corbata')
insert into testIndice values (3, 'Bibiri')
insert into testIndice values (1, 'Reloj')
insert into testIndice values (6, 'Anillo')
insert into testIndice values (0, 'Corbata')

--3
select * from testIndice

--4. Usamos el explorador de objetos para crear el indice cluster

--5
select * from testIndice

--6
insert into testIndice values (7, 'AAAAAAAAAAAA')
insert into testIndice values (11,'VBVBVBVBVBVB')



USE AdventureWorks2022;
GO

EXEC sp_helpstats 'Person.Person';

DROP STATISTICS Person.Person.Person_FirstName_Stats
GO

CREATE STATISTICS Person_FirstName_Stats 
ON Person.Person (FirstName)
WITH FULLSCAN;
GO

EXEC sp_helpstats 'Person.Person';
GO

DBCC SHOW_STATISTICS('Person.Person',Person_FirstName_Stats);
GO

SELECT count(*) FROM Person.Contact 
WHERE FirstName = 'Abigail';
GO

-------------MANTÉN LAS ESTADÍSTICAS ACTUALIZADAS------------------------------------
--AUTO_UPDATE_STATISTICS
ALTER DATABASE nombre_base_datos  
SET AUTO_UPDATE_STATISTICS ON;
--Esto permite que SQL Server actualice automáticamente las estadísticas cuando detecte cambios significativos en los datos.

--AUTO_UPDATE_STATISTICS_ASYNC
ALTER DATABASE nombre_base_datos  
SET AUTO_UPDATE_STATISTICS_ASYNC ON;
--Con esta opción activada, las estadísticas se actualizan en segundo plano, evitando bloqueos en consultas que dependen de ellas.


-------------MONITOREA LAS ESTADÍSTICAS Y SU IMPACTO EN LOS PLANES DE EJECUCIÓN------
--#### **Explicación de cada columna:**
--object_id: Identificador de la tabla o vista sobre la cual se tienen las estadísticas.
--stats_id: Identificador único de las estadísticas dentro de la tabla.
--last_updated: Fecha y hora de la última actualización de las estadísticas.
--rows: Número total de filas en la tabla en el momento de la última actualización de estadísticas.
--rows_sampled: Cantidad de filas utilizadas para calcular las estadísticas (puede ser menor a `rows` si se usó muestreo en la actualización).

--Cómo interpretarlo:
--Si `last_updated` es antigua en comparación con la actividad de la tabla, es posible que necesites actualizar las estadísticas manualmente.
--Si `rows_sampled` es mucho menor que `rows`, el muestreo puede ser insuficiente, lo que puede afectar la precisión de los planes de ejecución.

SELECT object_id, stats_id, last_updated, rows, rows_sampled
FROM sys.dm_db_stats_properties(OBJECT_ID('[dbo].[DimProductCategory]'), NULL);

--Análisis de planes de ejecución y estadísticas obsoletas
--Un **plan de ejecución** es la estrategia que SQL Server usa para ejecutar una consulta. Si las estadísticas están desactualizadas, SQL Server puede generar planes de ejecución ineficientes.

--#### **Pasos para analizar planes de ejecución y detectar problemas con estadísticas:**
--1. **Ejecutar el plan de ejecución estimado o real**
--2. **Buscar signos de estadísticas obsoletas en el plan de ejecución**
--   - **Cardinalidad incorrecta**: Si el estimado de filas es muy diferente al real, es probable que las estadísticas estén desactualizadas.
--   - **Uso de SCAN en lugar de SEEK**: SQL Server puede optar por un SCAN de tabla en lugar de usar índices eficientes si las estadísticas no reflejan correctamente la distribución de los datos.
--3. **Solución si las estadísticas afectan el rendimiento**
--   - Forzar la actualización manualmente:
--     UPDATE STATISTICS nombre_tabla WITH FULLSCAN;
--   - Si el problema persiste, revisar índices y considerar particionar datos si son muy grandes.


-------------------TÉCNICAS AVANZADAS DE INDEXACIÓN------------------
--### **Significado de "Definir la columna más única primero" en Indexación Avanzada**  

--En SQL Server, cuando se crea un **índice compuesto** (un índice que incluye múltiples columnas), el orden en que se definen las columnas afecta el rendimiento de las consultas. **"Definir la columna más única primero"** significa que, al crear un índice compuesto, la primera columna del índice debe ser aquella con mayor **selectividad** (es decir, la que tiene más valores distintos en comparación con el total de filas).  

			--### **¿Por qué es importante?**  
			--SQL Server utiliza la primera columna del índice para filtrar los datos más rápidamente. Si esta columna tiene una alta **cardinalidad** (muchos valores únicos), el índice será más eficiente en la reducción del conjunto de datos que debe examinar.

--Ejemplo Práctico 1
--Supongamos que tienes una tabla de ventas con las siguientes columnas:  
--- `cliente_id`: 10,000 valores distintos.  
--- `fecha_venta`: Muchas fechas repetidas (por ejemplo, un mismo día puede tener miles de ventas).  

--Si se crea un índice compuesto así:
--CREATE INDEX idx_ventas ON ventas (cliente_id, fecha_venta);
--Este índice es más eficiente porque **cliente_id** es más único y ayuda a reducir rápidamente el número de registros a analizar antes de aplicar el filtro de **fecha_venta**.

--ejemplo Práctico
--Imagina una tabla de "Clientes" con las columnas "País", "Ciudad" y "ID_Cliente".

--"ID_Cliente" es la columna más única, ya que cada cliente tiene un ID único.
--"Ciudad" tiene menos valores únicos que "ID_Cliente", pero más que "País".
--"Pais" es la columna con menos valores unicos.
--Un índice compuesto óptimo sería:

CREATE INDEX IX_Clientes_ID_Cliente_Ciudad_Pais
ON Clientes (ID_Cliente, Ciudad, Pais);
--En este caso, "ID_Cliente" se coloca primero, seguido de "Ciudad" y luego "País".


------------------------------COLUMNAS INCLUIDAS - problema de LOOK UP--------------
USE tempdb;
GO

-- Step 2: 
CREATE TABLE dbo.Book
( ISBN nvarchar(20) PRIMARY KEY,
  Title nvarchar(50) NOT NULL,
  ReleaseDate date NOT NULL,
  PublisherID int NOT NULL
);
GO

-- Step 3: 
CREATE NONCLUSTERED INDEX IX_Book_Publisher
  ON dbo.Book (PublisherID, ReleaseDate DESC);
GO

-- Step 4: estimated execution plan
SELECT PublisherID, Title, ReleaseDate
FROM dbo.Book 
WHERE ReleaseDate > DATEADD(year,-1,SYSDATETIME())
ORDER BY PublisherID, ReleaseDate DESC;
GO

-- Step 5: Replace the index with one that includes the Title column
CREATE NONCLUSTERED INDEX IX_Book_Publisher
  ON dbo.Book (PublisherID, ReleaseDate DESC)
  INCLUDE (Title)
  WITH DROP_EXISTING;
GO

SELECT PublisherID, Title, ReleaseDate
FROM dbo.Book 
WHERE ReleaseDate > DATEADD(year,-1,SYSDATETIME())
ORDER BY PublisherID, ReleaseDate;
GO

DROP INDEX dbo.Book.IX_Book_Publisher;
DROP TABLE dbo.Book;

------------------------------INDICES FILTRADOS--------------
-- Step 1: 
USE [AdventureWorksDW2022]
GO

-- Step 2: 
DBCC FREEPROCCACHE
SET STATISTICS IO ON
	SELECT SalesOrderNumber, SalesAmount
	FROM FactResellerSales
	WHERE SalesAmount > 1000; 
SET STATISTICS IO OFF;


-- Step 3: Crear un índice filtrado para mejorar consultas en ventas mayores a 1000
CREATE NONCLUSTERED INDEX IX_FactResellerSales_SalesAmount_Filtered
ON FactResellerSales (SalesAmount)
WHERE SalesAmount > 1000;
GO

-- Step 4: EXECUTE STEP 2

--Step 5
DROP INDEX dbo.FactResellerSales.IX_FactResellerSales_SalesAmount_Filtered;


------------------------------VISTAS INDIZADAS
USE AdventureWorks2022
GO

-- 0
DBCC FREEPROCCACHE
SET STATISTICS IO ON
    SELECT SUM(UnitPrice*OrderQty*(1.00-UnitPriceDiscount)) AS Revenue,
        OrderDate, ProductID, COUNT_BIG(*) AS 'COUNT'
    FROM Sales.SalesOrderDetail AS od, Sales.SalesOrderHeader AS o
    WHERE od.SalesOrderID = o.SalesOrderID
    GROUP BY OrderDate, ProductID;
SET STATISTICS IO OFF

--1
GO
CREATE VIEW Sales.vOrders
WITH SCHEMABINDING
AS
    SELECT SUM(UnitPrice*OrderQty*(1.00-UnitPriceDiscount)) AS Revenue,
        OrderDate, ProductID, COUNT_BIG(*) AS 'COUNT'
    FROM Sales.SalesOrderDetail AS od, Sales.SalesOrderHeader AS o
    WHERE od.SalesOrderID = o.SalesOrderID
    GROUP BY OrderDate, ProductID;
GO

--2
DBCC FREEPROCCACHE
SET STATISTICS IO ON
	select * from Sales.vOrders
SET STATISTICS IO OFF

GO
SP_SPACEUSED [Sales.vOrders]

--2 Create an index on the view.
CREATE UNIQUE CLUSTERED INDEX IDX_V1 
    ON Sales.vOrders (OrderDate, ProductID);

--3
GO
SP_SPACEUSED [Sales.vOrders]

--Ejecutar el paso 0

--4 Cleanup
DROP VIEW Sales.vOrders

--5
--Escenario Ideal para Aplicar Vistas con Índice Cluster en SQL Server 2022
--Las **vistas indexadas** (vistas con un índice **clustered**) mejoran el rendimiento de consultas complejas almacenando los datos precomputados en disco. Sin embargo, no son aplicables en todos los casos.  

--🔹 CONSULTAS DE AGREGACIÓN FRECUENTES Y COSTOSAS**  
--Si las consultas incluyen funciones como `SUM()`, `AVG()`, `COUNT()`, `GROUP BY`, o `JOIN` sobre grandes volúmenes de datos, una vista indexada puede mejorar drásticamente el rendimiento.  

--Beneficio:** Permite consultar rápidamente las ventas anuales por cliente sin recalcular los datos cada vez.  

--🔹 **MEJORAR RENDIMIENTO EN COMBINACIONES DE TABLAS GRANDES (JOINS FRECUENTES)
--Si una consulta con **JOIN** entre tablas grandes se ejecuta repetidamente, una vista indexada puede prealmacenar los resultados optimizando el rendimiento.  

--Beneficio:** SQL Server reutiliza los datos preprocesados en lugar de recalcular el `JOIN` en cada consulta.  

--### **Casos Donde NO Es Recomendable**  
--❌ Cuando las tablas subyacentes se actualizan frecuentemente, ya que SQL Server debe actualizar la vista indexada en cada cambio.  
		--❌ Cuando la vista contiene funciones no determinísticas (`GETDATE()`, `RAND()`, `NEWID()`).  

--### **Conclusión**  
--Las **vistas indexadas** en SQL Server 2022 son ideales para mejorar el rendimiento en consultas con agregaciones, cálculos repetitivos o combinaciones de tablas grandes. Sin embargo, deben usarse con precaución en entornos con escrituras frecuentes para evitar sobrecarga en actualizaciones. 🚀


------------------------------CONOCER LAS ESTADÍSTICAS DE USO DE ÍNDICE------------------
USE AdventureWorksDW2022 --[AdventureWorksLT2022], [AdventureWorksLT2022], [AdventureWorks2022]
GO

SELECT  
    OBJECT_NAME(i.object_id) AS TableName,  
    i.name AS IndexName,  
    i.index_id,  
    us.user_seeks AS NumSeeks,  
    us.user_scans AS NumScans,  
    us.user_lookups AS NumLookups,  
    us.user_updates AS NumUpdates,  
    us.last_user_seek AS LastSeek,  
    us.last_user_scan AS LastScan,  
    us.last_user_lookup AS LastLookup,  
    us.last_user_update AS LastUpdate  
FROM sys.indexes AS i  
LEFT JOIN sys.dm_db_index_usage_stats AS us  
    ON i.object_id = us.object_id AND i.index_id = us.index_id  
--WHERE i.object_id = OBJECT_ID('[dbo].[FactInternetSales]')  
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY NumSeeks DESC, NumScans DESC;

| **Columna**     | **Descripción** |
|----------------|--------------|
| `TableName`    | Nombre de la tabla donde está el índice. |
| `IndexName`    | Nombre del índice analizado. |
| `NumSeeks`     | Número de veces que el índice se usó en búsquedas eficientes (`WHERE`, `JOIN`). |
| `NumScans`     | Número de veces que SQL Server escaneó el índice en lugar de hacer `SEEK` (puede ser una señal de ineficiencia). |
| `NumLookups`   | Número de veces que SQL Server tuvo que buscar datos adicionales (puede indicar falta de cobertura en el índice). |
| `NumUpdates`   | Número de veces que el índice fue modificado debido a `INSERT`, `UPDATE` o `DELETE`. |
| `LastSeek`     | Fecha y hora de la última búsqueda con `SEEK` en el índice. |
| `LastScan`     | Fecha y hora del último escaneo completo. |
| `LastLookup`   | Fecha y hora de la última búsqueda individual. |
| `LastUpdate`   | Fecha y hora de la última actualización del índice. |

### **Cuándo Optimizar un Índice**  
🔹 **Índices con muchos `Updates` pero pocos `Seeks`** → Puede ser un candidato para eliminación o ajuste.  
🔹 **Índices con alto `Scan` y bajo `Seek`** → Podría necesitar un reordenamiento de columnas o un índice más específico.  
🔹 **Índices sin uso (`NULL` en `LastSeek`, `LastScan`, `LastLookup`)** → Posiblemente obsoleto y candidato a eliminación.  


### **Conclusión**  
Esta consulta permite evaluar la efectividad de los índices en SQL Server 2022 y tomar decisiones informadas sobre **creación, eliminación o ajuste de índices** para mejorar el rendimiento. 🚀


------------------------------IDENTIFICAR Y CORREGIR LA FRAGMENTACIÓN------------------------------
--step 1
SELECT
	OBJECT_NAME(i.object_id) AS TableName ,
	i.name AS TableIndexName ,
	phystat.avg_fragmentation_in_percent 
FROM
	sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') phystat 
		inner JOIN sys.indexes i ON i.object_id = phystat.object_id 
					AND i.index_id = phystat.index_id 
WHERE phystat.avg_fragmentation_in_percent > 10 
AND phystat.avg_fragmentation_in_percent < 100 
order by avg_fragmentation_in_percent desc

--step 2
--ALTER INDEX AK_BillOfMaterials_ProductAssemblyID_ComponentID_StartDate ON Production.BillOfMaterials REORGANIZE
ALTER INDEX PK_StateProvince_StateProvinceID ON Person.StateProvince REBUILD



------------------------------MISSIN INDEX------------------------------
-- Missing Index Script
SELECT TOP 25
dm_mid.database_id AS DatabaseID,
dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
dm_migs.last_user_seek AS Last_User_Seek,
OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + '_'
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''),', ','_'),'[',''),']','') 
+ CASE
WHEN dm_mid.equality_columns IS NOT NULL
AND dm_mid.inequality_columns IS NOT NULL THEN '_'
ELSE ''
END
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''),', ','_'),'[',''),']','')
+ ']'
+ ' ON ' + dm_mid.statement
+ ' (' + ISNULL (dm_mid.equality_columns,'')
+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns 
IS NOT NULL THEN ',' ELSE
'' END
+ ISNULL (dm_mid.inequality_columns, '')
+ ')'
+ ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid
ON dm_mig.index_handle = dm_mid.index_handle
WHERE dm_mid.database_ID = DB_ID()
ORDER BY Avg_Estimated_Impact DESC
GO

--### **¿Qué es un Missing Index en SQL Server?**  
--Un **Missing Index** es un índice recomendado por SQL Server cuando detecta que ciertas consultas podrían mejorar su rendimiento si existiera un índice adecuado. SQL Server identifica estos índices analizando patrones de consulta y acceso a los datos.  

--⚠ **Importante:**  
--- Los **Missing Indexes** no se crean automáticamente; deben evaluarse antes de implementarlos.  
--- No siempre son la mejor solución; hay que considerar su impacto en inserciones, actualizaciones y eliminaciones.  

--### **Explicación del Query (Resumen Rápido)**  
--Este **script identifica y sugiere índices faltantes** en la base de datos, generando automáticamente un comando `CREATE INDEX`.  

--#### **Explicación de las columnas clave:**  
--- `Avg_Estimated_Impact`: Impacto estimado del índice en el rendimiento de las consultas.  
--- `Last_User_Seek`: Última vez que se identificó la necesidad del índice.  
--- `TableName`: Tabla donde falta el índice.  
--- `Create_Statement`: Comando `CREATE INDEX` sugerido.  

--#### **Cómo funciona:**  
--1. Extrae información de las vistas del sistema `sys.dm_db_missing_index_details`, `sys.dm_db_missing_index_groups` y `sys.dm_db_missing_index_group_stats`.  
--2. Calcula el impacto estimado basado en `user_seeks` y `user_scans`.  
--3. Construye dinámicamente una instrucción `CREATE INDEX` basada en las columnas involucradas.  
--4. Ordena los índices recomendados por impacto estimado (`Avg_Estimated_Impact DESC`).  

--### **Conclusión**  
--Este query es una herramienta poderosa para identificar y generar índices potencialmente útiles. Sin embargo, **antes de aplicar cualquier índice, se recomienda analizar su impacto** en la base de datos para evitar sobrecarga en escrituras y mantenimientos innecesarios. 🚀


------------------------------Unused INDEX------------------------------
SELECT TOP 25
o.name AS ObjectName
, i.name AS IndexName
, i.index_id AS IndexID
, dm_ius.user_seeks AS UserSeek
, dm_ius.user_scans AS UserScans
, dm_ius.user_lookups AS UserLookups
, dm_ius.user_updates AS UserUpdates
, p.TableRows
, 'DROP INDEX ' + QUOTENAME(i.name)
+ ' ON ' + QUOTENAME(s.name) + '.'
+ QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS 'drop statement'
FROM sys.dm_db_index_usage_stats dm_ius
INNER JOIN sys.indexes i ON i.index_id = dm_ius.index_id 
AND dm_ius.OBJECT_ID = i.OBJECT_ID
INNER JOIN sys.objects o ON dm_ius.OBJECT_ID = o.OBJECT_ID
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1
AND dm_ius.database_id = DB_ID()
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
GO

--Un "Unused Index" (índice no utilizado) es un índice que SQL Server ha detectado que no está siendo utilizado por las consultas.  En otras palabras, es un índice que existe en la base de datos, pero el optimizador de consultas nunca lo elige para ejecutar consultas.  Esto significa que el índice está ocupando espacio y recursos del sistema (especialmente durante las operaciones de inserción, actualización y eliminación), pero no está proporcionando ningún beneficio en términos de rendimiento de las consultas.

--El query que has proporcionado sirve para identificar y listar los índices no utilizados en tu base de datos actual.  De manera resumida, el query hace lo siguiente:

--1.  **`SELECT TOP 25 ...`**:  Selecciona los 25 índices menos utilizados.
--2.  **`o.name AS ObjectName, i.name AS IndexName, ...`**:  Obtiene información sobre el índice, como el nombre del objeto (tabla), el nombre del índice, etc.
--3.  **`dm_ius.user_seeks, dm_ius.user_scans, dm_ius.user_lookups, dm_ius.user_updates`**:  Estas columnas muestran cuántas veces se han realizado búsquedas, escaneos, búsquedas de marcadores y actualizaciones en el índice.  Si estos valores son bajos (idealmente cero), sugiere que el índice no se está utilizando.
--4.  **`p.TableRows`**:  Muestra el número de filas en la tabla asociada al índice.
--5.  **`'DROP INDEX ...' AS 'drop statement'`**:  Genera una sentencia `DROP INDEX` para cada índice no utilizado.  Esto te da el script exacto que puedes ejecutar para eliminar el índice.
--6.  **`FROM sys.dm_db_index_usage_stats dm_ius ...`**:  Obtiene los datos de las vistas del sistema que contienen información sobre el uso de los índices.
--7.  **`WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1 ...`**:  Filtra los resultados para mostrar solo los índices de tablas de usuario y excluye índices de sistema, claves primarias y constraints únicos.
--8.  **`ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC`**:  Ordena los resultados por la suma de búsquedas, escaneos y búsquedas de marcadores, de menor a mayor.  Esto muestra primero los índices que se utilizan menos.

--En resumen, este query te da una lista de índices que probablemente no se estén utilizando y, por lo tanto, podrían ser candidatos para ser eliminados.  Eliminar índices no utilizados puede liberar espacio en disco y reducir la sobrecarga de mantenimiento, mejorando el rendimiento general de la base de datos.