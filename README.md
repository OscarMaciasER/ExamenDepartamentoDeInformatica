# ExamenDepartamentoDeInformatica

Instalacion de la Base de Datos en SQL Server 16
1.- Abre "SQL Server Management Studio (SSMS)"
1.- Haz clic en "Archivo > Abrir > Archivo"
1.- Selecciona el archivo `ExamenDepartamentoDeInformatica.sql` (viene en la carpeta "Base de Datos en SQL Server 16")
1.- Presiona el botón "Ejecutar" (o la tecla `F5`)
1.- Espera a que aparezca el mensaje de ejecución correcta

¡Listo! Ya tienes la base de datos creada y configurada con todo lo necesario.



Instalacion Django con Django Rest Framework
1.-Crea el entorno viertual
    python -m venv venv

2.- Activalo 
    venv\Scripts\activate  # Windows

2.-Instala las dependencias (con el entorno activado)
    pip install -r requirements.txt

4.-Configura la base de datos de acuerdo a tu login  "Backend/Backend/settings.py"

    DATABASES = {
        'default': {
            'ENGINE': 'mssql',
            'NAME': 'Nombre de la Base de Datos',
            'HOST': 'TU host de Base de datos',
            'OPTIONS': {
                'driver': 'ODBC Driver 17 for SQL Server',
            },
        },
    }

5.-Corre el proyecto
    python manage.py runserver

6.-Ruta para el navegador    
    http://127.0.0.1:8000/


Instalacion de VUE.JS
1.-Nos situamos dentro del proyecto de VUE.JS
    cd ../frontend

2.-Instalamos las dependencias
    npm install
    npm run dev

3.-Corremos el proyecto
    npm run serve

4.-Ruta para el navegador
    http://localhost:8080/

Nota: Recuenta el frontend ocupa su propia consola de comando al igual que el backend