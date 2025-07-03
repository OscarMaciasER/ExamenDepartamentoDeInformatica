CREATE DATABASE examenDepartamentoDeInformatica
GO

USE examenDepartamentoDeInformatica;
GO

CREATE TABLE Equipos(
  Id_Equipo BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Tipo_Equipo VARCHAR(300) NOT NULL,
  Modelo VARCHAR(100) NOT NULL,
  Numero_Serie VARCHAR(50) NOT NULL,
  Costo FLOAT NOT NULL,
  Especificaciones NVARCHAR(MAX) NOT NULL
);

CREATE TABLE Roles(
  Id_Rol BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Nombre VARCHAR(20) NOT NULL
);

CREATE TABLE PerfilesRequerimientos(
  Id_Perfil_Requerimiento BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Id_Rol_Perfil_Requerimiento BIGINT NOT NULL,
  requisitos NVARCHAR(MAX) NOT NULL,
  FOREIGN KEY(Id_Rol_Perfil_Requerimiento) REFERENCES Roles(Id_Rol)
);

CREATE TABLE Empleados(
  Id_Empleado BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Id_Rol_Empleado BIGINT NOT NULL,
  Nombre_Completo VARCHAR(100) NOT NULL,
  Telefono VARCHAR(15) NOT NULL,
  FOREIGN KEY (Id_Rol_Empleado) REFERENCES Roles(Id_Rol)
);

CREATE TABLE Solicitudes(
  Id_Solicitud BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Nombre VARCHAR(500) NOT NULL,
  Id_Solicitante BIGINT NOT NULL,
  Estatus VARCHAR(50) NOT NULL,
  FOREIGN KEY(Id_Solicitante) REFERENCES Empleados(Id_Empleado)
);

CREATE TABLE DetalleSolicitudes(
  Id_Detalle_Solicitud BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Id_Solicitud BIGINT NOT NULL,
  Id_Rol_Solicitud BIGINT NOT NULL,
  Cantidad INT NOT NULL,
  FOREIGN KEY(Id_Solicitud) REFERENCES Solicitudes(Id_Solicitud)
);

CREATE TABLE HistorialAsignaciones(
  Id_Historial_Asignacion BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Id_Responsable_TI BIGINT NOT NULL,
  Id_Asignado_A_Empleado BIGINT NOT NULL,
  Id_Equipo BIGINT NOT NULL,
  Estatus VARCHAR(15) NOT NULL,
  FechaRegistro DATETIME NOT NULL,
  FOREIGN KEY(Id_Responsable_TI) REFERENCES Empleados(Id_Empleado),
  FOREIGN KEY(Id_Asignado_A_Empleado) REFERENCES Empleados(Id_Empleado),
  FOREIGN KEY(Id_Equipo) REFERENCES Equipos(Id_Equipo)
);
GO



CREATE PROCEDURE SP_Historial_Inventario(
  @Tipo_Equipo VARCHAR(300) = NULL,
  @Estatus VARCHAR(20)= NULL
)
AS
BEGIN
  SET NOCOUNT ON;
  DROP TABLE IF EXISTS #Historial_Asignado;
		
  CREATE TABLE #Historial_Asignado(
    Id_Historial_Asignado BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    Asignado_A_Empleado VARCHAR(100) NOT NULL,
	Responsable_TI VARCHAR(100) NOT NULL,
	Id_Equipo BIGINT NOT NULL,
    Tipo_Equipo VARCHAR(300) NOT NULL,
	FechaRegistro DATETIME NOT NULL
  );
		
  INSERT INTO #Historial_Asignado(
    Asignado_A_Empleado,
	Responsable_TI,
	Id_Equipo,
	Tipo_Equipo,
	FechaRegistro
  )
  SELECT
	(
      SELECT 
	    E1.Nombre_Completo 
	  FROM 
	    Empleados AS E1 
	  WHERE 
	    E1.Id_Empleado = HA1.Id_Asignado_A_Empleado
	) AS Asignado_A_Empleado,
	(
      SELECT
	    E2.Nombre_Completo
	  FROM
	    Empleados AS E2
	  WHERE
	    E2.Id_Empleado = HA1.Id_Responsable_TI
	) AS Responsable_TI,
	HA1.Id_Equipo,
	(
      SELECT
	    EQ.Tipo_Equipo
	  FROM 
	    Equipos AS EQ
	  WHERE 
	    EQ.Id_Equipo = HA1.Id_Equipo
	) AS Tipo_Equipo,
	HA1.FechaRegistro
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

	IF @Estatus = 'Asignado'
	BEGIN
	  SELECT
	    HA.Responsable_TI,
		HA.Asignado_A_Empleado,
		HA.Tipo_Equipo,
		HA.FechaRegistro
	  FROM
		#Historial_Asignado AS HA
	  WHERE
	      @Tipo_Equipo IS NULL
		  OR
	      HA.Tipo_Equipo = @Tipo_Equipo 
	END
	ELSE IF @Estatus = 'Disponible'
	BEGIN
	  SELECT
	    '' AS Responsable_TI,
		'' AS Asignado_A_Empleado,
		E.Tipo_Equipo,
		'' AS FechaRegistro
	  FROM 
	    Equipos AS E
	  WHERE
	    (
		  E.Tipo_Equipo = @Tipo_Equipo
		  OR
		  @Tipo_Equipo IS NULL
		)
		AND
		E.Id_Equipo NOT IN(
							SELECT
							  HA.Id_Equipo
							FROM
							  #Historial_Asignado AS HA
						   );

	END
	ELSE IF @Estatus IS NULL AND @Tipo_Equipo IS NULL
	BEGIN

	  DROP TABLE IF EXISTS #No_Asignados;
			
	  CREATE TABLE #No_Asignados(
	    Id_No_Asignados BIGINT PRIMARY KEY IDENTITY(1,1) NOT NULL,
		Asignado_A_Empleado VARCHAR(100) NULL,
		Responsable_TI VARCHAR(100) NULL,
		Id_Equipo BIGINT NOT NULL,
		Tipo_Equipo VARCHAR(300) NOT NULL,
		FechaRegistro DATETIME NULL
	  );

	  INSERT INTO #No_Asignados(
	    Asignado_A_Empleado,
		Responsable_TI,
		Id_Equipo,
		Tipo_Equipo,
		FechaRegistro
	  )
	  SELECT
	    '' AS Asignado_A_Empleado,
	    '' AS Responsable_TI,
		E.Id_Equipo AS Id_Equipo,
	    E.Tipo_Equipo, 
		'' AS FechaRegistro
	  FROM 
	    Equipos AS E
	  WHERE
		E.Id_Equipo NOT IN(
						     SELECT
							   HA.Id_Equipo
							 FROM
							   #Historial_Asignado AS HA
						   )


		SELECT 
		  HA.Responsable_TI,
		  HA.Asignado_A_Empleado,
		  HA.Tipo_Equipo,
		  HA.FechaRegistro
		FROM
		  #Historial_Asignado AS HA
		UNION ALL
		SELECT
		  NA.Responsable_TI,
		  NA.Asignado_A_Empleado,
		  NA.Tipo_Equipo,
		  NULL AS FechaRegistro
		FROM 
		  #No_Asignados AS NA;
	END

	DROP TABLE IF EXISTS #No_Asignados;
	DROP TABLE IF EXISTS #Historial_Asignado;
END
GO


CREATE PROCEDURE SP_Crear_Equipo(
  @Tipo_Equipo VARCHAR(300) = NULL,
  @Modelo VARCHAR(10) = NULL,
  @Numero_Serie VARCHAR(50) = NULL,
  @Costo FLOAT = NULL,
  @Especificaciones NVARCHAR(MAX) = NULL
)
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRANSACTION;  
  BEGIN TRY
    INSERT INTO Equipos VALUES(
                                  @Tipo_Equipo,
							      @Modelo,
							      @Numero_Serie,
								  @Costo,
								  @Especificaciones
							  );
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


CREATE PROCEDURE SP_Solicitud_Equipo(
  @Nombre VARCHAR(500) = NULL,
  @ID_Solicitante BIGINT = NULL,
  @DetalleSolicitudes NVARCHAR(MAX) = NULL
)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @ID_Solicitud BIGINT = NULL;

  BEGIN TRANSACTION;  
  BEGIN TRY

    INSERT INTO Solicitudes VALUES(
	                                @Nombre,
                                    @ID_Solicitante,
								    'Pendiente'
							    );
     SELECT 
     @ID_Solicitud = MAX(S.Id_Solicitud)
	 FROM 
	   Solicitudes AS S;

     INSERT INTO DetalleSolicitudes(
       Id_Solicitud,
	   Id_Rol_Solicitud,
       Cantidad
     )
     SELECT
       @ID_Solicitud,
       Id_Rol_Solicitud,
       Cantidad
     FROM OPENJSON(@DetalleSolicitudes)
     WITH(
       Id_Solicitud BIGINT,
       Id_Rol_Solicitud BIGINT,
       Cantidad INT
     );

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


CREATE PROCEDURE SP_Todas_Solicitudes
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    S.Nombre,
    (
      SELECT 
	    E.Nombre_Completo 
	  FROM 
	     Empleados AS E
	  WHERE
	     E.Id_Empleado = S.Id_Solicitante
    ) AS Solicitante,
    S.Estatus
  FROM 
    Solicitudes AS S 
END
GO


CREATE PROCEDURE SP_Detalle_Solicitud(
  @Id_Solicitud BIGINT = NULL
)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
  (
    SELECT 
	  R.Nombre
	FROM
	  Roles AS R
    WHERE
	  R.Id_Rol = DS.Id_Rol_Solicitud
  ) AS Rol,
  DS.Cantidad
  FROM 
    DetalleSolicitudes AS DS
  WHERE
    DS.Id_Solicitud = @Id_Solicitud;
END
GO

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

CREATE PROCEDURE SP_Tipo_Equipos
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    DISTINCT
    E.Tipo_Equipo
  FROM 
    Equipos AS E 
END
GO

CREATE PROCEDURE SP_Estados
AS
BEGIN
  SET NOCOUNT ON;

  SELECT 'Asignado' AS Estatus
  UNION ALL
  SELECT 'Disponible' AS Estatus
END
GO


/*
Datos
*/
INSERT INTO Roles (Nombre)
VALUES
  ('Root'),
  ('Director'),
  ('Contador'),
  ('Administrador'),
  ('Programacion'),
  ('Recepcion');
GO


INSERT INTO Empleados (Id_Rol_Empleado, Nombre_Completo, Telefono)
VALUES 
   (1, 'Juan Perez', '1234567890'),
   (2, 'Ana Garcia', '0987654321'),
   (3, 'Pedro Ramirez', '555-8765-4321'),
   (3, 'Ana Martinez', '555-1122-3344'),
   (6, 'Jorge Lopez', '555-5566-7788');
GO

INSERT INTO Equipos (Tipo_Equipo, Modelo, Numero_Serie, Costo, Especificaciones)
VALUES 
  -- Laptop
  ('Laptop', 'HP123', 'SN123456', 800.00, '[{"Objeto": "Procesador", "Descripcion": "Intel i7"}, {"Objeto": "RAM", "Descripcion": "16GB"}, {"Objeto": "Almacenamiento", "Descripcion": "512GB SSD"}]'),
  ('Laptop', 'Lenovo X1', 'SN234567', 1200.00, '[{"Objeto": "Procesador", "Descripcion": "Intel i5"}, {"Objeto": "RAM", "Descripcion": "8GB"}, {"Objeto": "Almacenamiento", "Descripcion": "256GB SSD"}]'),
  ('Laptop', 'Apple MacBook', 'SN789012', 1800.00, '[{"Objeto": "Procesador", "Descripcion": "M1 Chip"}, {"Objeto": "RAM", "Descripcion": "16GB"}, {"Objeto": "Almacenamiento", "Descripcion": "1TB SSD"}]'),
  ('Laptop', 'Dell Inspiron', 'SN123789', 950.00, '[{"Objeto": "Procesador", "Descripcion": "Intel i7"}, {"Objeto": "RAM", "Descripcion": "8GB"}, {"Objeto": "Almacenamiento", "Descripcion": "512GB SSD"}]'),
  ('Laptop', 'Acer Predator', 'SN234890', 1400.00, '[{"Objeto": "Procesador", "Descripcion": "Intel i9"}, {"Objeto": "RAM", "Descripcion": "16GB"}, {"Objeto": "Almacenamiento", "Descripcion": "1TB SSD"}]'),
  -- Monitor
  ('Monitor', 'Dell 24', 'SN345678', 200.00, '[{"Objeto": "Dimension", "Descripcion": "24 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1080p"}]'),
  ('Monitor', 'Samsung 27', 'SN456789', 350.00, '[{"Objeto": "Dimension", "Descripcion": "27 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1440p"}]'),
  ('Monitor', 'LG Ultrawide', 'SN345901', 450.00, '[{"Objeto": "Dimension", "Descripcion": "34 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1440p"}]'),
  ('Monitor', 'BenQ GW2780', 'SN456902', 220.00, '[{"Objeto": "Dimension", "Descripcion": "27 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1080p"}]'),
  ('Monitor', 'BenQ ZOWIE XL2411', 'SN9015678', 250.00, '[{"Objeto": "Dimension", "Descripcion": "24 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1080p"}, {"Objeto": "Frecuencia", "Descripcion": "144Hz"}]'),
  ('Monitor', 'Acer Predator X34', 'SN8904567', 900.00, '[{"Objeto": "Dimension", "Descripcion": "34 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1440p"}, {"Objeto": "Frecuencia", "Descripcion": "120Hz"}, {"Objeto": "Curvado", "Descripcion": "Si"}]'),
  ('Monitor', 'ASUS ROG Swift PG259QN', 'SN0126789', 600.00, '[{"Objeto": "Dimension", "Descripcion": "24.5 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1080p"}, {"Objeto": "Frecuencia", "Descripcion": "360Hz"}, {"Objeto": "Tecnologia", "Descripcion": "G-Sync"}]'),  
  -- Teclado
  ('Teclado', 'Logitech K120', 'SN567890', 20.00, '[{"Objeto": "Tipo", "Descripcion": "Mecanico"}, {"Objeto": "Conexion", "Descripcion": "USB"}]'),
  ('Teclado', 'Corsair K95', 'SN567901', 120.00, '[{"Objeto": "Tipo", "Descripcion": "Mecanico"}, {"Objeto": "Caracteristicas", "Descripcion": "RGB"}]'),
  ('Teclado', 'Logitech G Pro X', 'SN2348902', 140.00, '[{"Objeto": "Tipo", "Descripcion": "Mecanico"}, {"Objeto": "Switches", "Descripcion": "Intercambiables"}, {"Objeto": "Caracteristicas", "Descripcion": "RGB"}]'),
  ('Teclado', 'Razer BlackWidow V3', 'SN3459012', 120.00, '[{"Objeto": "Tipo", "Descripcion": "Mecanico"}, {"Objeto": "Switches", "Descripcion": "Verdes"}, {"Objeto": "Caracteristicas", "Descripcion": "Retroiluminado RGB"}]'),
  ('Teclado', 'Corsair K70 RGB MK.2', 'SN4560123', 180.00, '[{"Objeto": "Tipo", "Descripcion": "Mecanico"}, {"Objeto": "Switches", "Descripcion": "Cherry MX"}, {"Objeto": "Caracteristicas", "Descripcion": "RGB"}]'),
  -- Mouse
  ('Mouse', 'Logitech M510', 'SN678901', 25.00, '[{"Objeto": "Tipo", "Descripcion": "Inalambrico"}, {"Objeto": "Caracteristicas", "Descripcion": "Ergonomico"}]'),
  ('Mouse', 'Razer DeathAdder', 'SN678902', 40.00, '[{"Objeto": "Tipo", "Descripcion": "Ergonomico"}, {"Objeto": "Caracteristicas", "Descripcion": "RGB, Sensor optico"}]'),
  ('Mouse', 'Logitech MX Master 3', 'SN2345678', 80.00, '[{"Objeto": "Tipo", "Descripcion": "Inalambrico"}, {"Objeto": "Caracteristicas", "Descripcion": "Ergonomico, 4000 DPI, Bluetooth"}]'),
  ('Mouse', 'SteelSeries Rival 600', 'SN3456789', 70.00, '[{"Objeto": "Tipo", "Descripcion": "Inalambrico"}, {"Objeto": "Caracteristicas", "Descripcion": "Sensor dual, 12000 DPI"}]'),
  ('Mouse', 'Corsair Dark Core RGB', 'SN4567890', 90.00, '[{"Objeto": "Tipo", "Descripcion": "Inalambrico"}, {"Objeto": "Caracteristicas", "Descripcion": "Ergonomico, 16000 DPI, RGB"}]'),
  -- Otros
  ('Tablet', 'Samsung Tab', 'SN890123', 450.00, '[{"Objeto": "Dimension", "Descripcion": "10 pulgadas"}, {"Objeto": "Almacenamiento", "Descripcion": "64GB"}]'),
  ('Impresora', 'HP LaserJet', 'SN901234', 150.00, '[{"Objeto": "Tipo", "Descripcion": "Laser"}, {"Objeto": "Dimension", "Descripcion": "A4"}]'),
  ('Proyector', 'Epson XG', 'SN012345', 500.00, '[{"Objeto": "Resolucion", "Descripcion": "Full HD"}, {"Objeto": "Lumenes", "Descripcion": "3000"}]'),
  ('Impresora', 'Canon PIXMA', 'SN901345', 180.00, '[{"Objeto": "Tipo", "Descripcion": "Inyeccion de tinta"}, {"Objeto": "Dimension", "Descripcion": "A4"}]'),
  ('Proyector', 'ViewSonic PA503S', 'SN012456', 350.00, '[{"Objeto": "Resolucion", "Descripcion": "VGA"}, {"Objeto": "Lumenes", "Descripcion": "3600"}]'),
  -- Mas ejemplos
  ('Monitor', 'Samsung Odyssey G7', 'SN2348901', 700.00, '[{"Objeto": "Dimension", "Descripcion": "27 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1440p"}, {"Objeto": "Frecuencia", "Descripcion": "240Hz"}, {"Objeto": "Curvado", "Descripcion": "Si"}, {"Objeto": "Tecnologia", "Descripcion": "QLED"}]'),
  ('Monitor', 'Acer Nitro VG240Y', 'SN9876543', 180.00, '[{"Objeto": "Dimension", "Descripcion": "23.8 pulgadas"}, {"Objeto": "Resolucion", "Descripcion": "1080p"}, {"Objeto": "Frecuencia", "Descripcion": "75Hz"}]'),
  ('Mouse', 'Logitech G Pro Wireless', 'SN2346789', 130.00, '[{"Objeto": "Tipo", "Descripcion": "Inalambrico"}, {"Objeto": "Caracteristicas", "Descripcion": "Sensor HERO, 16K DPI"}]'),
  ('Teclado', 'Razer Huntsman Mini', 'SN7894561', 130.00, '[{"Objeto": "Tipo", "Descripcion": "Mecanico"}, {"Objeto": "Switches", "Descripcion": "Opto-mecanicos"}, {"Objeto": "Caracteristicas", "Descripcion": "RGB, compacto"}]'),
  ('Laptop', 'MSI GF63', 'SN987654', 1100.00, '[{"Objeto": "Procesador", "Descripcion": "Intel i7"}, {"Objeto": "RAM", "Descripcion": "16GB"}, {"Objeto": "Almacenamiento", "Descripcion": "512GB SSD"}]');
GO

INSERT INTO PerfilesRequerimientos (Id_Rol_Perfil_Requerimiento, requisitos)
VALUES
  (1, '[{"Objeto": "Monitor", "Cantidad": 2}, {"Objeto": "Mouse", "Cantidad": 1}, {"Objeto": "Teclado", "Cantidad": 1}, {"Objeto": "Laptop", "Cantidad": 1}]'),
  (2, '[{"Objeto": "Monitor", "Cantidad": 2}, {"Objeto": "Mouse", "Cantidad": 1}, {"Objeto": "Teclado", "Cantidad": 1}, {"Objeto": "Laptop", "Cantidad": 2}, {"Objeto": "Impresora", "Cantidad": 1}, {"Objeto": "Proyector", "Cantidad": 1}]'),
  (3, '[{"Objeto": "Monitor", "Cantidad": 2}, {"Objeto": "Mouse", "Cantidad": 1}, {"Objeto": "Teclado", "Cantidad": 1}, {"Objeto": "Laptop", "Cantidad": 1}]'),
  (4, '[{"Objeto": "Monitor", "Cantidad": 1}, {"Objeto": "Mouse", "Cantidad": 1}, {"Objeto": "Teclado", "Cantidad": 1}, {"Objeto": "Laptop", "Cantidad": 1}]'),
  (5, '[{"Objeto": "Monitor", "Cantidad": 2}, {"Objeto": "Mouse", "Cantidad": 1}, {"Objeto": "Teclado", "Cantidad": 1}, {"Objeto": "Laptop", "Cantidad": 1}]'),
  (6, '[{"Objeto": "Monitor", "Cantidad": 1}, {"Objeto": "Mouse", "Cantidad": 1}, {"Objeto": "Teclado", "Cantidad": 1}, {"Objeto": "Laptop", "Cantidad": 1}, {"Objeto": "Impresora", "Cantidad": 1}]');
GO  

INSERT INTO Solicitudes (Nombre, Id_Solicitante, Estatus)
VALUES 
  ('Solicitud para el nuevo gerente de programacion', 1, 'Aprobada'),
  ('Solicitud para el nuevo director', 1, 'Aprobada'),
  ('Solicitud para dos nuevos contadores', 1, 'Aprobada'),
  ('Solicitud para un nuevo contador', 1, 'Aprobada'),
  ('Solicitud para recepcion', 1, 'Pendiente');
  
INSERT INTO DetalleSolicitudes (Id_Solicitud, Id_Rol_Solicitud, Cantidad)
VALUES 
  (1, 1, 1),  
  (2, 2, 1),
  (3, 3, 2),
  (4, 3, 1),
  (5, 6, 1);
GO

INSERT INTO HistorialAsignaciones (Id_Responsable_TI, Id_Asignado_A_Empleado, Id_Equipo, Estatus, FechaRegistro)
VALUES 
  --Gerente de TI - 5
  (1, 1, 6, 'Asignado', '2020-01-01 10:00:00'),--Monitor
  (1, 1, 7, 'Asignado', '2020-01-01 10:00:00'),--Monitor
  (1, 1, 18, 'Asignado', '2020-01-01 10:00:00'),--Mouse
  (1, 1, 13, 'Asignado', '2020-01-01 10:00:00'),--Teclado
  (1, 1, 1, 'Asignado', '2020-01-01 10:00:00'),--Laptop
  
  --Director - 8
  (1, 2, 8, 'Asignado', '2020-01-01 14:00:00'),--Monitor
  (1, 2, 9, 'Asignado', '2020-01-01 14:00:00'),--Monitor
  (1, 2, 19, 'Asignado', '2020-01-01 14:00:00'),--Mouse
  (1, 2, 14, 'Asignado', '2020-01-01 14:00:00'),--Teclado
  (1, 2, 2, 'Asignado', '2020-01-01 14:00:00'),--Laptop
  (1, 2, 3, 'Asignado', '2020-01-01 14:00:00'),--Laptop
  (1, 2, 25, 'Asignado', '2020-01-01 14:00:00'),--Impresora
  (1, 2, 26, 'Asignado', '2020-01-01 14:00:00'),--Proyector

  --Contador1
  (1, 3, 10, 'Asignado', '2021-02-02 10:00:00'),--Monitor
  (1, 3, 20, 'Asignado', '2021-02-02 10:00:00'),--Mouse
  (1, 3, 15, 'Asignado', '2021-02-02 10:00:00'),--Teclado
  (1, 3, 4, 'Asignado', '2021-02-02 10:00:00'),--Laptop

  --Contador2
  (1, 4, 11, 'Asignado', '2021-02-02 17:00:00'),--Monitor
  (1, 4, 21, 'Asignado', '2021-02-02 17:00:00'),--Mouse
  (1, 4, 16, 'Asignado', '2021-02-02 17:00:00'),--Teclado
  (1, 4, 5, 'Asignado', '2021-02-02 17:00:00'),--Laptop

   --Contador2
  (1, 4, 11, 'Disponible', '2023-06-06 18:00:00'),--Monitor
  (1, 4, 21, 'Disponible', '2023-06-06 18:00:00'),--Mouse
  (1, 4, 16, 'Disponible', '2023-06-06 18:00:00'),--Teclado
  (1, 4, 5, 'Disponible', '2023-06-06 18:00:00'),--Laptop

  --Contador1
  (1, 3, 10, 'Disponible', '2023-10-10 15:00:00'),--Monitor
  (1, 3, 20, 'Disponible', '2023-10-10 15:00:00'),--Mouse
  (1, 3, 15, 'Disponible', '2023-10-10 15:00:00'),--Teclado
  (1, 3, 4, 'Disponible', '2023-10-10 15:00:00'),--Laptop

  --Contador1 - 4
  (1, 3, 29, 'Asignado', '2025-01-01 10:00:00'),--Monitor
  (1, 3, 30, 'Asignado', '2025-01-01 10:00:00'),--Mouse
  (1, 3, 31, 'Asignado', '2025-01-01 10:00:00'),--Teclado
  (1, 3, 32, 'Asignado', '2025-01-01 10:00:00');--Laptop
GO