<?php
/**
 * ==============================================================================
 * CICLOMIKU - CONEXIÓN A MARIADB/MYSQL MEDIANTE PDO (compatible con XAMPP)
 * ==============================================================================
 * Valores por defecto de XAMPP: host 127.0.0.1, usuario root, sin contraseña.
 * Si cambiaste la contraseña de root, creá el archivo PHP/config/local.php con:
 *     <?php define('DB_PASS', 'tu_clave');
 * (ese archivo, si existe, se carga primero y no se pisa).
 */

if (is_file(__DIR__ . '/local.php')) {
    require_once __DIR__ . '/local.php';
}

if (!defined('DB_HOST'))    define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
if (!defined('DB_NAME'))    define('DB_NAME', getenv('DB_NAME') ?: 'ciclo_miku');
if (!defined('DB_USER'))    define('DB_USER', getenv('DB_USER') ?: 'root');
if (!defined('DB_PASS'))    define('DB_PASS', getenv('DB_PASS') !== false ? getenv('DB_PASS') : '');
if (!defined('DB_PORT'))    define('DB_PORT', getenv('DB_PORT') ?: '3306');
if (!defined('DB_CHARSET')) define('DB_CHARSET', 'utf8mb4');

// Mostrar el detalle técnico del error de MySQL en la respuesta JSON (solo para depurar en tu PC).
if (!defined('CM_DEBUG')) define('CM_DEBUG', false);

// Zona horaria del negocio (fechas de turnos y pedidos)
date_default_timezone_set('America/Argentina/Buenos_Aires');

// Nunca imprimir warnings/notices de PHP dentro del JSON (romperían la respuesta)
ini_set('display_errors', '0');
error_reporting(E_ALL);

/**
 * Devuelve la conexión PDO única.
 * @return PDO
 */
function obtenerConexion() {
    static $pdo = null;

    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=' . DB_CHARSET;
        $opciones = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            // Se dejan las consultas preparadas NATIVAS (más seguras). Por eso, en este proyecto,
            // un mismo marcador con nombre NO puede repetirse dentro de una misma consulta.
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];

        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $opciones);
            $pdo->exec("SET time_zone = '-03:00'");
        } catch (PDOException $e) {
            error_log('CicloMiku - error de conexión PDO: ' . $e->getMessage());
            if (!headers_sent()) {
                http_response_code(500);
                header('Content-Type: application/json; charset=utf-8');
            }
            $respuesta = [
                'success' => false,
                'error'   => 'No se pudo conectar a la base de datos "' . DB_NAME . '". Verificá que MySQL esté iniciado en XAMPP y que la base exista.'
            ];
            if (CM_DEBUG) $respuesta['detalle'] = $e->getMessage();
            echo json_encode($respuesta, JSON_UNESCAPED_UNICODE);
            exit;
        }
    }

    return $pdo;
}
