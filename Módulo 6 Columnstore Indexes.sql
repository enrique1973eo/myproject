-----------------QUE SON LOS ÍNDICES COLUMNSTORE-----------------
--Columnstore Indexes en SQL Server 2022 son un tipo de índice diseñado para mejorar el rendimiento de consultas analíticas en grandes volúmenes de datos. A diferencia de los índices tradicionales basados en filas (*rowstore*), los índices columnares almacenan los datos en columnas en lugar de filas, lo que permite una mejor compresión y un acceso más eficiente en consultas de agregación y exploración de datos.

-- Beneficios de Columnstore Indexes
--✔ Compresión Eficiente → Reduce el almacenamiento hasta 10 veces.  
	--Los Columnstore Indexes utilizan técnicas avanzadas de compresión, logrando reducir el tamaño del almacenamiento hasta 10 veces en comparación con los índices tradicionales (rowstore). Esto se debe a dos factores clave:
				--a) Almacenamiento en Segmentos
				--Los datos en un índice columnar se dividen en segmentos de 1 millón de filas, lo que permite aplicar una compresión más efectiva en cada columna.
				--c) Eliminación de Datos No Necesarios
				--	Se omiten automáticamente valores NULL, reduciendo aún más el tamaño de almacenamiento

--✔ Batch Processing → Ejecuta consultas en paralelo y mejora el rendimiento.  
	 --Procesa múltiples filas simultáneamente en paquetes de 900-1000 filas, aprovechando la paralelización.
	 --Esto mejora drásticamente la ejecución de consultas con agregaciones, filtros y agrupaciones.
	 --Las consultas analíticas que procesan grandes volúmenes de datos (e.g., GROUP BY, SUM, AVG, COUNT sobre millones de filas) se benefician enormemente del modo batch.

--✔ Eliminación Automática de Filas No Necesarias → Ignora segmentos de datos irrelevantes.  
	--Los datos en Columnstore Indexes se organizan en segmentos de 1 millón de filas.
	--SQL Server mantiene metadatos sobre los valores mínimo y máximo de cada segmento.
	--Cuando una consulta filtra por una columna específica, solo se leen los segmentos relevantes, ignorando aquellos que no contienen datos útiles.
	--		✅ Ejemplo de Beneficio
	--			Una consulta con un filtro de rango (WHERE Date BETWEEN '2024-01-01' AND '2024-01-31') en una tabla con 1,000 millones de filas solo leerá los segmentos que contienen ese rango, en lugar de escanear toda la tabla

--Este índice es ideal para consultas analíticas en bases de datos de gran tamaño, especialmente en entornos de *Business Intelligence (BI)* y *Big Data*.


-----------------NONCLUSTERED COLUMNSTORE INDEXES-----------------
--Un Nonclustered Columnstore Index (NCCI) es un índice columna no agrupado que se puede aplicar sobre una tabla con almacenamiento en filas (*rowstore*). Es útil para mejorar el rendimiento de consultas analíticas sin afectar las operaciones de transacción en línea (*OLTP*).  

-- 1. Permite una Estrategia Híbrida (OLTP + OLAP)
--- Un NCCI permite mantener la estructura de filas de la tabla original mientras se acelera el procesamiento de consultas analíticas.  
--- Es ideal para workloads híbridos, donde se realizan operaciones de consulta masiva (OLAP) sin afectar el rendimiento de inserciones y actualizaciones en línea (OLTP).  

-- 2. Optimización con Batch Processing
--- Las consultas analíticas (OLAP) utilizan *Batch Mode Processing*, lo que permite procesar datos en bloques de hasta 1,000 filas simultáneamente en lugar de fila por fila.  
--- Esto reduce la carga en CPU y mejora el rendimiento en consultas de agregación, filtros y uniones grandes.  

-- 4. Insertos y Actualizaciones con Delta Store
--- Los NCCI tienen un área de almacenamiento temporal llamada Delta Store, donde se insertan las filas nuevas en formato rowstore antes de ser convertidas en columnstore.  
--- Una vez que el Delta Store alcanza 104,857 filas, se convierte en un nuevo segmento columnstore comprimido.  
--- Impacto:  
--  - Altas tasas de inserción pueden degradar el rendimiento debido a la necesidad de conversión.  
--  - Es recomendable hacer cargas masivas en lotes grandes para evitar fragmentación.  

-- 7. Compatible con Index Rebuild y Mantenimiento Online
--- Permite reconstrucción en línea con `ALTER INDEX REBUILD`, minimizando impacto en operaciones concurrentes.  

-- Cuándo Usar un Nonclustered Columnstore Index
--✅ Workloads híbridos (OLTP + OLAP).  
--✅ Tablas con altas tasas de inserción y necesidad de consultas analíticas rápidas.  
--✅ Reducción del tamaño de almacenamiento sin alterar la estructura rowstore.  
--✅ Escenarios donde la eliminación automática de datos irrelevantes mejora la eficiencia.  

--🚀 Conclusión:  
--Los Nonclustered Columnstore Indexes (NCCI) son ideales para bases de datos transaccionales con consultas analíticas frecuentes, combinando el rendimiento de OLTP y OLAP sin sacrificar velocidad de escritura ni integridad de datos.




-----------------CLUSTERED COLUMNSTORE INDEXES-----------------
--Un Clustered Columnstore Index (CCI) es un índice columna *agrupado* que almacena toda la tabla en formato columnar en lugar de filas. Es altamente eficiente para cargas de trabajo analíticas (OLAP), ya que mejora la compresión, reduce el consumo de I/O y acelera la ejecución de consultas de agregación.

-- 1. Almacena Toda la Tabla en Formato Columnar
--- Un CCI reemplaza completamente la estructura rowstore de la tabla.  
--- La tabla ya no tiene almacenamiento tradicional en filas (*heap* o *clustered index*).  
--- Permite escaneo de grandes volúmenes de datos con máxima eficiencia.

-- 2. Altamente Comprimido → Reduce el Tamaño hasta 10 Veces
--- Usa técnicas de compresión avanzadas como:
--  - Run-Length Encoding (RLE): Agrupa valores repetidos.
--  - Dictionary Encoding: Almacena referencias en lugar de valores repetidos.
--  - Bit-Packing: Reduce el tamaño de valores numéricos.  
--- Reduce la cantidad de almacenamiento en disco y memoria, minimizando el impacto en rendimiento.

--✅ Ejemplo de Beneficio:  
--Una tabla de 100 GB en formato *rowstore* puede reducirse a 10 GB o menos con un CCI.

-- 3. Procesamiento en Modo Batch (Batch Mode Processing)
--- Las consultas analíticas pueden procesar múltiples filas a la vez (hasta 1,000 filas por ciclo de CPU).
--- Acelera consultas de agregaciones, filtros y uniones sobre grandes volúmenes de datos.

-- 5. Manejo de Insertos con Delta Store
--- Las filas nuevas se insertan primero en un Delta Store en formato *rowstore*.
--- Cuando el Delta Store alcanza 104,857 filas, se convierte en un segmento *columnstore* comprimido.
--- Puede generar fragmentación si hay muchas filas en el Delta Store sin comprimir.
--✅ Recomendación:  
--Realizar cargas de datos en lotes grandes (`BULK INSERT`) para evitar fragmentación.

-- 7. Soporta Actualizaciones, pero con Costo Alto
--- Las actualizaciones (`UPDATE` y `DELETE`) son costosas, ya que se manejan con segmentos enteros.  
--- SQL Server marca las filas eliminadas como "eliminadas" en lugar de eliminarlas físicamente.  
--- Se recomienda realizar reconstrucciones periódicas (`REBUILD`) para optimizar el rendimiento.

 --8. Soporta Columnstore Archival Compression
--- SQL Server 2022 permite aplicar una compresión aún mayor en datos históricos mediante `COLUMNSTORE_ARCHIVE`:
--- Útil para almacenamiento de datos históricos con menos consultas frecuentes.

-- Cuándo Usar un Clustered Columnstore Index
--✅ Bases de datos de Data Warehouse y Big Data.  
--✅ Consultas analíticas sobre millones o miles de millones de filas.  
--✅ Alta compresión de almacenamiento y reducción de costos de I/O.  
--✅ Optimización de rendimiento en agregaciones, filtros y JOINs.  

--🚀 Conclusión:  
--Los Clustered Columnstore Indexes (CCI) son la mejor opción para bases de datos analíticas en SQL Server 2022, proporcionando máxima compresión y alto rendimiento en consultas de grandes volúmenes de datos.


-----------------Managing Columnstore Indexes-----------------
--La imagen muestra cómo SQL Server maneja la inserción de datos en un Columnstore Index, ilustrando la transformación desde la carga inicial hasta la compresión en segmentos columnares.

-- 1. Datos a Insertar (Data to Insert)
--- Representa los datos que se van a insertar en la tabla con un Clustered Columnstore Index (CCI) o un Nonclustered Columnstore Index (NCCI).  
--- Estos datos pueden provenir de inserciones individuales (`INSERT INTO`), cargas masivas (`BULK INSERT`), o procesos ETL.  

-- 2. Agrupación en Rowgroups (Rowgroups to Insert)
--- SQL Server organiza las filas en grupos llamados Rowgroups, cada uno con un máximo de 1,048,576 filas.  
--- Un Rowgroup es la unidad lógica de almacenamiento dentro de un Columnstore Index.  

-- 3. Conversión a Segmentos Columnares (Column Segments)
--- Cada Rowgroup se convierte en segmentos columnares donde cada columna se almacena por separado en bloques comprimidos.  
--- Cada segmento contiene aproximadamente 102,400 filas (puede variar debido a la compresión).  
--- Esta organización permite una alta compresión y un acceso más eficiente a los datos.  
--✅ Beneficio:  
--Las consultas solo leen las columnas necesarias en lugar de toda la fila, reduciendo el uso de memoria y aumentando la velocidad de ejecución.  

-- 4. Almacenamiento en Columnstore (Compressed Column Segments)
--- Los segmentos columnares se almacenan en la estructura Columnstore de la tabla.  
--- SQL Server usa técnicas de compresión avanzada como:
--  - Run-Length Encoding (RLE) (para valores repetidos).
--  - Dictionary Encoding (para reducir almacenamiento de cadenas de texto).
--  - Bit-Packing (para valores numéricos más eficientes).
--✅ Beneficio:  
--Reduce el almacenamiento hasta 10 veces y acelera las consultas analíticas (*OLAP*).  


-- 5. Manejo del Delta Store
--- Si la inserción contiene menos de 102,400 filas, los datos NO se comprimen inmediatamente.  
--- En su lugar, se almacenan temporalmente en un Delta Store en formato *rowstore* (similar a un heap o un índice tradicional).  
--- Una vez que el Delta Store acumula suficientes filas, se convierte en un segmento columnstore comprimido.  
--✅ Impacto en el Rendimiento:  
--- Muchas inserciones pequeñas generan fragmentación en el Delta Store.  
--- Se recomienda hacer cargas masivas (`BULK INSERT` o `INSERT INTO ... SELECT`) para reducir la fragmentación y optimizar el rendimiento.  

-- Conclusión  
--La imagen ilustra el flujo de trabajo de los Columnstore Indexes en SQL Server, desde la inserción de datos hasta su compresión en segmentos columnares. Este proceso permite una ejecución de consultas mucho más rápida y eficiente, especialmente en bases de datos analíticas (*OLAP*).




----------------------------------DEMOSTRACIONES-----------------
--1
USE [AdventureworksDW2022]
GO

SELECT * INTO FactResellerSalesXL
FROM FactResellerSales
GO

USE [AdventureworksDW2022]
GO
ALTER TABLE [dbo].[FactResellerSalesXL] ADD  CONSTRAINT [PK_FactResellerSalesXL_SalesOrderNumber_SalesOrderLineNumber] PRIMARY KEY NONCLUSTERED 
(
	[SalesOrderNumber] ASC,
	[SalesOrderLineNumber] ASC
)


USE AdventureWorksDW2022;  
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON;
DBCC FREEPROCCACHE
	SELECT ProductKey, sum(SalesAmount) SalesAmount, sum(OrderQuantity) ct
	FROM dbo.FactResellerSalesXL
	GROUP BY ProductKey
SET STATISTICS IO OFF
SET STATISTICS TIME OFF;
--Table 'FactResellerSalesXL'. Scan count 1, logical reads 1673,
--Segundo bloque (CPU time = 16 ms, elapsed time = 46 ms)
--Este es el tiempo real de ejecución de la consulta SELECT ProductKey, SUM(SalesAmount) SalesAmount, SUM(OrderQuantity) ct FROM dbo.FactResellerSalesXL GROUP BY ProductKey.
--El CPU time indica cuánto tiempo de CPU se usó para procesar la consulta (16 ms).
--El elapsed time es el tiempo total desde que la consulta comenzó hasta que terminó, incluyendo la espera por recursos del sistema, E/S, etc. (46 ms).
--La diferencia entre CPU time y elapsed time sugiere que hubo cierta latencia, probablemente por el acceso a datos desde la memoria o almacenamiento.


--ADD CS INDEX -- TAKES 3 mins 
CREATE CLUSTERED COLUMNSTORE INDEX [CS_IDX_FactResellerSalesXL_CCI] ON [dbo].[FactResellerSalesXL]

USE AdventureWorksDW2022;  
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON;
DBCC FREEPROCCACHE
	SELECT ProductKey, sum(SalesAmount) SalesAmount, sum(OrderQuantity) ct
	FROM dbo.FactResellerSalesXL
	GROUP BY ProductKey
SET STATISTICS IO OFF
SET STATISTICS TIME OFF;
--(334 rows affected)
--Table 'FactResellerSalesXL'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 77, lob physical reads 3, lob page server reads 0, lob read-ahead reads 100, lob page server read-ahead reads 0.
--Table 'FactResellerSalesXL'. Segment reads 1, segment skipped 0.
		--Segment reads 1
		--Indica que SQL Server leyó 1 segmento completo de datos.
		--Un segmento es un conjunto de filas procesadas juntas, optimizando el uso de CPU y memoria.
		--Este comportamiento es común en Columnstore Indexes, donde SQL Server divide los datos en segmentos comprimidos para mejorar el rendimiento.

		--Segment skipped 0
		--Significa que no se omitió ningún segmento.
		--Si SQL Server detecta que ciertos segmentos no son necesarios para la consulta (por ejemplo, mediante Segment Elimination), los salta para mejorar la eficiencia.
		--En este caso, se procesó todo el segmento sin descartes

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 4 ms.

--LETS LOOK AT INSIGHTS
--LOOK AT COLUMN STORE SEGMENTS
--------------------------------------------------------------------------------------------------
SELECT * FROM sys.column_store_segments

SELECT i.name, p.object_id, p.index_id, i.type_desc,   
    COUNT(*) AS number_of_segments  
FROM sys.column_store_segments AS s   
INNER JOIN sys.partitions AS p   
    ON s.hobt_id = p.hobt_id   
INNER JOIN sys.indexes AS i   
    ON p.object_id = i.object_id  
WHERE i.type = 5 OR i.type = 6  
GROUP BY i.name, p.object_id, p.index_id, i.type_desc ;  
GO  

--SELECT * FROM dbo.FactResellerSalesXL
--select * from INFORMATION_SCHEMA.COLUMNS ih where ih.TABLE_NAME = 'FactResellerSalesXL'
--------------------------------------------------------------------------------------------------

DROP INDEX [CS_IDX_FactResellerSalesXL_CCI] ON [dbo].[FactResellerSalesXL];
DROP TABLE FactResellerSalesXL;



--2
-- Create indexes on the DimDate table
USE DemoDW;
GO
CREATE CLUSTERED INDEX cids_Dimdate_DateKey ON DimDate(DateKey);
CREATE NONCLUSTERED INDEX idx_DimDate_MonthNumberOfYear ON DimDate(MonthNumberOfYear);
CREATE NONCLUSTERED INDEX idx_DimDate_CalendarYear ON DimDate(CalendarYear);


-- Create indexes on the DimCustomer table
CREATE CLUSTERED INDEX cids_DimCustomer_CustomerKey ON DimCustomer(CustomerKey);
CREATE NONCLUSTERED INDEX idx_DimCustomer_CustomerName ON DimCustomer(CustomerName);
CREATE NONCLUSTERED INDEX idx_DimCustomer_CustomerType ON DimCustomer(CustomerType);

-- Create indexes on the DimProduct table
CREATE CLUSTERED INDEX cids_DimProduct_ProductKey ON DimProduct(ProductKey);
CREATE NONCLUSTERED INDEX idx_DimProduct_ProductName ON DimProduct(ProductName);

-- Create a fact table
SELECT d.DateKey, c.CustomerKey, p.ProductKey, d.DayNumberOfWeek Quantity, d.DayNumberOfMonth SalesAmount
INTO FactOrder
FROM DimDate d
CROSS JOIN DimCustomer c
CROSS JOIN DimProduct p;

-- View index usage and execution statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
DBCC FREEPROCCACHE
SELECT d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName, SUM(o.Quantity) ItemsSold, SUM(o.SalesAmount) TotalRevenue
FROM FactOrder o
JOIN DimDate d ON o.DateKey = d.DateKey
JOIN DimCustomer c ON o.CustomerKey = c.CustomerKey
JOIN DimProduct p ON o.ProductKey = p.ProductKey
WHERE d.FullDateAlternateKey BETWEEN (DATEADD(month, -6, getdate())) AND (getdate())
GROUP BY d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName
ORDER BY d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName;
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
--(21021 rows affected)
--Table 'FactOrder'. Scan count 9, logical reads 21703,
--Table 'DimCustomer'. Scan count 9, logical reads 4, 
--Table 'DimProduct'. Scan count 6, logical reads 16, 
--Table 'DimDate'. Scan count 4, logical reads 19, 
--Table 'Worktable'. Scan count 0, logical reads 0, 
-- SQL Server Execution Times:
--   CPU time = 2002 ms,  elapsed time = 424 ms.

-- Create traditional indexes on the fact table
CREATE CLUSTERED INDEX cids_FactOrder_DateKey ON FactOrder(DateKey);
CREATE NONCLUSTERED INDEX cids_FactOrder_CustomerKey ON FactOrder(CustomerKey);
CREATE NONCLUSTERED INDEX cids_FactOrder_ProductKey ON FactOrder(ProductKey);


-- Test the traditional indexes
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
DBCC FREEPROCCACHE
SELECT d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName, SUM(o.Quantity) ItemsSold, SUM(o.SalesAmount) TotalRevenue
FROM FactOrder o
JOIN DimDate d ON o.DateKey = d.DateKey
JOIN DimCustomer c ON o.CustomerKey = c.CustomerKey
JOIN DimProduct p ON o.ProductKey = p.ProductKey
WHERE d.FullDateAlternateKey BETWEEN (DATEADD(month, -6, getdate())) AND (getdate())
GROUP BY d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName
ORDER BY d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName;
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
--Table 'FactOrder'. Scan count 181, logical reads 7690
--Table 'DimCustomer'. Scan count 9, logical reads 4, 
--Table 'DimProduct'. Scan count 9, logical reads 16, 
--Table 'DimDate'. Scan count 9, logical reads 19, 
-- SQL Server Execution Times:
--   CPU time = 2437 ms,  elapsed time = 522 ms.


-- CREATE A COPY OF THE FACT TABLE WITH NO INDEXES
SELECT *
INTO FactOrderCS
FROM FactOrder;


-- Create a columnstore index on the copied table
CREATE COLUMNSTORE INDEX csidx_FactOrderCS ON FactOrderCS(DateKey, CustomerKey, ProductKey, Quantity, SalesAmount);

-- Test the columnstore index
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
DBCC FREEPROCCACHE
SELECT d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName, SUM(o.Quantity) ItemsSold, SUM(o.SalesAmount) TotalRevenue
FROM FactOrderCS o
JOIN DimDate d ON o.DateKey = d.DateKey
JOIN DimCustomer c ON o.CustomerKey = c.CustomerKey
JOIN DimProduct p ON o.ProductKey = p.ProductKey
WHERE d.FullDateAlternateKey BETWEEN (DATEADD(month, -6, getdate())) AND (getdate())
GROUP BY d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName
ORDER BY d.CalendarYear, d.MonthNumberOfYear, c.CustomerType, p.ProductName;
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

--(21021 rows affected)
--Table 'FactOrderCS'. Scan count 16, logical reads 0, 
--Table 'FactOrderCS'. Segment reads 7, segment skipped 2.
--Table 'DimCustomer'. Scan count 8, logical reads 4, 
--Table 'DimDate'. Scan count 9, logical reads 19, 
--SQL Server Execution Times:
--   CPU time = 406 ms,  elapsed time = 193 ms.


----------------------------
--El **segundo resultado** es significativamente mejor en términos de rendimiento, y la mejora se debe a la implementación de los índices **Columnstore**. Aquí están las razones clave:  

--### Comparación de métricas clave:
--1. **Lecturas lógicas (Logical Reads)**  
--   - En el **primer resultado**, la tabla `FactOrder` tiene **7690 lecturas lógicas**.  
--   - En el **segundo resultado**, `FactOrderCS` tiene **0 lecturas lógicas** (porque usa segment reads en Columnstore, lo que reduce el I/O de páginas de datos).  

--2. **Uso de CPU y tiempo de ejecución:**  
--   - **Primer resultado:** CPU **2437 ms**, tiempo total **522 ms**.  
--   - **Segundo resultado:** CPU **406 ms**, tiempo total **193 ms**.  
--   - La reducción del uso de CPU (de 2437 ms a 406 ms) y del tiempo de ejecución (de 522 ms a 193 ms) indica una optimización significativa.  

--3. **Scan count y segment reads:**  
--   - `FactOrderCS` en el segundo resultado muestra **segment reads (7) y segment skipped (2)**, lo que indica que el índice Columnstore está funcionando de manera eficiente, evitando leer segmentos innecesarios.  
--   - En el primer resultado, `FactOrder` realiza **181 escaneos de tabla**, lo que es mucho más costoso en términos de I/O.  

--### Conclusión:
--El **segundo resultado es claramente superior** porque los índices **Columnstore** reducen las lecturas lógicas, mejoran la compresión de datos y permiten una ejecución más eficiente, reduciendo tanto el uso de CPU como el tiempo de ejecución.  

--Si tu carga de trabajo implica consultas analíticas y operaciones de agregación sobre grandes volúmenes de datos, **los índices Columnstore son la mejor opción**.


----------------------------