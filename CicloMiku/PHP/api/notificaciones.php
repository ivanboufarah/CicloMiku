<?php
/**
 * CICLOMIKU - API de notificaciones del usuario autenticado
 *   GET  -> lista (solo las guardadas en la base de datos para ese usuario)
 *   POST -> accion: marcar_leida {id} | marcar_todas | eliminar {id}
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';
require_once __DIR__ . '/../includes/preferencias.php';

$pdo       = obtenerConexion();
$usuarioId = requerirAutenticacion();
$metodo    = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'GET') {
    try {
        $s = $pdo->prepare('SELECT id, tipo, icono, titulo, mensaje, leida, creado_en FROM notificaciones WHERE usuario_id = :uid ORDER BY creado_en DESC, id DESC');
        $s->execute([':uid' => $usuarioId]);
        $lista = $s->fetchAll();

        $sinLeer = 0;
        foreach ($lista as &$n) {
            $n['leida'] = (bool)$n['leida'];
            if (!$n['leida']) $sinLeer++;
            $n['fecha_formateada'] = fechaEspanol($n['creado_en'], true);
        }
        unset($n);

        responderJSON(['success' => true, 'total' => count($lista), 'sin_leer' => $sinLeer, 'notificaciones' => $lista]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'notificaciones GET', 'No se pudieron obtener las notificaciones.');
    }

} elseif ($metodo === 'POST') {
    validarTokenCSRF();

    $datos  = obtenerEntrada();
    $accion = limpiarTexto($datos['accion'] ?? '', 30);
    $id     = (int)($datos['id'] ?? 0);

    try {
        if ($accion === 'marcar_leida') {
            if ($id <= 0) responderJSON(['success' => false, 'error' => 'Notificación no válida.'], 400);
            $s = $pdo->prepare('UPDATE notificaciones SET leida = 1 WHERE id = :id AND usuario_id = :uid');
            $s->execute([':id' => $id, ':uid' => $usuarioId]);
            responderJSON(['success' => true, 'mensaje' => 'Notificación marcada como leída.']);

        } elseif ($accion === 'marcar_todas' || $accion === 'marcar_todas_leidas') {
            $s = $pdo->prepare('UPDATE notificaciones SET leida = 1 WHERE usuario_id = :uid AND leida = 0');
            $s->execute([':uid' => $usuarioId]);
            responderJSON(['success' => true, 'mensaje' => 'Todas las notificaciones fueron marcadas como leídas.', 'actualizadas' => $s->rowCount()]);

        } elseif ($accion === 'eliminar') {
            if ($id <= 0) responderJSON(['success' => false, 'error' => 'Notificación no válida.'], 400);
            $s = $pdo->prepare('DELETE FROM notificaciones WHERE id = :id AND usuario_id = :uid');
            $s->execute([':id' => $id, ':uid' => $usuarioId]);
            responderJSON(['success' => true, 'mensaje' => 'Notificación eliminada.']);

        } else {
            responderJSON(['success' => false, 'error' => 'Acción no válida.'], 400);
        }
    } catch (PDOException $e) {
        responderErrorSQL($e, 'notificaciones POST', 'No se pudo actualizar la notificación.');
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
