<?php
/**
 * CICLOMIKU - Inicio de sesión (password_verify) + unión del carrito de visitante
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responderJSON(['success' => false, 'error' => 'Método no permitido. Utilizá POST.'], 405);
}
validarTokenCSRF();

// Freno básico contra fuerza bruta (por sesión): 5 fallos => 60 segundos de espera
if (!empty($_SESSION['login_bloqueo_hasta']) && time() < $_SESSION['login_bloqueo_hasta']) {
    $faltan = $_SESSION['login_bloqueo_hasta'] - time();
    responderJSON(['success' => false, 'error' => "Demasiados intentos fallidos. Esperá {$faltan} segundos e intentá de nuevo."], 429);
}

$datos    = obtenerEntrada();
$email    = filter_var(limpiarTexto($datos['correo'] ?? $datos['email'] ?? '', 150), FILTER_VALIDATE_EMAIL);
$password = (string)($datos['contrasena'] ?? $datos['password'] ?? '');

if (!$email || $password === '') {
    responderJSON(['success' => false, 'error' => 'Ingresá un correo electrónico válido y tu contraseña.'], 400);
}

$pdo = obtenerConexion();

try {
    $stmt = $pdo->prepare('SELECT id, nombre, apellido, email, password, telefono, rol FROM usuarios WHERE email = :email LIMIT 1');
    $stmt->execute([':email' => $email]);
    $usuario = $stmt->fetch();

    if (!$usuario || !password_verify($password, $usuario['password'])) {
        $_SESSION['login_fallos'] = ($_SESSION['login_fallos'] ?? 0) + 1;
        if ($_SESSION['login_fallos'] >= 5) {
            $_SESSION['login_bloqueo_hasta'] = time() + 60;
            $_SESSION['login_fallos'] = 0;
        }
        responderJSON(['success' => false, 'error' => 'El correo o la contraseña son incorrectos.'], 401);
    }

    unset($_SESSION['login_fallos'], $_SESSION['login_bloqueo_hasta']);

    // Actualiza el hash si el algoritmo por defecto de PHP mejoró
    if (password_needs_rehash($usuario['password'], PASSWORD_DEFAULT)) {
        $pdo->prepare('UPDATE usuarios SET password = :h WHERE id = :id')
            ->execute([':h' => password_hash($password, PASSWORD_DEFAULT), ':id' => $usuario['id']]);
    }

    $cartSessionId = obtenerSessionCartId();   // se lee antes de regenerar el ID de sesión
    session_regenerate_id(true);

    $_SESSION['usuario_id']     = (int)$usuario['id'];
    $_SESSION['usuario_nombre'] = trim($usuario['nombre'] . ' ' . $usuario['apellido']);
    $_SESSION['usuario_email']  = $usuario['email'];
    $_SESSION['usuario_rol']    = $usuario['rol'];

    // Unir el carrito que tenía como visitante con el de su cuenta
    $stmtG = $pdo->prepare('SELECT id FROM carrito WHERE session_id = :sid AND usuario_id IS NULL LIMIT 1');
    $stmtG->execute([':sid' => $cartSessionId]);
    $carritoVisitante = $stmtG->fetchColumn();

    if ($carritoVisitante) {
        $pdo->beginTransaction();
        $stmtU = $pdo->prepare('SELECT id FROM carrito WHERE usuario_id = :uid LIMIT 1');
        $stmtU->execute([':uid' => $usuario['id']]);
        $carritoUsuario = $stmtU->fetchColumn();

        if (!$carritoUsuario) {
            $pdo->prepare('UPDATE carrito SET usuario_id = :uid, session_id = NULL WHERE id = :cid')
                ->execute([':uid' => $usuario['id'], ':cid' => $carritoVisitante]);
        } else {
            $items = $pdo->prepare('SELECT cd.producto_id, cd.cantidad, COALESCE(cd.color, \'\') AS color, COALESCE(cd.talle, \'\') AS talle, p.stock
                                    FROM carrito_detalle cd JOIN productos p ON p.id = cd.producto_id
                                    WHERE cd.carrito_id = :cid');
            $items->execute([':cid' => $carritoVisitante]);

            $buscar = $pdo->prepare('SELECT id, cantidad FROM carrito_detalle WHERE carrito_id = :cid AND producto_id = :pid AND COALESCE(color, \'\') = :color AND COALESCE(talle, \'\') = :talle LIMIT 1');
            $sumar  = $pdo->prepare('UPDATE carrito_detalle SET cantidad = :cant WHERE id = :id');
            $nuevo  = $pdo->prepare('INSERT INTO carrito_detalle (carrito_id, producto_id, cantidad, color, talle) VALUES (:cid, :pid, :cant, :color, :talle)');

            foreach ($items->fetchAll() as $it) {
                $buscar->execute([':cid' => $carritoUsuario, ':pid' => $it['producto_id'], ':color' => $it['color'], ':talle' => $it['talle']]);
                $ex = $buscar->fetch();
                $cant = min((int)$it['stock'], (int)$it['cantidad'] + ($ex ? (int)$ex['cantidad'] : 0));
                if ($cant < 1) continue;
                if ($ex) {
                    $sumar->execute([':cant' => $cant, ':id' => $ex['id']]);
                } else {
                    $nuevo->execute([':cid' => $carritoUsuario, ':pid' => $it['producto_id'], ':cant' => $cant, ':color' => $it['color'], ':talle' => $it['talle']]);
                }
            }
            $pdo->prepare('DELETE FROM carrito WHERE id = :cid')->execute([':cid' => $carritoVisitante]);
        }
        $pdo->commit();
    }

    unset($usuario['password']);

    responderJSON([
        'success'    => true,
        'mensaje'    => '¡Bienvenido de nuevo, ' . $usuario['nombre'] . '!',
        'usuario'    => $usuario,
        'csrf_token' => obtenerTokenCSRF()
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    responderErrorSQL($e, 'login.php', 'No se pudo iniciar sesión por un error de base de datos.');
}
