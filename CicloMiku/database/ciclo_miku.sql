-- ==============================================================================
-- CICLOMIKU - INSTALACIÓN LIMPIA de la base de datos `ciclo_miku`
-- Compatible con MariaDB / MySQL de XAMPP (phpMyAdmin > Importar).
--
-- Usalo SOLO si la base está vacía o si querés empezar de cero. Si ya tenés tablas con
-- datos, usá en su lugar  database/migracion_ciclo_miku.sql  (conserva todo).
-- No contiene usuarios, pedidos, notificaciones ni carritos de ejemplo: solo la estructura
-- y los productos reales del sitio.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS `ciclo_miku` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `ciclo_miku`;
SET NAMES utf8mb4;

-- 1. usuarios
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

-- 2. productos
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

-- 3. carrito
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

-- 4. carrito_detalle
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

-- 5. favoritos
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

-- 6. pedidos
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

-- 7. pedido_detalle
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

-- 8. turnos
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

-- 9. notificaciones
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

-- 10. configuraciones
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
