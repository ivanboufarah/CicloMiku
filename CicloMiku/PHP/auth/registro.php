<?php
/**
 * CICLOMIKU - Registro de usuarios (password_hash) con transacción
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responderJSON(['success' => false, 'error' => 'Método no permitido. Utilizá POST.'], 405);
}
validarTokenCSRF();

$datos    = obtenerEntrada();
$nombre   = limpiarTexto($datos['nombre'] ?? '', 100);
$apellido = limpiarTexto($datos['apellido'] ?? '', 100);
$email    = filter_var(limpiarTexto($datos['correo'] ?? $datos['email'] ?? '', 150), FILTER_VALIDATE_EMAIL);
$telefono = limpiarTexto($datos['telefono'] ?? '', 50);
$password = (string)($datos['contrasena'] ?? $datos['password'] ?? '');
$aceptaWhatsapp = !empty($datos['acepta_whatsapp']) && filter_var($datos['acepta_whatsapp'], FILTER_VALIDATE_BOOLEAN) ? 1 : 0;

// Compatibilidad: si llega todo en "nombre" ("Juan Pérez") se separa
if ($apellido === '' && strpos($nombre, ' ') !== false) {
    [$nombre, $apellido] = explode(' ', $nombre, 2);
    $apellido = trim($apellido);
}

if ($nombre === '' || $apellido === '') {
    responderJSON(['success' => false, 'error' => 'Ingresá tu nombre y tu apellido.'], 400);
}
if (!$email) {
    responderJSON(['success' => false, 'error' => 'Ingresá un correo electrónico válido.'], 400);
}
if ($telefono !== '' && !preg_match('/^[0-9 +().-]{6,25}$/', $telefono)) {
    responderJSON(['success' => false, 'error' => 'El teléfono solo puede contener números, espacios y los símbolos + ( ) - .'], 400);
}
if (strlen($password) < 8 || strlen($password) > 72) {
    responderJSON(['success' => false, 'error' => 'La contraseña debe tener entre 8 y 72 caracteres.'], 400);
}

$pdo = obtenerConexion();

try {
    $stmt = $pdo->prepare('SELECT id FROM usuarios WHERE email = :email LIMIT 1');
    $stmt->execute([':email' => $email]);
    if ($stmt->fetch()) {
        responderJSON(['success' => false, 'error' => 'Ese correo ya está registrado. Probá iniciar sesión.'], 409);
    }

    $hash = password_hash($password, PASSWORD_DEFAULT);

    $pdo->beginTransaction();

    $pdo->prepare("INSERT INTO usuarios (nombre, apellido, email, password, telefono, rol) VALUES (:nombre, :apellido, :email, :password, :telefono, 'cliente')")
        ->execute([':nombre' => $nombre, ':apellido' => $apellido, ':email' => $email, ':password' => $hash, ':telefono' => $telefono]);
    $nuevoId = (int)$pdo->lastInsertId();

    // Preferencias iniciales (solo avisos del taller/pedidos activados; promociones desactivadas hasta que el usuario las acepte)
    $pdo->prepare('INSERT INTO configuraciones (usuario_id, notif_whatsapp_taller, notif_recordatorio_turno, notif_email_pedidos, notif_promos_club, tema_visual)
                   VALUES (:uid, :wa, 1, 1, 0, \'claro\')')
        ->execute([':uid' => $nuevoId, ':wa' => $aceptaWhatsapp]);

    $pdo->prepare("INSERT INTO notificaciones (usuario_id, tipo, icono, titulo, mensaje, leida) VALUES (:uid, 'cuenta', '🎉', '¡Bienvenido a CicloMiku!', 'Tu cuenta fue creada. Ya podés guardar favoritos, comprar y solicitar turnos de taller.', 0)")
        ->execute([':uid' => $nuevoId]);

    $pdo->commit();

    session_regenerate_id(true);
    $_SESSION['usuario_id']     = $nuevoId;
    $_SESSION['usuario_nombre'] = $nombre . ' ' . $apellido;
    $_SESSION['usuario_email']  = $email;
    $_SESSION['usuario_rol']    = 'cliente';

    responderJSON([
        'success'    => true,
        'mensaje'    => '¡Cuenta creada! Bienvenido a CicloMiku, ' . $nombre . '.',
        'usuario'    => ['id' => $nuevoId, 'nombre' => $nombre, 'apellido' => $apellido, 'email' => $email, 'telefono' => $telefono],
        'csrf_token' => obtenerTokenCSRF()
    ], 201);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    if ($e->getCode() === '23000') {
        responderJSON(['success' => false, 'error' => 'Ese correo ya está registrado. Probá iniciar sesión.'], 409);
    }
    responderErrorSQL($e, 'registro.php', 'No se pudo crear la cuenta por un error de base de datos.');
}
