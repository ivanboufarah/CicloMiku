<?php
/**
 * CICLOMIKU - Estado de la sesión, contadores y token CSRF (lo consulta api.js en cada página)
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

$usuarioId = obtenerUsuarioId();

$respuesta = [
    'success'                       => true,
    'autenticado'                   => false,
    'usuario'                       => null,
    'csrf_token'                    => obtenerTokenCSRF(),
    'total_notificaciones_sin_leer' => 0,
    'total_items_carrito'           => 0,
    'total_favoritos'               => 0
];

$pdo = obtenerConexion();

try {
    $usuario = null;
    if ($usuarioId) {
        $stmt = $pdo->prepare('SELECT id, nombre, apellido, email, telefono, rol FROM usuarios WHERE id = :id LIMIT 1');
        $stmt->execute([':id' => $usuarioId]);
        $usuario = $stmt->fetch();
        if (!$usuario) {
            // La cuenta ya no existe: se limpia la sesión
            unset($_SESSION['usuario_id'], $_SESSION['usuario_nombre'], $_SESSION['usuario_email'], $_SESSION['usuario_rol']);
        }
    }

    if ($usuario) {
        $respuesta['autenticado'] = true;
        $respuesta['usuario']     = $usuario;

        $q = $pdo->prepare('SELECT COUNT(*) FROM notificaciones WHERE usuario_id = :uid AND leida = 0');
        $q->execute([':uid' => $usuarioId]);
        $respuesta['total_notificaciones_sin_leer'] = (int)$q->fetchColumn();

        $q = $pdo->prepare('SELECT COUNT(*) FROM favoritos WHERE usuario_id = :uid');
        $q->execute([':uid' => $usuarioId]);
        $respuesta['total_favoritos'] = (int)$q->fetchColumn();

        $q = $pdo->prepare('SELECT COALESCE(SUM(cd.cantidad), 0) FROM carrito c JOIN carrito_detalle cd ON c.id = cd.carrito_id WHERE c.usuario_id = :uid');
        $q->execute([':uid' => $usuarioId]);
        $respuesta['total_items_carrito'] = (int)$q->fetchColumn();
    } else {
        $q = $pdo->prepare('SELECT COALESCE(SUM(cd.cantidad), 0) FROM carrito c JOIN carrito_detalle cd ON c.id = cd.carrito_id WHERE c.session_id = :sid AND c.usuario_id IS NULL');
        $q->execute([':sid' => obtenerSessionCartId()]);
        $respuesta['total_items_carrito'] = (int)$q->fetchColumn();
    }
} catch (PDOException $e) {
    // No se corta la página por un contador: se informa el error para depurar
    error_log('CicloMiku - estado.php: ' . $e->getMessage());
    $respuesta['aviso_bd'] = CM_DEBUG ? $e->getMessage() : 'Hay un problema con la base de datos. Ejecutá database/migracion_ciclo_miku.sql.';
}

responderJSON($respuesta);
