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


BEGIN
EXEC SP_Tipo_Equipos;
END


BEGIN
EXEC SP_Estados;
END