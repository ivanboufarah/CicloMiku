-- ==============================================================================
-- CICLOMIKU - DIAGNÓSTICO (solo lectura, no modifica nada)
-- Ejecutalo en phpMyAdmin > ciclo_miku > SQL, ANTES y DESPUÉS de la migración.
-- ==============================================================================
USE `ciclo_miku`;

-- 1) Columnas que el código PHP necesita y NO existen (si no devuelve filas, está todo bien)
SELECT e.tabla, e.columna AS columna_faltante
FROM (
SELECT 'usuarios' AS tabla, 'id' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'nombre' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'apellido' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'email' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'password' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'telefono' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'dni' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'fecha_nacimiento' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'direccion' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'ciudad' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'codigo_postal' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'instrucciones_entrega' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'bici_actual_modelo' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'rango_socio' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'rol' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'usuarios' AS tabla, 'actualizado_en' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'id' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'nombre' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'descripcion' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'categoria' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'subcategoria' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'marca' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'gama' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'precio' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'cuotas_texto' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'stock' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'imagen' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'activo' AS columna
UNION ALL
SELECT 'productos' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'carrito' AS tabla, 'id' AS columna
UNION ALL
SELECT 'carrito' AS tabla, 'usuario_id' AS columna
UNION ALL
SELECT 'carrito' AS tabla, 'session_id' AS columna
UNION ALL
SELECT 'carrito' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'carrito' AS tabla, 'actualizado_en' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'id' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'carrito_id' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'producto_id' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'cantidad' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'color' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'talle' AS columna
UNION ALL
SELECT 'carrito_detalle' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'favoritos' AS tabla, 'id' AS columna
UNION ALL
SELECT 'favoritos' AS tabla, 'usuario_id' AS columna
UNION ALL
SELECT 'favoritos' AS tabla, 'producto_id' AS columna
UNION ALL
SELECT 'favoritos' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'id' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'numero_pedido' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'usuario_id' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'subtotal' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'descuento' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'total' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'metodo_pago' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'estado' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'direccion_envio' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'codigo_seguimiento' AS columna
UNION ALL
SELECT 'pedidos' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'id' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'pedido_id' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'producto_id' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'nombre_producto' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'precio_unitario' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'cantidad' AS columna
UNION ALL
SELECT 'pedido_detalle' AS tabla, 'subtotal' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'id' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'codigo_turno' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'usuario_id' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'servicio' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'marca_bici' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'modelo_bici' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'anio_bici' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'tipo_bici' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'motivo' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'foto_url' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'fecha_turno' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'horario_turno' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'nombre_cliente' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'telefono_cliente' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'email_cliente' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'presupuesto_base' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'mecanico_asignado' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'estado' AS columna
UNION ALL
SELECT 'turnos' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'id' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'usuario_id' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'tipo' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'icono' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'titulo' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'mensaje' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'leida' AS columna
UNION ALL
SELECT 'notificaciones' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'id' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'usuario_id' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'notif_whatsapp_taller' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'notif_recordatorio_turno' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'notif_email_pedidos' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'notif_promos_club' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'tema_visual' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'metodo_pago_defecto' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'creado_en' AS columna
UNION ALL
SELECT 'configuraciones' AS tabla, 'actualizado_en' AS columna
) e
LEFT JOIN information_schema.COLUMNS c
  ON c.TABLE_SCHEMA = DATABASE() AND c.TABLE_NAME = e.tabla AND c.COLUMN_NAME = e.columna
WHERE c.COLUMN_NAME IS NULL
ORDER BY e.tabla, e.columna;

-- 2) Tablas existentes, motor, cotejamiento y cantidad aproximada de filas
SELECT TABLE_NAME AS tabla, ENGINE AS motor, TABLE_COLLATION AS cotejamiento, TABLE_ROWS AS filas_aprox
FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME;

-- 3) Conteo exacto de datos importantes
SELECT (SELECT COUNT(*) FROM productos)       AS productos,
       (SELECT COUNT(*) FROM usuarios)        AS usuarios,
       (SELECT COUNT(*) FROM favoritos)       AS favoritos,
       (SELECT COUNT(*) FROM carrito_detalle) AS items_en_carritos,
       (SELECT COUNT(*) FROM pedidos)         AS pedidos,
       (SELECT COUNT(*) FROM turnos)          AS turnos,
       (SELECT COUNT(*) FROM notificaciones)  AS notificaciones,
       (SELECT COUNT(*) FROM configuraciones) AS configuraciones;

-- 4) Estructura completa (si algo falla, copiá y pegá el resultado de estas líneas)
SHOW CREATE TABLE usuarios;
SHOW CREATE TABLE productos;
SHOW CREATE TABLE favoritos;
SHOW CREATE TABLE configuraciones;
