"""
URL configuration for Backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from Propuesta import views
from Gestion_Inventario import views as inventario_views
from Gestion_Solicitudes import views as solicitudes_views
from Propuesta import views as propuesta_views

urlpatterns = [
    #path("admin/", admin.site.urls),
    
    #Gestios_Inventario
    path('api/equipos/', inventario_views.equipos.as_view()),
    path('api/tipoEquipos/', inventario_views.tipoEquipos.as_view()),
    path('api/estados/', inventario_views.estados.as_view()),
    
    #Gestion_Solicitudes
    path('api/solicitudes/', solicitudes_views.solicitudes.as_view()),
    path('api/solicitudes/detalle/', solicitudes_views.detalle.as_view()),
    
    #Propuesta
    path('api/propuesta/', propuesta_views.propuesta.as_view()),
]
