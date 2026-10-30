<?php
/**
 * CICLOMIKU - API de favoritos
 *   GET  -> lista de favoritos del usuario autenticado
 *   POST -> {producto_id}                 alterna (agrega/quita)
 *           {producto_id, activo: true}   deja el producto como favorito (idempotente)
 *           {producto_id, activo: false}  lo quita (idempotente)
 * El usuario sale SIEMPRE de la sesión.
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

$pdo    = obtenerConexion();
$metodo = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'GET') {
    $usuarioId = requerirAutenticacion();
    try {
        $stmt = $pdo->prepare('
            SELECT p.id AS producto_id, p.id, p.nombre, p.descripcion, p.categoria, p.subcategoria,
                   p.marca, p.precio, p.stock, p.imagen, p.activo
            FROM favoritos f
            JOIN productos p ON p.id = f.producto_id
            WHERE f.usuario_id = :uid
            ORDER BY f.creado_en DESC, p.id DESC
        ');
        $stmt->execute([':uid' => $usuarioId]);
        $favoritos = $stmt->fetchAll();

        foreach ($favoritos as &$fav) {
            $fav['precio'] = (float)$fav['precio'];
            $fav['precio_formateado'] = '$' . number_format($fav['precio'], 0, ',', '.');
        }
        unset($fav);

        responderJSON(['success' => true, 'total' => count($favoritos), 'favoritos' => $favoritos]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'favoritos GET', 'No se pudieron consultar tus favoritos.');
    }

} elseif ($metodo === 'POST') {
    $usuarioId = requerirAutenticacion();
    validarTokenCSRF();

    $datos      = obtenerEntrada();
    $productoId = (int)($datos['producto_id'] ?? 0);
    if ($productoId <= 0) {
        responderJSON(['success' => false, 'error' => 'Producto no válido.'], 400);
    }

    $deseado = null;   // null = alternar
    if (array_key_exists('activo', $datos)) {
        $deseado = filter_var($datos['activo'], FILTER_VALIDATE_BOOLEAN);
    }

    try {
        $q = $pdo->prepare('SELECT id FROM productos WHERE id = :pid AND activo = 1 LIMIT 1');
        $q->execute([':pid' => $productoId]);
        if (!$q->fetch()) {
            responderJSON(['success' => false, 'error' => 'El producto no existe en la base de datos. Ejecutá la carga de productos (database/migracion_ciclo_miku.sql).'], 404);
        }

        $q = $pdo->prepare('SELECT COUNT(*) FROM favoritos WHERE usuario_id = :uid AND producto_id = :pid');
        $q->execute([':uid' => $usuarioId, ':pid' => $productoId]);
        $existente = $q->fetchColumn();

        $activo = $deseado === null ? !$existente : $deseado;

        if ($activo && !$existente) {
            try {
                $pdo->prepare('INSERT INTO favoritos (usuario_id, producto_id) VALUES (:uid, :pid)')
                    ->execute([':uid' => $usuarioId, ':pid' => $productoId]);
            } catch (PDOException $e) {
                if ($e->getCode() !== '23000') throw $e;   // ya existía (doble clic simultáneo): es correcto
            }
        } elseif (!$activo && $existente) {
            $pdo->prepare('DELETE FROM favoritos WHERE usuario_id = :uid AND producto_id = :pid')
                ->execute([':uid' => $usuarioId, ':pid' => $productoId]);
        }

        $q = $pdo->prepare('SELECT COUNT(*) FROM favoritos WHERE usuario_id = :uid');
        $q->execute([':uid' => $usuarioId]);

        responderJSON([
            'success'     => true,
            'activo'      => (bool)$activo,
            'mensaje'     => $activo ? '¡Producto guardado en tus favoritos!' : 'Producto quitado de tus favoritos.',
            'producto_id' => $productoId,
            'total'       => (int)$q->fetchColumn()
        ]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'favoritos POST', 'No se pudo actualizar tu lista de favoritos.');
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
