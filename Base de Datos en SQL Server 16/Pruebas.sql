/*
PRUEBAS DE SP
*/
SELECT HA.*,E.Tipo_Equipo FROM HistorialAsignaciones AS HA INNER JOIN Equipos AS E ON HA.Id_Equipo = E.Id_Equipo ORDER BY E.Tipo_Equipo;
SELECT * FROM Equipos;

BEGIN
	EXEC SP_Historial_Inventario
		@Tipo_Equipo = NULL,
		@Estatus = NULL;
END
GO

BEGIN
	EXEC SP_Crear_Equipo 
		@Tipo_Equipo = 'Prueba',
		@Modelo = 'Prueba',
		@Numero_Serie = 'Prueba',
		@Costo = 1.00,
		@Especificaciones = '[{"Procesador": "Prueba", "RAM": "Prueba", "Almacenamiento": "Prueba"}]';
	
	SELECT 
	* 
	FROM Equipos;
END
GO

BEGIN
DECLARE @DetalleSolicitudes NVARCHAR(MAX);

SET @DetalleSolicitudes = '[
  {"Id_Rol_Solicitud": 5, "Cantidad": 20},
  {"Id_Rol_Solicitud": 3, "Cantidad": 20}
]';

EXEC SP_Solicitud_Equipo
  @Nombre = 'Solicitud de 20 programadores y 20 contadores',
  @ID_Solicitante = 1,
  @DetalleSolicitudes = @DetalleSolicitudes;

  SELECT* FROM Solicitudes;
  SELECT * FROM DetalleSolicitudes;
END;
GO

BEGIN
EXEC SP_Todas_Solicitudes;
END
GO

BEGIN
EXEC SP_Detalle_Solicitud
  @Id_Solicitud = 6
END;
GO






CREATE PROCEDURE SP_Propuesta_De_Seleccion(
  @Id_Solicitud BIGINT = NULL
)
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;  
  BEGIN TRY
		SELECT 
			pr.Id_Rol_Perfil_Requerimiento,
			JSONData.Objeto,
			JSONData.Cantidad
		FROM PerfilesRequerimientos AS PR
		CROSS APPLY OPENJSON(PR.requisitos)
		WITH (
			Objeto VARCHAR(500) '$.Objeto',
			Cantidad FLOAT '$.Cantidad'
		) AS JSONData;


		SELECT 
		S.Id_Solicitud,
		S.Nombre,
		(SELECT 
		 E.Nombre_Completo 
		 FROM Empleados AS E 
		 WHERE E.Id_Empleado = S.Id_Solicitante
		 ) AS Nombre_Completo,
		 S.Estatus,
		 (
		  SELECT 
		  R.Nombre
		  FROM Roles AS R
		  WHERE
		  R.Id_Rol=DS.Id_Rol_Solicitud
		 ) AS Rol,
		 DS.Cantidad
		FROM 
		Solicitudes AS S 
		INNER JOIN DetalleSolicitudes AS DS 
		ON S.Id_Solicitud = DS.Id_Solicitud 
		AND S.Estatus = 'Pendiente' 


	  DROP TABLE IF EXISTS #Historial_Asignado;

	  CREATE TABLE #Historial_Asignado(
		Id_Historial_Asignado BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
		Id_Equipo BIGINT NOT NULL
	  );
		
	  INSERT INTO #Historial_Asignado(
		Id_Equipo
	  )
	  SELECT
		HA1.Id_Equipo
	  FROM 
		HistorialAsignaciones AS HA1
	  WHERE
		ha1.Estatus = 'Asignado'
		AND
		HA1.Id_Historial_Asignacion = (
										SELECT
										  MAX(HA2.Id_Historial_Asignacion)
										FROM 
										  HistorialAsignaciones AS HA2
										WHERE
										  HA2.Id_Equipo = HA1.Id_Equipo
									  );

		  SELECT
		  E.Tipo_Equipo,
		  E.Modelo,
		  E.Numero_Serie,
		  E.Especificaciones,
		  E.Costo
		  FROM 
			Equipos AS E
		  WHERE
			E.Id_Equipo NOT IN(
								SELECT
								  HA.Id_Equipo
								FROM
								  #Historial_Asignado AS HA
							   );

		DROP TABLE IF EXISTS #Historial_Asignado;


	  DROP TABLE IF EXISTS #Seleccionados;
	  CREATE TABLE #Seleccionados(
		Id_Seleccionado BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
		Tipo_Equipo VARCHAR(300) NOT NULL,
		Modelo VARCHAR(100) NOT NULL,
		Numero_Serie VARCHAR(50) NOT NULL,
		Costo FLOAT NOT NULL,
		Especificaciones NVARCHAR(MAX) NOT NULL
	  );
	  DROP TABLE IF EXISTS #Seleccionados;

	  DROP TABLE IF EXISTS #Sin_Equipo;
	  CREATE TABLE #Sin_Equipo(
		Id_Sin_Equipo BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
		Id_Rol BIGINT NOT NULL
	  );
	  DROP TABLE IF EXISTS #Sin_Equipo;


  COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
    SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
  END CATCH
END
GO