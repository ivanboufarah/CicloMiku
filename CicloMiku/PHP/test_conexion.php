<?php
/**
 * ==============================================================================
 * CICLOMIKU - DIAGNÓSTICO DE LA CONEXIÓN Y DE LA BASE DE DATOS (solo lectura)
 * Abrir en el navegador:  http://localhost/CicloMiku/PHP/test_conexion.php
 * Solo funciona desde tu propia PC (localhost). No modifica nada.
 * ==============================================================================
 */
require_once __DIR__ . '/config/conexion.php';

$ip = $_SERVER['REMOTE_ADDR'] ?? '';
if (!in_array($ip, ['127.0.0.1', '::1'], true)) {
    http_response_code(403);
    exit('Esta página de diagnóstico solo está disponible desde localhost.');
}
header('Content-Type: text/html; charset=utf-8');

$esperado = [
    'usuarios' => ['id', 'nombre', 'apellido', 'email', 'password', 'telefono', 'dni', 'fecha_nacimiento', 'direccion', 'ciudad', 'codigo_postal', 'instrucciones_entrega', 'bici_actual_modelo', 'rango_socio', 'rol', 'creado_en', 'actualizado_en'],
    'productos' => ['id', 'nombre', 'descripcion', 'categoria', 'subcategoria', 'marca', 'gama', 'precio', 'cuotas_texto', 'stock', 'imagen', 'activo', 'creado_en'],
    'carrito' => ['id', 'usuario_id', 'session_id', 'creado_en', 'actualizado_en'],
    'carrito_detalle' => ['id', 'carrito_id', 'producto_id', 'cantidad', 'color', 'talle', 'creado_en'],
    'favoritos' => ['id', 'usuario_id', 'producto_id', 'creado_en'],
    'pedidos' => ['id', 'numero_pedido', 'usuario_id', 'subtotal', 'descuento', 'total', 'metodo_pago', 'estado', 'direccion_envio', 'codigo_seguimiento', 'creado_en'],
    'pedido_detalle' => ['id', 'pedido_id', 'producto_id', 'nombre_producto', 'precio_unitario', 'cantidad', 'subtotal'],
    'turnos' => ['id', 'codigo_turno', 'usuario_id', 'servicio', 'marca_bici', 'modelo_bici', 'anio_bici', 'tipo_bici', 'motivo', 'foto_url', 'fecha_turno', 'horario_turno', 'nombre_cliente', 'telefono_cliente', 'email_cliente', 'presupuesto_base', 'mecanico_asignado', 'estado', 'creado_en'],
    'notificaciones' => ['id', 'usuario_id', 'tipo', 'icono', 'titulo', 'mensaje', 'leida', 'creado_en'],
    'configuraciones' => ['id', 'usuario_id', 'notif_whatsapp_taller', 'notif_recordatorio_turno', 'notif_email_pedidos', 'notif_promos_club', 'tema_visual', 'metodo_pago_defecto', 'creado_en', 'actualizado_en'],
];

$conexionOk = false; $errorConexion = ''; $infoServidor = '';
$resultado = []; $conteos = [];

try {
    $pdo = new PDO('mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=utf8mb4', DB_USER, DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    $conexionOk = true;
    $infoServidor = $pdo->query('SELECT VERSION()')->fetchColumn();

    foreach ($esperado as $tabla => $columnas) {
        $q = $pdo->prepare('SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t');
        $q->execute([':t' => $tabla]);
        $existentes = $q->fetchAll(PDO::FETCH_COLUMN);
        $resultado[$tabla] = ['existe' => count($existentes) > 0, 'faltan' => array_values(array_diff($columnas, $existentes))];
        if ($resultado[$tabla]['existe']) {
            $conteos[$tabla] = (int)$pdo->query("SELECT COUNT(*) FROM `$tabla`")->fetchColumn();
        }
    }
} catch (PDOException $e) {
    $errorConexion = $e->getMessage();
}

$todoOk = $conexionOk;
foreach ($resultado as $r) { if (!$r['existe'] || $r['faltan']) $todoOk = false; }
if ($conexionOk && empty($conteos['productos'])) $todoOk = false;
?>
<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><title>Diagnóstico CicloMiku</title>
<style>body{font-family:system-ui,sans-serif;max-width:900px;margin:30px auto;padding:0 15px;color:#142E54}
.ok{color:#2f855a;font-weight:bold}.mal{color:#c53030;font-weight:bold}table{border-collapse:collapse;width:100%}
td,th{border:1px solid #cbd5e0;padding:6px 10px;text-align:left}th{background:#eaf2fd}code{background:#eef;padding:1px 5px}</style></head><body>
<h1>🔧 Diagnóstico de CicloMiku</h1>
<p>Versión de PHP: <b><?= htmlspecialchars(PHP_VERSION) ?></b> · extensión pdo_mysql: <?= extension_loaded('pdo_mysql') ? '<span class="ok">sí</span>' : '<span class="mal">NO (activala en php.ini)</span>' ?></p>
<?php if (!$conexionOk): ?>
  <p class="mal">❌ No se pudo conectar a la base «<?= htmlspecialchars(DB_NAME) ?>».</p>
  <p>Detalle: <code><?= htmlspecialchars($errorConexion) ?></code></p>
  <ul><li>¿MySQL está en verde (Start) en el panel de XAMPP?</li><li>¿Existe la base <b><?= htmlspecialchars(DB_NAME) ?></b> en phpMyAdmin?</li>
  <li>¿Cambiaste la contraseña de root? Creá <code>PHP/config/local.php</code> con <code>&lt;?php define('DB_PASS','tu_clave');</code></li></ul>
<?php else: ?>
  <p class="ok">✅ Conexión correcta con «<?= htmlspecialchars(DB_NAME) ?>» (servidor <?= htmlspecialchars($infoServidor) ?>).</p>
  <table><tr><th>Tabla</th><th>Estado</th><th>Filas</th><th>Columnas que faltan</th></tr>
  <?php foreach ($resultado as $t => $r): ?>
    <tr><td><?= $t ?></td>
    <td><?= !$r['existe'] ? '<span class="mal">no existe</span>' : ($r['faltan'] ? '<span class="mal">incompleta</span>' : '<span class="ok">OK</span>') ?></td>
    <td><?= $conteos[$t] ?? '-' ?></td><td><?= $r['faltan'] ? htmlspecialchars(implode(', ', $r['faltan'])) : '' ?></td></tr>
  <?php endforeach; ?></table>
  <?php if (empty($conteos['productos'])): ?><p class="mal">⚠️ La tabla «productos» está vacía: favoritos y carrito no pueden funcionar. Ejecutá <code>database/migracion_ciclo_miku.sql</code>.</p><?php endif; ?>
  <p><?= $todoOk ? '<span class="ok">✅ Todo listo: la estructura coincide con lo que usa el código PHP.</span>' : '<span class="mal">❌ Falta estructura o datos: ejecutá database/migracion_ciclo_miku.sql desde phpMyAdmin (Importar) y recargá esta página.</span>' ?></p>
<?php endif; ?>
</body></html>
