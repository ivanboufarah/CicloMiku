# CicloMiku

Tienda online de bicicletas y accesorios con taller de mantenimiento y solicitud de turnos.
Proyecto de la materia **Construcción de Software – Taller G605**. Autor: **Ivan Boufarah**.

El sitio guarda y recupera todo en una base de datos MySQL/MariaDB: usuarios, favoritos, carrito, pedidos, historial, perfil, configuración, notificaciones y turnos.

## Contenido de la entrega

| Elemento | Ubicación |
|---|---|
| Proyecto completo | esta carpeta (`index.html`, `menu_usuario/`, `CSS/`, `js/`, `PHP/`, `imagenes/`) |
| Base de datos (.sql) | `database/ciclo_miku.sql` (estructura completa + los 12 productos) |
| Documentación del proyecto (PDF) | `Documentacion_CicloMiku.pdf` |
| Manual de usuario (PDF) | `Manual_de_Usuario_CicloMiku.pdf` |
| README | este archivo |

Otros archivos de `database/`: `migracion_ciclo_miku.sql` (actualiza una base ya existente sin borrar datos) y `diagnostico.sql` (consultas de solo lectura para verificar la estructura).

## Tecnologías utilizadas

- **Front-end:** HTML5, CSS3, Bootstrap 5 (cargado por CDN) y JavaScript (ES6).
- **Comunicación AJAX:** `fetch()` con respuestas JSON.
- **Back-end:** PHP (7.3 o superior; XAMPP actual incluye PHP 8.x) con **PDO** y consultas preparadas.
- **Base de datos:** MySQL / MariaDB (motor InnoDB, codificación utf8mb4).
- **Seguridad:** `password_hash` / `password_verify`, token CSRF, sesiones PHP (cookie HttpOnly + SameSite), validaciones en cliente y servidor.

## Herramientas necesarias para ejecutarlo en un entorno local

1. **XAMPP** (Apache + MariaDB/MySQL + PHP + phpMyAdmin) para Windows: https://www.apachefriends.org
2. Un navegador actualizado (Chrome, Edge o Firefox).
3. **Conexión a Internet** durante la prueba: Bootstrap se carga desde un CDN y las imágenes de los productos son enlaces externos.

No requiere Node.js, Composer ni ninguna instalación adicional.

## Instalación y ejecución paso a paso

### 1. Copiar el proyecto
Descomprimí el ZIP y copiá la carpeta **`CicloMiku`** completa dentro de `C:\xampp\htdocs\`, de modo que quede `C:\xampp\htdocs\CicloMiku\index.html`.

### 2. Iniciar los servicios
Abrí el *Panel de control de XAMPP* y presioná **Start** en **Apache** y en **MySQL** (ambos deben quedar en verde).

### 3. Crear la base de datos
1. Entrá a **http://localhost/phpmyadmin**.
2. Pestaña **Importar** → *Elegir archivo* → seleccioná `C:\xampp\htdocs\CicloMiku\database\ciclo_miku.sql` → **Importar**.
   - El archivo crea la base `ciclo_miku`, sus 10 tablas y carga los 12 productos. No hace falta crearla antes.
3. Verificá que a la izquierda aparezca `ciclo_miku` con 10 tablas y que `productos` tenga 12 filas.

> **Si ya tenías una base `ciclo_miku` con datos**, no uses el archivo anterior: importá en su lugar `database/migracion_ciclo_miku.sql`, que agrega solo lo que falta y conserva lo existente.

### 4. Verificar la conexión
Abrí **http://localhost/CicloMiku/PHP/test_conexion.php**. Debe mostrar la conexión correcta y todas las tablas en **OK**.
Si tu MySQL tiene contraseña para `root`, creá el archivo `PHP/config/local.php` con:
```php
<?php define('DB_PASS', 'tu_clave');
```
(los valores por defecto de XAMPP son: host `127.0.0.1`, usuario `root`, sin contraseña, base `ciclo_miku`).

### 5. Abrir el sitio
Entrá a **http://localhost/CicloMiku/** (siempre por `localhost`; no abras los `.html` con doble clic, porque las funciones de PHP y base de datos no funcionarían).

## Cómo probarlo (usuario de prueba)
La base **no incluye usuarios de ejemplo**. Para probar:
1. Menú de usuario (icono arriba a la derecha) → **Iniciar sesión** → pestaña **Crear cuenta** y registrá una cuenta.
2. Tocá corazones en **Bicicletas** y **Accesorios**; agregá productos al carrito; en **Carrito** presioná *Registrar pedido*; revisá **Historial**, **Perfil**, **Configuración** y **Notificaciones**; pedí un turno en **Sacar Turno**.

La lista completa de pruebas está en la sección 6.2 de `Documentacion_CicloMiku.pdf`, y el uso de cada pantalla en `Manual_de_Usuario_CicloMiku.pdf`.

## Estructura del proyecto
```
CicloMiku/
├── index.html · accesoriomikus.html · turnosmiku.html
├── menu_usuario/   registro, perfil, favoritos, carrito, historial, notificaciones, configuracion
├── CSS/            hojas de estilo (corazones.css: estilo único de los favoritos)
├── js/             api.js (cliente fetch + CSRF) y un script por funcionalidad
├── PHP/
│   ├── config/conexion.php        conexión PDO
│   ├── includes/                  sesión/CSRF, valores permitidos, validaciones
│   ├── auth/                      registro, login, logout, estado de sesión
│   ├── api/                       productos, favoritos, carrito, pedidos, perfil,
│   │                              configuracion, notificaciones, turnos
│   └── test_conexion.php          diagnóstico de la instalación
├── database/       ciclo_miku.sql · migracion_ciclo_miku.sql · diagnostico.sql
└── imagenes/
```

## Notas importantes
- **No hay pasarela de pago.** «Registrar pedido» guarda el pedido como *pendiente*; no se cobra ni se simula un pago. No se guardan datos de tarjetas.
- **Stock inicial provisorio:** las páginas no indicaban existencias, por lo que cada producto se carga con 10 unidades; se ajusta en phpMyAdmin (tabla `productos`, columna `stock`).
- El **administrador** gestiona stock, pedidos y turnos desde phpMyAdmin (ver el capítulo 12 del manual de usuario).
- La carga de fotos en el formulario de turnos y el tema oscuro no están implementados (ver «Limitaciones» en la documentación).
- Si querés entregar tu propia copia de la base con tus datos de prueba, exportala desde phpMyAdmin: base `ciclo_miku` → **Exportar** → método *Rápido* → formato *SQL* → guardá el archivo en `database/`. (Contiene los hash de contraseñas de los usuarios que hayas creado.)

## Solución de problemas
| Síntoma | Qué hacer |
|---|---|
| phpMyAdmin dice «No se puede establecer una conexión» | MySQL está apagado: iniciarlo en el panel de XAMPP (revisar que el puerto 3306 no esté ocupado). |
| El sitio muestra «No se pudo conectar con el servidor» | Verificar que Apache esté iniciado y abrir el sitio desde `http://localhost/CicloMiku/`. |
| `test_conexion.php` marca tablas o columnas faltantes | Importar `database/migracion_ciclo_miku.sql`. |
| Favoritos o carrito dicen que el producto no existe | La tabla `productos` está vacía: importar `ciclo_miku.sql` o la migración. |
| Errores de PHP | Revisar `C:\xampp\apache\logs\error.log`. Para ver el detalle SQL en las respuestas, agregar `define('CM_DEBUG', true);` en `PHP/config/local.php`. |
