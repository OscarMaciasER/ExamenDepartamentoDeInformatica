from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import connection
import json

class solicitudes(APIView):
    def post(self, request):
        Nombre = request.data.get('Nombre')
        ID_Solicitante = request.data.get('ID_Solicitante')
        DetalleSolicitudes = json.dumps(request.data.get('DetalleSolicitudes'))
  
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Solicitud_Equipo @Nombre=%s,@ID_Solicitante=%s,@DetalleSolicitudes=%s", [Nombre,ID_Solicitante,DetalleSolicitudes])
            
        return Response({"mensaje": "La solicitud se inserto exitosamente"})
        
    def get(self, request):
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Todas_Solicitudes")
            rows = cursor.fetchall()
            
        data = [{'Nombre': row[0], 'Solicitante': row[1], 'Estatus': row[2]} for row in rows]
        return Response(data)
    
class detalle(APIView):
    def get(self, request):
        Id_Solicitud = request.query_params.get('Id_Solicitud')
        with connection.cursor() as cursor:
            cursor.execute("EXEC SP_Detalle_Solicitud @Id_Solicitud=%s",[Id_Solicitud])
            rows = cursor.fetchall()
            
        data = [{'Rol': row[0], 'Cantidad': row[1]} for row in rows]
        return Response(data)    