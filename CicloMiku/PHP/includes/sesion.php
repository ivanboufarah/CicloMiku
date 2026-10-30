<?php
/**
 * ==============================================================================
 * CICLOMIKU - SESIONES, CSRF Y RESPUESTAS JSON
 * ==============================================================================
 * El usuario autenticado SIEMPRE se obtiene de $_SESSION (nunca de lo que envía JavaScript).
 */

if (session_status() === PHP_SESSION_NONE) {
    $esHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
    session_name('CICLOMIKU_SID');
    session_set_cookie_params([
        'lifetime' => 86400 * 7,
        'path'     => '/',
        'domain'   => '',
        'secure'   => $esHttps,
        'httponly' => true,
        'samesite' => 'Lax'
    ]);
    session_start();
}

// Si algo falla de forma inesperada, responder JSON (y no una página en blanco)
set_exception_handler(function ($e) {
    error_log('CicloMiku - excepción no controlada: ' . $e->getMessage() . ' en ' . $e->getFile() . ':' . $e->getLine());
    $r = ['success' => false, 'error' => 'Error interno del servidor.'];
    if (defined('CM_DEBUG') && CM_DEBUG) $r['detalle'] = $e->getMessage();
    responderJSON($r, 500);
});

/** Token CSRF de la sesión actual (se crea si no existe). */
function obtenerTokenCSRF() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/** Valida el token CSRF (cabecera X-CSRF-Token, campo POST o campo JSON csrf_token). */
function validarTokenCSRF() {
    $token = null;
    if (!empty($_SERVER['HTTP_X_CSRF_TOKEN'])) {
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'];
    } elseif (!empty($_POST['csrf_token'])) {
        $token = $_POST['csrf_token'];
    } else {
        $entrada = obtenerDatosJSON();
        if (!empty($entrada['csrf_token'])) $token = $entrada['csrf_token'];
    }

    if (!is_string($token) || empty($_SESSION['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $token)) {
        responderJSON([
            'success'    => false,
            'error'      => 'Token de seguridad inválido o sesión expirada. Recargá la página e intentá de nuevo.',
            'csrf_token' => obtenerTokenCSRF()
        ], 403);
    }
}

/** ID del usuario autenticado, o null si es visitante. */
function obtenerUsuarioId() {
    return isset($_SESSION['usuario_id']) ? (int)$_SESSION['usuario_id'] : null;
}

/** Identificador estable para el carrito de un visitante (se conserva al iniciar sesión). */
function obtenerSessionCartId() {
    if (empty($_SESSION['cart_session_id'])) {
        $_SESSION['cart_session_id'] = bin2hex(random_bytes(16));
    }
    return $_SESSION['cart_session_id'];
}

/** Exige sesión iniciada; si no, responde 401. */
function requerirAutenticacion() {
    $id = obtenerUsuarioId();
    if (!$id) {
        responderJSON([
            'success'        => false,
            'requiere_login' => true,
            'error'          => 'Debés iniciar sesión para realizar esta operación.'
        ], 401);
    }
    return $id;
}

/** Cuerpo JSON de la petición (fetch) como array. */
function obtenerDatosJSON() {
    static $datos = null;
    if ($datos === null) {
        $contenido = file_get_contents('php://input');
        $decodificado = json_decode($contenido, true);
        $datos = is_array($decodificado) ? $decodificado : [];
    }
    return $datos;
}

/** Datos de entrada: JSON si lo hay; si no, $_POST. */
function obtenerEntrada() {
    $datos = obtenerDatosJSON();
    return !empty($datos) ? $datos : $_POST;
}

/** Texto limpio con longitud máxima (multibyte). */
function limpiarTexto($valor, $maximo = 255) {
    if (!is_scalar($valor)) return '';
    $valor = trim((string)$valor);
    $valor = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/u', '', $valor);
    return mb_substr($valor, 0, $maximo, 'UTF-8');
}

/** Respuesta JSON estándar y fin del script. */
function responderJSON($data, $codigo = 200) {
    if (!headers_sent()) {
        http_response_code($codigo);
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-cache, no-store, must-revalidate');
        header('X-Content-Type-Options: nosniff');
    }
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

/** Registra un error SQL en el log de PHP y responde 500 sin exponer detalles (salvo CM_DEBUG). */
function responderErrorSQL(PDOException $e, $contexto, $mensaje) {
    error_log('CicloMiku - ' . $contexto . ': ' . $e->getMessage());
    $r = ['success' => false, 'error' => $mensaje];
    if (defined('CM_DEBUG') && CM_DEBUG) $r['detalle'] = $e->getMessage();
    responderJSON($r, 500);
}
