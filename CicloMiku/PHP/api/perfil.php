<?php
/**
 * CICLOMIKU - API de perfil (ver y editar los datos del usuario autenticado)
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';
require_once __DIR__ . '/../includes/preferencias.php';
require_once __DIR__ . '/../includes/usuarios_util.php';

$pdo       = obtenerConexion();
$usuarioId = requerirAutenticacion();
$metodo    = $_SERVER['REQUEST_METHOD'];

function cargarPerfil(PDO $pdo, $usuarioId) {
    $s = $pdo->prepare('SELECT id, nombre, apellido, email, telefono, dni, fecha_nacimiento, direccion, ciudad, codigo_postal,
                               instrucciones_entrega, bici_actual_modelo, rango_socio, rol, creado_en
                        FROM usuarios WHERE id = :uid LIMIT 1');
    $s->execute([':uid' => $usuarioId]);
    $p = $s->fetch();
    if (!$p) return null;

    $p['miembro_desde'] = fechaEspanol($p['creado_en']);

    // Último service REAL: último turno completado en el taller
    $s = $pdo->prepare("SELECT fecha_turno, servicio FROM turnos WHERE usuario_id = :uid AND estado = 'completado' ORDER BY fecha_turno DESC LIMIT 1");
    $s->execute([':uid' => $usuarioId]);
    $t = $s->fetch();
    $p['ultimo_service'] = $t ? fechaEspanol($t['fecha_turno']) . ' (' . $t['servicio'] . ')' : null;

    return $p;
}

if ($metodo === 'GET') {
    try {
        $perfil = cargarPerfil($pdo, $usuarioId);
        if (!$perfil) responderJSON(['success' => false, 'error' => 'Usuario no encontrado.'], 404);
        responderJSON(['success' => true, 'perfil' => $perfil]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'perfil GET', 'No se pudieron cargar los datos del perfil.');
    }

} elseif ($metodo === 'POST') {
    validarTokenCSRF();

    [$campos, $error] = validarDatosPersonales(obtenerEntrada());
    if ($error) responderJSON(['success' => false, 'error' => $error], 400);
    if (!$campos) responderJSON(['success' => false, 'error' => 'No se enviaron datos para guardar.'], 400);

    try {
        actualizarUsuario($pdo, $usuarioId, $campos);
        $perfil = cargarPerfil($pdo, $usuarioId);
        $_SESSION['usuario_nombre'] = trim($perfil['nombre'] . ' ' . $perfil['apellido']);
        responderJSON(['success' => true, 'mensaje' => '¡Datos actualizados correctamente!', 'perfil' => $perfil]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'perfil POST', 'No se pudieron guardar los cambios del perfil.');
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
