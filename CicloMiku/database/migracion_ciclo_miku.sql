-- ==============================================================================
-- CICLOMIKU - MIGRACIÓN SEGURA Y REPETIBLE para la base `ciclo_miku` YA EXISTENTE
-- Compatible con MariaDB / MySQL de XAMPP. Ejecutar con phpMyAdmin > base ciclo_miku > Importar
-- (o pegando el contenido en la pestaña SQL).
--
-- QUÉ HACE (y qué NO):
--   * NO borra ni recrea ninguna tabla. NO borra datos (salvo filas DUPLICADAS de favoritos,
--     que son redundantes por definición, antes de crear el índice único).
--   * Crea solo las tablas que falten (CREATE TABLE IF NOT EXISTS). Esto resuelve el error
--     "#1146 - Tabla 'ciclo_miku.configuraciones' no existe".
--   * Agrega SOLO las columnas que falten, comprobando antes en information_schema.
--   * Agrega los índices únicos que impiden duplicados (favoritos, emails, etc.).
--   * Amplía los ENUM de estados solo si faltan valores y ninguna fila queda inválida.
--   * Reemplaza valores por defecto inventados de versiones anteriores (ej. la tarjeta
--     "Visa terminada en 4242", el mecánico y el código de seguimiento falsos).
--   * Carga/actualiza los 12 productos reales del sitio (sin pisar el stock existente).
--   * Es repetible: podés ejecutarlo varias veces sin efectos adversos.
-- ==============================================================================

USE `ciclo_miku`;
SET NAMES utf8mb4;

-- ------------------------------------------------------------------------------
-- 1. TABLAS FALTANTES (solo se crean si no existen)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `apellido` VARCHAR(100) NOT NULL DEFAULT '',
  `email` VARCHAR(150) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `telefono` VARCHAR(50) NOT NULL DEFAULT '',
  `dni` VARCHAR(30) NOT NULL DEFAULT '',
  `fecha_nacimiento` DATE NULL DEFAULT NULL,
  `direccion` VARCHAR(255) NOT NULL DEFAULT '',
  `ciudad` VARCHAR(100) NOT NULL DEFAULT '',
  `codigo_postal` VARCHAR(20) NOT NULL DEFAULT '',
  `instrucciones_entrega` VARCHAR(500) NOT NULL DEFAULT '',
  `bici_actual_modelo` VARCHAR(150) NOT NULL DEFAULT '',
  `rango_socio` VARCHAR(100) NULL DEFAULT NULL,
  `rol` ENUM('cliente','admin') NOT NULL DEFAULT 'cliente',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_usuarios_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `productos` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL,
  `descripcion` TEXT NULL,
  `categoria` ENUM('bicicleta','accesorio') NOT NULL DEFAULT 'accesorio',
  `subcategoria` VARCHAR(80) NOT NULL DEFAULT '',
  `marca` VARCHAR(50) NOT NULL DEFAULT '',
  `gama` ENUM('alta','media','baja') NOT NULL DEFAULT 'media',
  `precio` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `cuotas_texto` VARCHAR(120) NULL DEFAULT NULL,
  `stock` INT NOT NULL DEFAULT 0,
  `imagen` VARCHAR(500) NOT NULL DEFAULT '',
  `activo` TINYINT(1) NOT NULL DEFAULT 1,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_prod_cat_marca` (`categoria`,`marca`,`precio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `carrito` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NULL DEFAULT NULL,
  `session_id` VARCHAR(128) NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_carrito_usuario` (`usuario_id`),
  KEY `idx_carrito_session` (`session_id`),
  CONSTRAINT `fk_carrito_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `carrito_detalle` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `carrito_id` INT NOT NULL,
  `producto_id` INT NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 1,
  `color` VARCHAR(50) NULL DEFAULT '',
  `talle` VARCHAR(50) NULL DEFAULT '',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_item_carrito` (`carrito_id`,`producto_id`,`color`,`talle`),
  CONSTRAINT `fk_cd_carrito` FOREIGN KEY (`carrito_id`) REFERENCES `carrito` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cd_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `favoritos` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `producto_id` INT NOT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fav_usuario_prod` (`usuario_id`,`producto_id`),
  CONSTRAINT `fk_fav_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fav_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `pedidos` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `numero_pedido` VARCHAR(50) NOT NULL,
  `usuario_id` INT NOT NULL,
  `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `descuento` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `metodo_pago` VARCHAR(80) NULL DEFAULT NULL,
  `estado` ENUM('pendiente','confirmado','en_preparacion','enviado','entregado','cancelado') NOT NULL DEFAULT 'pendiente',
  `direccion_envio` VARCHAR(255) NULL DEFAULT NULL,
  `codigo_seguimiento` VARCHAR(100) NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pedido_numero` (`numero_pedido`),
  KEY `idx_pedido_usuario` (`usuario_id`),
  CONSTRAINT `fk_pedido_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `pedido_detalle` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `pedido_id` INT NOT NULL,
  `producto_id` INT NOT NULL,
  `nombre_producto` VARCHAR(150) NOT NULL DEFAULT '',
  `precio_unitario` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `cantidad` INT NOT NULL DEFAULT 1,
  `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_det_pedido` (`pedido_id`),
  CONSTRAINT `fk_det_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_det_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `turnos` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `codigo_turno` VARCHAR(50) NOT NULL,
  `usuario_id` INT NULL DEFAULT NULL,
  `servicio` VARCHAR(150) NOT NULL DEFAULT '',
  `marca_bici` VARCHAR(100) NOT NULL DEFAULT '',
  `modelo_bici` VARCHAR(100) NOT NULL DEFAULT '',
  `anio_bici` INT NULL DEFAULT NULL,
  `tipo_bici` VARCHAR(50) NULL DEFAULT NULL,
  `motivo` TEXT NULL,
  `foto_url` VARCHAR(255) NULL DEFAULT NULL,
  `fecha_turno` DATE NOT NULL,
  `horario_turno` VARCHAR(20) NOT NULL DEFAULT '',
  `nombre_cliente` VARCHAR(100) NOT NULL DEFAULT '',
  `telefono_cliente` VARCHAR(50) NOT NULL DEFAULT '',
  `email_cliente` VARCHAR(150) NOT NULL DEFAULT '',
  `presupuesto_base` DECIMAL(12,2) NULL DEFAULT NULL,
  `mecanico_asignado` VARCHAR(100) NULL DEFAULT NULL,
  `estado` ENUM('solicitado','confirmado','en_taller','completado','cancelado') NOT NULL DEFAULT 'solicitado',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_turno_codigo` (`codigo_turno`),
  KEY `idx_turno_fecha` (`fecha_turno`,`horario_turno`),
  KEY `idx_turno_usuario` (`usuario_id`),
  CONSTRAINT `fk_turno_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `notificaciones` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `tipo` VARCHAR(50) NOT NULL DEFAULT 'general',
  `icono` VARCHAR(20) NOT NULL DEFAULT '🔔',
  `titulo` VARCHAR(200) NOT NULL DEFAULT '',
  `mensaje` TEXT NULL,
  `leida` TINYINT(1) NOT NULL DEFAULT 0,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notif_usuario_leida` (`usuario_id`,`leida`),
  CONSTRAINT `fk_notif_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `configuraciones` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `notif_whatsapp_taller` TINYINT(1) NOT NULL DEFAULT 1,
  `notif_recordatorio_turno` TINYINT(1) NOT NULL DEFAULT 1,
  `notif_email_pedidos` TINYINT(1) NOT NULL DEFAULT 1,
  `notif_promos_club` TINYINT(1) NOT NULL DEFAULT 0,
  `tema_visual` VARCHAR(20) NOT NULL DEFAULT 'claro',
  `metodo_pago_defecto` VARCHAR(100) NOT NULL DEFAULT 'sin_definir',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_config_usuario` (`usuario_id`),
  CONSTRAINT `fk_config_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------------------------
-- 2. COLUMNAS FALTANTES (cada bloque agrega la columna solo si no existe)
-- ------------------------------------------------------------------------------
-- tabla usuarios
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `nombre` VARCHAR(100) NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'nombre');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `apellido` VARCHAR(100) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'apellido');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `email` VARCHAR(150) NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'email');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `password` VARCHAR(255) NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'password');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `telefono` VARCHAR(50) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'telefono');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `dni` VARCHAR(30) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'dni');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `fecha_nacimiento` DATE NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'fecha_nacimiento');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `direccion` VARCHAR(255) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'direccion');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `ciudad` VARCHAR(100) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'ciudad');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `codigo_postal` VARCHAR(20) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'codigo_postal');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `instrucciones_entrega` VARCHAR(500) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'instrucciones_entrega');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `bici_actual_modelo` VARCHAR(150) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'bici_actual_modelo');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `rango_socio` VARCHAR(100) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'rango_socio');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `rol` ENUM(''cliente'',''admin'') NOT NULL DEFAULT ''cliente''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'rol');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD COLUMN `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'actualizado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla productos
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `nombre` VARCHAR(150) NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'nombre');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `descripcion` TEXT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'descripcion');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `categoria` ENUM(''bicicleta'',''accesorio'') NOT NULL DEFAULT ''accesorio''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'categoria');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `subcategoria` VARCHAR(80) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'subcategoria');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `marca` VARCHAR(50) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'marca');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `gama` ENUM(''alta'',''media'',''baja'') NOT NULL DEFAULT ''media''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'gama');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `precio` DECIMAL(12,2) NOT NULL DEFAULT 0.00', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'precio');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `cuotas_texto` VARCHAR(120) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'cuotas_texto');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `stock` INT NOT NULL DEFAULT 0', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'stock');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `imagen` VARCHAR(500) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'imagen');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `activo` TINYINT(1) NOT NULL DEFAULT 1', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'activo');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `productos` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla carrito
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito` ADD COLUMN `usuario_id` INT NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito' AND COLUMN_NAME = 'usuario_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito` ADD COLUMN `session_id` VARCHAR(128) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito' AND COLUMN_NAME = 'session_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito` ADD COLUMN `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito' AND COLUMN_NAME = 'actualizado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla carrito_detalle
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD COLUMN `carrito_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND COLUMN_NAME = 'carrito_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD COLUMN `producto_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND COLUMN_NAME = 'producto_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD COLUMN `cantidad` INT NOT NULL DEFAULT 1', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND COLUMN_NAME = 'cantidad');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD COLUMN `color` VARCHAR(50) NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND COLUMN_NAME = 'color');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD COLUMN `talle` VARCHAR(50) NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND COLUMN_NAME = 'talle');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla favoritos
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `favoritos` ADD COLUMN `usuario_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favoritos' AND COLUMN_NAME = 'usuario_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `favoritos` ADD COLUMN `producto_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favoritos' AND COLUMN_NAME = 'producto_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `favoritos` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favoritos' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla pedidos
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `numero_pedido` VARCHAR(50) NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'numero_pedido');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `usuario_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'usuario_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'subtotal');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `descuento` DECIMAL(12,2) NOT NULL DEFAULT 0.00', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'descuento');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `total` DECIMAL(12,2) NOT NULL DEFAULT 0.00', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'total');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `metodo_pago` VARCHAR(80) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'metodo_pago');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `estado` ENUM(''pendiente'',''confirmado'',''en_preparacion'',''enviado'',''entregado'',''cancelado'') NOT NULL DEFAULT ''pendiente''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'estado');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `direccion_envio` VARCHAR(255) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'direccion_envio');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `codigo_seguimiento` VARCHAR(100) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'codigo_seguimiento');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla pedido_detalle
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedido_detalle` ADD COLUMN `pedido_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedido_detalle' AND COLUMN_NAME = 'pedido_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedido_detalle` ADD COLUMN `producto_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedido_detalle' AND COLUMN_NAME = 'producto_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedido_detalle` ADD COLUMN `nombre_producto` VARCHAR(150) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedido_detalle' AND COLUMN_NAME = 'nombre_producto');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedido_detalle` ADD COLUMN `precio_unitario` DECIMAL(12,2) NOT NULL DEFAULT 0.00', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedido_detalle' AND COLUMN_NAME = 'precio_unitario');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedido_detalle` ADD COLUMN `cantidad` INT NOT NULL DEFAULT 1', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedido_detalle' AND COLUMN_NAME = 'cantidad');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedido_detalle` ADD COLUMN `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedido_detalle' AND COLUMN_NAME = 'subtotal');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla turnos
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `codigo_turno` VARCHAR(50) NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'codigo_turno');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `usuario_id` INT NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'usuario_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `servicio` VARCHAR(150) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'servicio');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `marca_bici` VARCHAR(100) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'marca_bici');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `modelo_bici` VARCHAR(100) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'modelo_bici');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `anio_bici` INT NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'anio_bici');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `tipo_bici` VARCHAR(50) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'tipo_bici');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `motivo` TEXT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'motivo');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `foto_url` VARCHAR(255) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'foto_url');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `fecha_turno` DATE NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'fecha_turno');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `horario_turno` VARCHAR(20) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'horario_turno');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `nombre_cliente` VARCHAR(100) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'nombre_cliente');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `telefono_cliente` VARCHAR(50) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'telefono_cliente');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `email_cliente` VARCHAR(150) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'email_cliente');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `presupuesto_base` DECIMAL(12,2) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'presupuesto_base');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `mecanico_asignado` VARCHAR(100) NULL DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'mecanico_asignado');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `estado` ENUM(''solicitado'',''confirmado'',''en_taller'',''completado'',''cancelado'') NOT NULL DEFAULT ''solicitado''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'estado');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla notificaciones
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `usuario_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'usuario_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `tipo` VARCHAR(50) NOT NULL DEFAULT ''general''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'tipo');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `icono` VARCHAR(20) NOT NULL DEFAULT ''🔔''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'icono');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `titulo` VARCHAR(200) NOT NULL DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'titulo');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `mensaje` TEXT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'mensaje');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `leida` TINYINT(1) NOT NULL DEFAULT 0', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'leida');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `notificaciones` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notificaciones' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- tabla configuraciones
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `usuario_id` INT NOT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'usuario_id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `notif_whatsapp_taller` TINYINT(1) NOT NULL DEFAULT 1', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'notif_whatsapp_taller');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `notif_recordatorio_turno` TINYINT(1) NOT NULL DEFAULT 1', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'notif_recordatorio_turno');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `notif_email_pedidos` TINYINT(1) NOT NULL DEFAULT 1', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'notif_email_pedidos');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `notif_promos_club` TINYINT(1) NOT NULL DEFAULT 0', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'notif_promos_club');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `tema_visual` VARCHAR(20) NOT NULL DEFAULT ''claro''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'tema_visual');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `metodo_pago_defecto` VARCHAR(100) NOT NULL DEFAULT ''sin_definir''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'metodo_pago_defecto');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'creado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD COLUMN `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'actualizado_en');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- ------------------------------------------------------------------------------
-- 3. ÍNDICES ÚNICOS (evitan duplicados)
-- ------------------------------------------------------------------------------
-- Si favoritos tiene columna `id`, se eliminan SOLO filas repetidas (mismo usuario + producto), conservando la más antigua.
-- Si no la tiene (clave primaria compuesta), no puede haber duplicados y este paso no hace nada.
SET @cm = (SELECT IF(COUNT(*) = 1, 'DELETE f1 FROM `favoritos` f1 JOIN `favoritos` f2 ON f1.`usuario_id` = f2.`usuario_id` AND f1.`producto_id` = f2.`producto_id` AND f1.`id` > f2.`id`', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favoritos' AND COLUMN_NAME = 'id');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `usuarios` ADD UNIQUE INDEX `uq_usuarios_email` (`email`)', 'DO 0') FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND INDEX_NAME = 'uq_usuarios_email');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `favoritos` ADD UNIQUE INDEX `uq_fav_usuario_prod` (`usuario_id`,`producto_id`)', 'DO 0') FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favoritos' AND INDEX_NAME = 'uq_fav_usuario_prod');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `configuraciones` ADD UNIQUE INDEX `uq_config_usuario` (`usuario_id`)', 'DO 0') FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND INDEX_NAME = 'uq_config_usuario');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `pedidos` ADD UNIQUE INDEX `uq_pedido_numero` (`numero_pedido`)', 'DO 0') FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND INDEX_NAME = 'uq_pedido_numero');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `turnos` ADD UNIQUE INDEX `uq_turno_codigo` (`codigo_turno`)', 'DO 0') FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND INDEX_NAME = 'uq_turno_codigo');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `carrito_detalle` ADD UNIQUE INDEX `uq_item_carrito` (`carrito_id`,`producto_id`,`color`,`talle`)', 'DO 0') FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'carrito_detalle' AND INDEX_NAME = 'uq_item_carrito');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- ------------------------------------------------------------------------------
-- 4. ESTADOS (ENUM) que usa el código
-- ------------------------------------------------------------------------------
SET @cm = (SELECT IF(COUNT(*) = 1 AND (SELECT COUNT(*) FROM `pedidos` WHERE `estado` NOT IN ('pendiente','confirmado','en_preparacion','enviado','entregado','cancelado')) = 0, 'ALTER TABLE `pedidos` MODIFY COLUMN `estado` ENUM(''pendiente'',''confirmado'',''en_preparacion'',''enviado'',''entregado'',''cancelado'') NOT NULL DEFAULT ''pendiente''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'estado' AND DATA_TYPE = 'enum' AND (LOCATE('''pendiente''', COLUMN_TYPE) = 0 OR LOCATE('''confirmado''', COLUMN_TYPE) = 0 OR LOCATE('''en_preparacion''', COLUMN_TYPE) = 0 OR LOCATE('''enviado''', COLUMN_TYPE) = 0 OR LOCATE('''entregado''', COLUMN_TYPE) = 0 OR LOCATE('''cancelado''', COLUMN_TYPE) = 0));
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1 AND (SELECT COUNT(*) FROM `turnos` WHERE `estado` NOT IN ('solicitado','confirmado','en_taller','completado','cancelado')) = 0, 'ALTER TABLE `turnos` MODIFY COLUMN `estado` ENUM(''solicitado'',''confirmado'',''en_taller'',''completado'',''cancelado'') NOT NULL DEFAULT ''solicitado''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'estado' AND DATA_TYPE = 'enum' AND (LOCATE('''solicitado''', COLUMN_TYPE) = 0 OR LOCATE('''confirmado''', COLUMN_TYPE) = 0 OR LOCATE('''en_taller''', COLUMN_TYPE) = 0 OR LOCATE('''completado''', COLUMN_TYPE) = 0 OR LOCATE('''cancelado''', COLUMN_TYPE) = 0));
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1 AND (SELECT COUNT(*) FROM `productos` WHERE `categoria` NOT IN ('bicicleta','accesorio')) = 0, 'ALTER TABLE `productos` MODIFY COLUMN `categoria` ENUM(''bicicleta'',''accesorio'') NOT NULL DEFAULT ''accesorio''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'categoria' AND DATA_TYPE = 'enum' AND (LOCATE('''bicicleta''', COLUMN_TYPE) = 0 OR LOCATE('''accesorio''', COLUMN_TYPE) = 0));
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1 AND (SELECT COUNT(*) FROM `productos` WHERE `gama` NOT IN ('alta','media','baja')) = 0, 'ALTER TABLE `productos` MODIFY COLUMN `gama` ENUM(''alta'',''media'',''baja'') NOT NULL DEFAULT ''media''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'productos' AND COLUMN_NAME = 'gama' AND DATA_TYPE = 'enum' AND (LOCATE('''alta''', COLUMN_TYPE) = 0 OR LOCATE('''media''', COLUMN_TYPE) = 0 OR LOCATE('''baja''', COLUMN_TYPE) = 0));
PREPARE cm_st FROM @cm;
EXECUTE cm_st;

-- ------------------------------------------------------------------------------
-- 5. VALORES POR DEFECTO INVENTADOS DE VERSIONES ANTERIORES
-- ------------------------------------------------------------------------------
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `usuarios` ALTER COLUMN `bici_actual_modelo` SET DEFAULT ''''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'bici_actual_modelo' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = 'Specialized Demo 7 - Rodado 27.5');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `usuarios` ALTER COLUMN `rango_socio` SET DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'rango_socio' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = '⭐ Socio CicloClub Oro (1.450 puntos acumulados)' AND IS_NULLABLE = 'YES');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `pedidos` ALTER COLUMN `codigo_seguimiento` SET DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'codigo_seguimiento' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = 'ANDREANI-EXP-7749' AND IS_NULLABLE = 'YES');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `pedidos` ALTER COLUMN `metodo_pago` SET DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'metodo_pago' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = 'Tarjeta Crédito en cuotas' AND IS_NULLABLE = 'YES');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `turnos` ALTER COLUMN `mecanico_asignado` SET DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'mecanico_asignado' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = 'Martín Gómez (Jefe de Taller CicloMiku)' AND IS_NULLABLE = 'YES');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `turnos` ALTER COLUMN `presupuesto_base` SET DEFAULT NULL', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'turnos' AND COLUMN_NAME = 'presupuesto_base' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = '20000.00' AND IS_NULLABLE = 'YES');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
SET @cm = (SELECT IF(COUNT(*) = 1, 'ALTER TABLE `configuraciones` ALTER COLUMN `metodo_pago_defecto` SET DEFAULT ''sin_definir''', 'DO 0') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'configuraciones' AND COLUMN_NAME = 'metodo_pago_defecto' AND TRIM(BOTH '''' FROM COLUMN_DEFAULT) = 'Visa Crédito terminada en •••• 4242');
PREPARE cm_st FROM @cm;
EXECUTE cm_st;
-- Si alguna fila ya guardó el método de pago falso, se deja como "sin definir"
UPDATE `configuraciones` SET `metodo_pago_defecto` = 'sin_definir'
 WHERE `metodo_pago_defecto` LIKE 'Visa Cr%4242%' OR `metodo_pago_defecto` = '' OR `metodo_pago_defecto` IS NULL;

-- Cada usuario existente debe tener su fila de preferencias
INSERT IGNORE INTO `configuraciones` (`usuario_id`) SELECT `id` FROM `usuarios`;

-- ------------------------------------------------------------------------------
-- PRODUCTOS: los 12 que aparecen hoy en index.html (ids 1-6, bicicletas) y
-- accesoriomikus.html (ids 7-12, accesorios). Nombre, descripción, marca, precio, cuotas e
-- imagen están copiados tal cual de las tarjetas HTML. El id coincide con data-producto-id.
-- ATENCIÓN: las páginas NO indican stock. Se carga un stock inicial de 10 unidades por
-- producto como VALOR PROVISORIO: ajustalo a tu stock real en phpMyAdmin (tabla productos).
-- ------------------------------------------------------------------------------
INSERT INTO `productos` (`id`,`nombre`,`descripcion`,`categoria`,`subcategoria`,`marca`,`gama`,`precio`,`cuotas_texto`,`stock`,`imagen`,`activo`) VALUES
(1, 'Specialized Demo 7', 'Cuadro reforzado de aluminio, suspensión Fox 180mm y frenos hidráulicos de 4 pistones.', 'bicicleta', 'MTB / Descenso', 'Specialized', 'alta', 450000.00, '12 cuotas fijas de $37.500', 10, 'https://assets.specialized.com/i/specialized/5719?$scom-pdp-product-image-xl$&fmt=webp', 1),
(2, 'Giant Talon 1 29er', 'Rodado 29, transmisión Shimano Deore 1x10 y horquilla con bloqueo hidráulico.', 'bicicleta', 'Mountain Bike', 'Giant', 'media', 315000.00, '6 cuotas sin interés de $52.500', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQR-5w0M_8YYLQM3LWM8Lv_PP__TH6e2U1iiqrWT2UnzQ&s=10', 1),
(3, 'Specialized Allez Sprint', 'Bicicleta de ruta aerodinámica, grupo Shimano 105 2x11 y horquilla de carbono.', 'bicicleta', 'Ruta / Carrera', 'Specialized', 'alta', 490000.00, '12 cuotas fijas de $40.833', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxAWO8qBMbtB16eGTt7z0RXuIhhrfMB3xhCKvkqu-IZQ&s=10', 1),
(4, 'Trek Marlin 7 Gen 3', 'Geometría moderna, frenos a disco hidráulicos Tektro y cubiertas Bontrager.', 'bicicleta', 'MTB / Trail', 'Trek', 'media', 280000.00, '12 cuotas fijas de $23.333', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ16NyCSLKyWKzg27YN0Y8yfJ8xo66hy4GUYklaumhMk3l9SO69SUQHan8&s=10', 1),
(5, 'Scott Aspect 940', 'Cuadro de aleación liviana, componentes Syncros y 18 velocidades Shimano.', 'bicicleta', 'Mountain Bike', 'Scott', 'media', 385000.00, '6 cuotas sin interés de $64.166', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ-IiFtxgRpViO2nmq2AhnIFrHRIfo7FfYHVeCqL0rmijS6NSztOrhHEkk&s=10', 1),
(6, 'Cannondale Quick 4 Urban', 'Bicicleta urbana ágil y ligera con sensor de rueda integrado para conectividad.', 'bicicleta', 'Urbana / Paseo', 'Cannondale', 'media', 320000.00, '6 cuotas sin interés de $53.333', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWKaiT3S3bqYqyCz5eQx2JTsoCBXbSQG28TIgQ42rKTQ&s', 1),
(7, 'Casco Bell 4Forty MIPS', 'Tecnología de protección contra impactos rotacionales MIPS, ventilación Sweat Guide.', 'accesorio', 'Seguridad', 'Bell', 'alta', 78000.00, '3 cuotas sin interés de $26.000', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQfWw5r40XNNS3xnzC94kJ7d-G9c9o5gix_4gSf0jYRcQ&s=10', 1),
(8, 'Set Luces LED Recargables USB', 'Luz delantera de 800 lúmenes y trasera de alta visibilidad, resistentes al agua IPX6.', 'accesorio', 'Iluminación', 'CicloMiku Pro', 'media', 24500.00, '3 cuotas de $8.166', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSU1UlO6_X81B6t4Hxj6een3AYOM7_D92tnYAclQNjTC_DjBQXho8x1to6D&s=10', 1),
(9, 'Guantes de Ciclismo Giro Gel', 'Acolchado con gel antideslizante, tela transpirable y refuerzo en palma para mayor agarre.', 'accesorio', 'Indumentaria', 'Giro', 'media', 18900.00, '3 cuotas sin interés de $6.300', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQsq_UQxmKmQ5jPb4FNkEVwWD4QL8AwmfNtLKq6WLZzWtax3PG_fgYWGgE&s=10', 1),
(10, 'Inflador Portátil con Manómetro', 'Compatible con válvulas Presta y Schrader (auto), presión máxima de 120 PSI.', 'accesorio', 'Herramientas', 'Beto', 'media', 15200.00, 'Efectivo 10% de descuento', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeYu7rnstXqO_GTcFsV8P8ME_eBO_CReXAypGEhFWFNw&s', 1),
(11, 'Candado U-Lock Antirrobo Acero', 'Grillete de acero endurecido de 14mm con cable de acero flexible de 1.2m incluido.', 'accesorio', 'Seguridad', 'OnGuard', 'alta', 42000.00, '6 cuotas fijas de $7.000', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS_FFx-L0xsRI4ivSTyVh86yHlaVph-6Zf8EC15jDnJXKJRu54qERPA3oU&s=10', 1),
(12, 'Cadena Shimano Deore 11V HG-X', 'Cadena original de 116 eslabones con Quick-Link para transmisiones de 11 velocidades.', 'accesorio', 'Repuestos', 'Shimano', 'media', 32500.00, '3 cuotas sin interés de $10.833', 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_SET1Eq6_cT5TC1vH2vBMmknwKpmyR6AKIqM_p_cGB7CgT9lLL0-W6rQ&s=10', 1)
ON DUPLICATE KEY UPDATE `nombre`=VALUES(`nombre`), `descripcion`=VALUES(`descripcion`), `categoria`=VALUES(`categoria`),
  `subcategoria`=VALUES(`subcategoria`), `marca`=VALUES(`marca`), `gama`=VALUES(`gama`), `precio`=VALUES(`precio`),
  `cuotas_texto`=VALUES(`cuotas_texto`), `imagen`=VALUES(`imagen`), `activo`=1;
-- (el STOCK no se pisa si el producto ya existía: lo administrás vos desde phpMyAdmin)

-- FIN. Para verificar el resultado ejecutá database/diagnostico.sql
