from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import connection
import json

class propuesta(APIView):    
    def get(self, request):
        Id_Solicitud = request.query_params.get('Id_Solicitud')
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Propuesta_De_Seleccion @Id_Solicitud=%s", [Id_Solicitud])
            #rows = cursor.fetchall()
            
        #data = [{'Responsable_TI': row[0], 'Asignado_A_Empleado': row[1], 'Tipo_Equipo': row[2], 'FechaRegistro': row[3]} for row in rows]
        #return Response(data)
        return Response({"mensaje": "Propuesta"})