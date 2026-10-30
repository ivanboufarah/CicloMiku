<?php
/**
 * CICLOMIKU - API de configuración (datos de la cuenta, preferencias y contraseña)
 * Pertenece SIEMPRE al usuario de la sesión. No guarda datos de tarjetas.
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';
require_once __DIR__ . '/../includes/preferencias.php';
require_once __DIR__ . '/../includes/usuarios_util.php';

$pdo       = obtenerConexion();
$usuarioId = requerirAutenticacion();
$metodo    = $_SERVER['REQUEST_METHOD'];

function cargarConfiguracion(PDO $pdo, $usuarioId) {
    // Si el usuario todavía no tiene fila de preferencias se crea con valores por defecto
    $pdo->prepare('INSERT IGNORE INTO configuraciones (usuario_id) VALUES (:uid)')->execute([':uid' => $usuarioId]);

    $s = $pdo->prepare('
        SELECT u.nombre, u.apellido, u.email, u.telefono, u.dni, u.direccion, u.ciudad, u.codigo_postal, u.instrucciones_entrega,
               c.notif_whatsapp_taller, c.notif_recordatorio_turno, c.notif_email_pedidos, c.notif_promos_club,
               c.tema_visual, c.metodo_pago_defecto
        FROM usuarios u
        LEFT JOIN configuraciones c ON c.usuario_id = u.id
        WHERE u.id = :uid LIMIT 1
    ');
    $s->execute([':uid' => $usuarioId]);
    $c = $s->fetch();
    if (!$c) return null;

    foreach (['notif_whatsapp_taller','notif_recordatorio_turno','notif_email_pedidos','notif_promos_club'] as $k) {
        $c[$k] = (int)$c[$k];
    }
    if (!in_array($c['tema_visual'], CM_TEMAS, true)) $c['tema_visual'] = 'claro';
    if (!isset(CM_METODOS_PAGO[$c['metodo_pago_defecto']])) $c['metodo_pago_defecto'] = 'sin_definir';
    return $c;
}

if ($metodo === 'GET') {
    try {
        $c = cargarConfiguracion($pdo, $usuarioId);
        if (!$c) responderJSON(['success' => false, 'error' => 'Usuario no encontrado.'], 404);
        responderJSON(['success' => true, 'configuracion' => $c, 'metodos_pago' => CM_METODOS_PAGO, 'temas' => CM_TEMAS]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'configuracion GET', 'No se pudo obtener la configuración.');
    }

} elseif ($metodo === 'POST') {
    validarTokenCSRF();
    $datos = obtenerEntrada();

    // 1) Validar todo ANTES de tocar la base de datos
    [$campos, $error] = validarDatosPersonales($datos);
    if ($error) responderJSON(['success' => false, 'error' => $error], 400);

    $tema = limpiarTexto($datos['tema_visual'] ?? 'claro', 10);
    if (!in_array($tema, CM_TEMAS, true)) responderJSON(['success' => false, 'error' => 'Tema visual no válido.'], 400);

    $metodoPago = limpiarTexto($datos['metodo_pago_defecto'] ?? 'sin_definir', 30);
    if (!isset(CM_METODOS_PAGO[$metodoPago])) responderJSON(['success' => false, 'error' => 'Método de pago no válido.'], 400);

    $flags = [];
    foreach (['notif_whatsapp_taller','notif_recordatorio_turno','notif_email_pedidos','notif_promos_club'] as $k) {
        $flags[$k] = !empty($datos[$k]) && filter_var($datos[$k], FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    }

    $passActual = (string)($datos['pass_actual'] ?? $datos['password_actual'] ?? '');
    $passNueva  = (string)($datos['pass_nueva']  ?? $datos['password_nueva']  ?? '');
    $cambiaPass = ($passNueva !== '');
    if ($cambiaPass) {
        if ($passActual === '')                          responderJSON(['success' => false, 'error' => 'Ingresá tu contraseña actual para poder cambiarla.'], 400);
        if (strlen($passNueva) < 8 || strlen($passNueva) > 72) responderJSON(['success' => false, 'error' => 'La nueva contraseña debe tener entre 8 y 72 caracteres.'], 400);
        if ($passNueva === $passActual)                  responderJSON(['success' => false, 'error' => 'La nueva contraseña debe ser distinta de la actual.'], 400);
    }

    try {
        if ($cambiaPass) {
            $s = $pdo->prepare('SELECT password FROM usuarios WHERE id = :uid');
            $s->execute([':uid' => $usuarioId]);
            if (!password_verify($passActual, (string)$s->fetchColumn())) {
                responderJSON(['success' => false, 'error' => 'La contraseña actual es incorrecta.'], 400);
            }
        }

        $pdo->beginTransaction();

        if ($campos) actualizarUsuario($pdo, $usuarioId, $campos);

        if ($cambiaPass) {
            $pdo->prepare('UPDATE usuarios SET password = :h WHERE id = :uid')
                ->execute([':h' => password_hash($passNueva, PASSWORD_DEFAULT), ':uid' => $usuarioId]);
        }

        $pdo->prepare('
            INSERT INTO configuraciones (usuario_id, notif_whatsapp_taller, notif_recordatorio_turno, notif_email_pedidos, notif_promos_club, tema_visual, metodo_pago_defecto)
            VALUES (:uid, :w, :t, :e, :p, :tema, :mp)
            ON DUPLICATE KEY UPDATE
                notif_whatsapp_taller    = VALUES(notif_whatsapp_taller),
                notif_recordatorio_turno = VALUES(notif_recordatorio_turno),
                notif_email_pedidos      = VALUES(notif_email_pedidos),
                notif_promos_club        = VALUES(notif_promos_club),
                tema_visual              = VALUES(tema_visual),
                metodo_pago_defecto      = VALUES(metodo_pago_defecto)
        ')->execute([
            ':uid' => $usuarioId, ':w' => $flags['notif_whatsapp_taller'], ':t' => $flags['notif_recordatorio_turno'],
            ':e' => $flags['notif_email_pedidos'], ':p' => $flags['notif_promos_club'], ':tema' => $tema, ':mp' => $metodoPago
        ]);

        $pdo->commit();

        if ($cambiaPass) session_regenerate_id(true);   // la sesión sigue activa, con un ID nuevo

        $c = cargarConfiguracion($pdo, $usuarioId);
        if (isset($campos['nombre'])) $_SESSION['usuario_nombre'] = trim($c['nombre'] . ' ' . $c['apellido']);

        responderJSON([
            'success'       => true,
            'mensaje'       => $cambiaPass ? '¡Configuración guardada y contraseña actualizada!' : '¡Configuración guardada!',
            'configuracion' => $c,
            'csrf_token'    => obtenerTokenCSRF()
        ]);
    } catch (PDOException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        responderErrorSQL($e, 'configuracion POST', 'No se pudo guardar la configuración. Verificá que la tabla "configuraciones" tenga todas las columnas (database/migracion_ciclo_miku.sql).');
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
