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
  {"Id_Rol_Solicitud": 5, "Cantidad": 1},
  {"Id_Rol_Solicitud": 6, "Cantidad": 2}
]';

EXEC SP_Solicitud_Equipo
  @Nombre = 'Solicitud de 1 programador y 2 Recepcionistas',
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


BEGIN
EXEC SP_Propuesta_De_Seleccion @Id_Solicitud = 6;
END


CREATE PROCEDURE SP_Propuesta_De_Seleccion
  @Id_Solicitud BIGINT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;  
  BEGIN TRY

    -- Variables
    DECLARE @Cont_Solitudes BIGINT;
    DECLARE @Num_Solicitudes INT;
    DECLARE @Id_Rol_Solicitud BIGINT;
    DECLARE @Solicitud_Cantidad_Personas BIGINT;
    DECLARE @Cont_Persona INT;
    DECLARE @Numero_Equipos_Perfil INT;
    DECLARE @Cont_Equipos INT;
    DECLARE @Num_Equipos_Surtir INT;
    DECLARE @Tipo_Equipo_Surtir VARCHAR(300);
    DECLARE @Cont_Equipo_Surtir INT;
    DECLARE @Seleccion_Id_Equipo BIGINT;
    DECLARE @Rol_Persona VARCHAR(20);

    -- Tabla de prioridades
    DROP TABLE IF EXISTS #Prioridades;
    CREATE TABLE #Prioridades(
        Id_Prioridad BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Id_Rol BIGINT NOT NULL
    );

    INSERT INTO #Prioridades (Id_Rol) VALUES 
    (2), (1), (5), (3), (4), (6);

    -- Tabla de solicitudes
    DROP TABLE IF EXISTS #Solicitudes;
    CREATE TABLE #Solicitudes(
        Id_Solicitud BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Id_Rol BIGINT NOT NULL,
        Cantidad BIGINT NOT NULL,
        Prioridad BIGINT NOT NULL
    );

    INSERT INTO #Solicitudes (Id_Rol, Cantidad, Prioridad)
    SELECT 
        DS.Id_Rol_Solicitud,
        DS.Cantidad,
        (
            SELECT P.Id_Prioridad
            FROM #Prioridades AS P
            WHERE P.Id_Rol = DS.Id_Rol_Solicitud
        ) AS Prioridad
    FROM Solicitudes AS S
    INNER JOIN DetalleSolicitudes AS DS 
        ON S.Id_Solicitud = DS.Id_Solicitud 
    WHERE S.Estatus = 'Pendiente'
      AND S.Id_Solicitud = @Id_Solicitud
    ORDER BY Prioridad;

    -- Tabla de requerimientos por perfil
    DROP TABLE IF EXISTS #Requerimientos_Perfiles;
    CREATE TABLE #Requerimientos_Perfiles(
        Id_Requerimient_Perfil BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Id_Rol BIGINT NOT NULL,
        Objeto VARCHAR(250) NOT NULL,
        Cantidad INT NOT NULL
    );

    INSERT INTO #Requerimientos_Perfiles (Id_Rol, Objeto, Cantidad)
    SELECT 
        PR.Id_Rol_Perfil_Requerimiento,
        JSONData.Objeto,
        JSONData.Cantidad
    FROM PerfilesRequerimientos AS PR
    CROSS APPLY OPENJSON(PR.requisitos)
    WITH (
        Objeto VARCHAR(500) '$.Objeto',
        Cantidad FLOAT '$.Cantidad'
    ) AS JSONData;

    -- Historial de asignaciones
    DROP TABLE IF EXISTS #Historial_Asignado;
    CREATE TABLE #Historial_Asignado(
        Id_Historial_Asignado BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Id_Equipo BIGINT NOT NULL
    );

    INSERT INTO #Historial_Asignado (Id_Equipo)
    SELECT HA1.Id_Equipo
    FROM HistorialAsignaciones AS HA1
    WHERE ha1.Estatus = 'Asignado'
      AND HA1.Id_Historial_Asignacion = (
        SELECT MAX(HA2.Id_Historial_Asignacion)
        FROM HistorialAsignaciones AS HA2
        WHERE HA2.Id_Equipo = HA1.Id_Equipo
    );

    -- Equipos sin asignar
    DROP TABLE IF EXISTS #Sin_Asignar;
    CREATE TABLE #Sin_Asignar(
        Id_Sin_Asignar BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Id_Equipo BIGINT NOT NULL, 
        Tipo_Equipo VARCHAR(300),
        Modelo VARCHAR(100),
        Numero_Serie VARCHAR(50),
        Especificaciones NVARCHAR(MAX),
        Costo FLOAT
    );

    INSERT INTO #Sin_Asignar (Id_Equipo, Tipo_Equipo, Modelo, Numero_Serie, Especificaciones, Costo)
    SELECT E.Id_Equipo, E.Tipo_Equipo, E.Modelo, E.Numero_Serie, E.Especificaciones, E.Costo
    FROM Equipos AS E
    WHERE E.Id_Equipo NOT IN (
        SELECT HA.Id_Equipo FROM #Historial_Asignado AS HA
    )
    ORDER BY E.Costo, E.Tipo_Equipo;

    -- Tabla con equipo asignado
    DROP TABLE IF EXISTS #Con_Equipo;
    CREATE TABLE #Con_Equipo (
        Id_Con_Equipo BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Rol VARCHAR(20) NOT NULL,
        Persona INT NOT NULL,
        Id_Equipo BIGINT NOT NULL,
        Tipo_Equipo VARCHAR(300) NOT NULL,
        Modelo VARCHAR(100) NOT NULL,
        Numero_Serie VARCHAR(50) NOT NULL,
        Costo FLOAT NOT NULL,
        Especificaciones NVARCHAR(MAX) NOT NULL
    );

    -- Tabla sin equipo asignado
    DROP TABLE IF EXISTS #Sin_Equipo;
    CREATE TABLE #Sin_Equipo (
        Id_Sin_Equipo BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        Rol VARCHAR(20) NOT NULL,
        Tipo_Equipo VARCHAR(300) NOT NULL,
        Persona INT NOT NULL
    );

	--SELECT * FROM #Requerimientos_Perfiles AS RP WHERE RP.Id_Rol IN (5,6); 

    -- Inicia algoritmo
    SELECT @Num_Solicitudes = COUNT(Id_Solicitud) FROM #Solicitudes;
    SELECT @Cont_Solitudes = 1;

    WHILE @Cont_Solitudes <= @Num_Solicitudes
    BEGIN
        SELECT @Id_Rol_Solicitud = S.Id_Rol, @Solicitud_Cantidad_Personas = S.Cantidad
        FROM #Solicitudes AS S WHERE S.Id_Solicitud = @Cont_Solitudes;

        SELECT @Rol_Persona = R.Nombre
        FROM Roles AS R WHERE R.Id_Rol = @Id_Rol_Solicitud;

		--SELECT (SELECT R.Nombre FROM Roles AS R WHERE R.Id_Rol = @Id_Rol_Solicitud) AS Rol,@Solicitud_Cantidad_Personas AS Personas;

        SELECT @Cont_Persona = 1;
        WHILE @Cont_Persona <= @Solicitud_Cantidad_Personas
        BEGIN
            SELECT @Numero_Equipos_Perfil = COUNT(RP.Id_Requerimient_Perfil)
            FROM #Requerimientos_Perfiles AS RP 
            WHERE RP.Id_Rol = @Id_Rol_Solicitud;

			DROP TABLE IF EXISTS #Lista_Equipo;
			CREATE TABLE #Lista_Equipo(
				Id_Lista_Equipo BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
				Objeto VARCHAR(250) NOT NULL,
				Cantidad INT NOT NULL
			);

			INSERT INTO #Lista_Equipo (Objeto, Cantidad)
            SELECT
			RP.Objeto,
			RP.Cantidad
		    FROM #Requerimientos_Perfiles AS RP 
            WHERE RP.Id_Rol = @Id_Rol_Solicitud;

			--SELECT @Numero_Equipos_Perfil AS Cantidad_Dispotivos;

            SELECT @Cont_Equipos = 1;
            WHILE @Cont_Equipos <= @Numero_Equipos_Perfil
            BEGIN
                SELECT @Tipo_Equipo_Surtir = LP.Objeto, @Num_Equipos_Surtir = LP.Cantidad
                FROM #Lista_Equipo AS LP
                WHERE LP.Id_Lista_Equipo = @Cont_Equipos;

				--SELECT @Tipo_Equipo_Surtir AS Objeto, @Num_Equipos_Surtir AS Cantidad_Ocupa;

                SELECT @Cont_Equipo_Surtir = 1;
                WHILE @Cont_Equipo_Surtir <= @Num_Equipos_Surtir
                BEGIN
                    SET @Seleccion_Id_Equipo = NULL;

                    SELECT TOP 1 @Seleccion_Id_Equipo = SA.Id_Equipo
                    FROM #Sin_Asignar AS SA
                    WHERE SA.Tipo_Equipo = @Tipo_Equipo_Surtir
                        AND SA.Id_Equipo NOT IN (SELECT CE.Id_Equipo FROM #Con_Equipo AS CE)
                    ORDER BY SA.Costo DESC;

                    IF @Seleccion_Id_Equipo IS NOT NULL
                    BEGIN
                        INSERT INTO #Con_Equipo (Rol, Persona, Id_Equipo, Tipo_Equipo, Modelo, Numero_Serie, Costo, Especificaciones)
                        SELECT @Rol_Persona, @Cont_Persona, SA.Id_Equipo, SA.Tipo_Equipo, SA.Modelo, SA.Numero_Serie, SA.Costo, SA.Especificaciones
                        FROM #Sin_Asignar AS SA
                        WHERE SA.Id_Equipo = @Seleccion_Id_Equipo;
                    END
                    ELSE
                    BEGIN
                        INSERT INTO #Sin_Equipo (Rol, Tipo_Equipo, Persona)
                        VALUES (@Rol_Persona, @Tipo_Equipo_Surtir, @Cont_Persona);
                    END

                    SET @Cont_Equipo_Surtir = @Cont_Equipo_Surtir + 1;
                END

                SET @Cont_Equipos = @Cont_Equipos + 1;
            END

            DROP TABLE IF EXISTS #Lista_Equipo;
            SET @Cont_Persona = @Cont_Persona + 1;
        END

        SET @Cont_Solitudes = @Cont_Solitudes + 1;
    END

    SELECT * FROM #Con_Equipo;
	SELECT * FROM #Sin_Equipo;

    DROP TABLE IF EXISTS #Prioridades;
    DROP TABLE IF EXISTS #Solicitudes;
    DROP TABLE IF EXISTS #Requerimientos_Perfiles;
    DROP TABLE IF EXISTS #Historial_Asignado;
    DROP TABLE IF EXISTS #Sin_Asignar;
    DROP TABLE IF EXISTS #Con_Equipo;
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

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
  END CATCH
END;
GO