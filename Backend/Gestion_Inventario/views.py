from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import connection
import json

class equipos(APIView):    
    def get(self, request):
        Tipo_Equipo = request.query_params.get('Tipo_Equipo')
        Estatus = request.query_params.get('Estatus')
        
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Historial_Inventario @Tipo_Equipo=%s,@Estatus=%s", [Tipo_Equipo,Estatus])
            rows = cursor.fetchall()
            
        data = [{'Responsable_TI': row[0], 'Asignado_A_Empleado': row[1], 'Tipo_Equipo': row[2], 'FechaRegistro': row[3]} for row in rows]
        return Response(data)
    
    def post(self, request):
        Tipo_Equipo = request.data.get('Tipo_Equipo')
        Modelo = request.data.get('Modelo')
        Numero_Serie = request.data.get('Numero_Serie')
        Costo = request.data.get('Costo')
        especificaciones = json.dumps(request.data.get('Especificaciones'))
  
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Crear_Equipo @Tipo_Equipo=%s,@Modelo=%s,@Numero_Serie=%s,@Costo=%s,@Especificaciones=%s", [Tipo_Equipo,Modelo,Numero_Serie,Costo,especificaciones])
            
        return Response({"mensaje": "Equipo insertado exitosamente"})