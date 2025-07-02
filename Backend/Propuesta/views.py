from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import connection
import json

class propuesta(APIView):    
    def get(self, request):
        Id_Solicitud = request.query_params.get('Id_Solicitud')
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Propuesta_De_Seleccion @Id_Solicitud=%s", [Id_Solicitud])
            rows = cursor.fetchall()
            con_Equipo = [{'Id_Con_Equipo': row[0], 'Rol': row[1], 'Persona': row[2], 'Id_Equipo': row[3], 'Tipo_Equipo': row[4], 'Modelo': row[5], 'Numero_Serie': row[6], 'Costo': row[7], 'Especificaciones': row[8]} for row in rows]
            
            cursor.nextset()
            rows = cursor.fetchall()
            sin_equipo = [{'Id_Sin_Equipo': row[0], 'Rol': row[1], 'Tipo_Equipo': row[2], 'Persona': row[3]} for row in rows]

        return Response({
            "con_equipo": con_Equipo,
            "sin_equipo": sin_equipo
        })