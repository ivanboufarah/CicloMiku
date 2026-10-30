<?php
/**
 * CICLOMIKU - Cierre de sesión (POST + token CSRF)
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responderJSON(['success' => false, 'error' => 'Método no permitido. Utilizá POST.'], 405);
}
validarTokenCSRF();

$_SESSION = [];

if (ini_get('session.use_cookies')) {
    $p = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
}
session_destroy();

responderJSON(['success' => true, 'mensaje' => 'Sesión cerrada correctamente.']);
