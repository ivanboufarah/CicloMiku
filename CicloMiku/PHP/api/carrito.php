<?php
/**
 * CICLOMIKU - API del carrito (persistente en MariaDB)
 *   GET  -> ítems y totales (precios y stock siempre leídos del servidor)
 *   POST -> accion: agregar | modificar (alias: actualizar) | eliminar | vaciar
 * Cada usuario tiene su carrito; un visitante tiene uno ligado a su sesión y se une al iniciar sesión.
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

const CM_CANTIDAD_MAX_POR_ITEM = 20;

$pdo           = obtenerConexion();
$usuarioId     = obtenerUsuarioId();
$cartSessionId = obtenerSessionCartId();
$metodo        = $_SERVER['REQUEST_METHOD'];

function buscarCarritoId(PDO $pdo, $usuarioId, $cartSessionId) {
    if ($usuarioId) {
        $s = $pdo->prepare('SELECT id FROM carrito WHERE usuario_id = :uid ORDER BY id ASC LIMIT 1');
        $s->execute([':uid' => $usuarioId]);
    } else {
        $s = $pdo->prepare('SELECT id FROM carrito WHERE session_id = :sid AND usuario_id IS NULL ORDER BY id ASC LIMIT 1');
        $s->execute([':sid' => $cartSessionId]);
    }
    $id = $s->fetchColumn();
    return $id ? (int)$id : null;
}

function obtenerOCrearCarritoId(PDO $pdo, $usuarioId, $cartSessionId) {
    $id = buscarCarritoId($pdo, $usuarioId, $cartSessionId);
    if ($id) return $id;
    if ($usuarioId) {
        $pdo->prepare('INSERT INTO carrito (usuario_id) VALUES (:uid)')->execute([':uid' => $usuarioId]);
    } else {
        $pdo->prepare('INSERT INTO carrito (session_id) VALUES (:sid)')->execute([':sid' => $cartSessionId]);
    }
    return (int)$pdo->lastInsertId();
}

if ($metodo === 'GET') {
    try {
        $carritoId = buscarCarritoId($pdo, $usuarioId, $cartSessionId);
        $items = [];

        if ($carritoId) {
            $s = $pdo->prepare('
                SELECT cd.id AS detalle_id, cd.producto_id, cd.cantidad, cd.color, cd.talle,
                       p.nombre, p.precio, p.stock, p.imagen, p.categoria, p.activo
                FROM carrito_detalle cd
                JOIN productos p ON p.id = cd.producto_id
                WHERE cd.carrito_id = :cid
                ORDER BY cd.id ASC
            ');
            $s->execute([':cid' => $carritoId]);
            $items = $s->fetchAll();
        }

        $subtotal = 0.0;
        $totalItems = 0;
        $hayProblemas = false;

        foreach ($items as &$item) {
            $item['precio']   = (float)$item['precio'];
            $item['cantidad'] = (int)$item['cantidad'];
            $item['stock']    = (int)$item['stock'];
            $item['disponible'] = ((int)$item['activo'] === 1 && $item['stock'] > 0);

            if ($item['disponible'] && $item['cantidad'] > $item['stock']) {
                $item['cantidad'] = $item['stock'];
                $pdo->prepare('UPDATE carrito_detalle SET cantidad = :cant WHERE id = :id')
                    ->execute([':cant' => $item['cantidad'], ':id' => $item['detalle_id']]);
            }
            if (!$item['disponible']) $hayProblemas = true;

            $item['subtotal'] = $item['disponible'] ? $item['precio'] * $item['cantidad'] : 0.0;
            $item['precio_formateado']   = '$' . number_format($item['precio'], 0, ',', '.');
            $item['subtotal_formateado'] = '$' . number_format($item['subtotal'], 0, ',', '.');

            $subtotal   += $item['subtotal'];
            $totalItems += $item['cantidad'];
        }
        unset($item);

        responderJSON([
            'success' => true,
            'items'   => $items,
            'resumen' => [
                'subtotal'            => $subtotal,
                'subtotal_formateado' => '$' . number_format($subtotal, 0, ',', '.'),
                'descuento'           => 0,
                'descuento_formateado' => '$0',
                'envio'               => null,
                'total'               => $subtotal,
                'total_formateado'    => '$' . number_format($subtotal, 0, ',', '.'),
                'total_items'         => $totalItems,
                'hay_sin_stock'       => $hayProblemas
            ]
        ]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'carrito GET', 'No se pudo cargar el carrito.');
    }

} elseif ($metodo === 'POST') {
    validarTokenCSRF();

    $datos      = obtenerEntrada();
    $accion     = limpiarTexto($datos['accion'] ?? '', 20);
    if ($accion === 'actualizar') $accion = 'modificar';   // nombre usado por versiones anteriores del JS
    $productoId = (int)($datos['producto_id'] ?? 0);
    $detalleId  = (int)($datos['detalle_id'] ?? 0);
    $cantidad   = (int)($datos['cantidad'] ?? 1);
    $color      = limpiarTexto($datos['color'] ?? '', 50);
    $talle      = limpiarTexto($datos['talle'] ?? '', 50);

    try {
        if ($accion === 'agregar') {
            if ($productoId <= 0 || $cantidad < 1 || $cantidad > CM_CANTIDAD_MAX_POR_ITEM) {
                responderJSON(['success' => false, 'error' => 'Producto o cantidad no válidos.'], 400);
            }

            $s = $pdo->prepare('SELECT id, nombre, stock FROM productos WHERE id = :pid AND activo = 1 LIMIT 1');
            $s->execute([':pid' => $productoId]);
            $producto = $s->fetch();
            if (!$producto) {
                responderJSON(['success' => false, 'error' => 'El producto no existe en la base de datos. Ejecutá la carga de productos (database/migracion_ciclo_miku.sql).'], 404);
            }
            if ((int)$producto['stock'] <= 0) {
                responderJSON(['success' => false, 'error' => 'Este producto no tiene stock disponible.'], 409);
            }

            $pdo->beginTransaction();
            $carritoId = obtenerOCrearCarritoId($pdo, $usuarioId, $cartSessionId);

            $s = $pdo->prepare('SELECT id, cantidad FROM carrito_detalle
                                WHERE carrito_id = :cid AND producto_id = :pid AND COALESCE(color, \'\') = :color AND COALESCE(talle, \'\') = :talle
                                LIMIT 1 FOR UPDATE');
            $s->execute([':cid' => $carritoId, ':pid' => $productoId, ':color' => $color, ':talle' => $talle]);
            $existente = $s->fetch();

            $nueva = $cantidad + ($existente ? (int)$existente['cantidad'] : 0);
            if ($nueva > (int)$producto['stock'] || $nueva > CM_CANTIDAD_MAX_POR_ITEM) {
                $pdo->rollBack();
                $tope = min((int)$producto['stock'], CM_CANTIDAD_MAX_POR_ITEM);
                responderJSON(['success' => false, 'error' => "No se pueden agregar más unidades: el máximo por compra de este producto es {$tope}."], 409);
            }

            if ($existente) {
                $pdo->prepare('UPDATE carrito_detalle SET cantidad = :cant WHERE id = :id')
                    ->execute([':cant' => $nueva, ':id' => $existente['id']]);
            } else {
                $pdo->prepare('INSERT INTO carrito_detalle (carrito_id, producto_id, cantidad, color, talle) VALUES (:cid, :pid, :cant, :color, :talle)')
                    ->execute([':cid' => $carritoId, ':pid' => $productoId, ':cant' => $nueva, ':color' => $color, ':talle' => $talle]);
            }
            $pdo->commit();

            responderJSON(['success' => true, 'mensaje' => $producto['nombre'] . ' agregado al carrito.', 'cantidad_en_carrito' => $nueva]);
        }

        $carritoId = buscarCarritoId($pdo, $usuarioId, $cartSessionId);
        if (!$carritoId) {
            responderJSON(['success' => false, 'error' => 'Tu carrito está vacío.'], 404);
        }

        // Localizar el ítem SOLO dentro del carrito del propio usuario/visitante
        $buscarItem = function () use ($pdo, $carritoId, $detalleId, $productoId) {
            if ($detalleId > 0) {
                $s = $pdo->prepare('SELECT cd.id, cd.cantidad, p.stock, p.activo FROM carrito_detalle cd JOIN productos p ON p.id = cd.producto_id WHERE cd.id = :did AND cd.carrito_id = :cid LIMIT 1');
                $s->execute([':did' => $detalleId, ':cid' => $carritoId]);
            } else {
                $s = $pdo->prepare('SELECT cd.id, cd.cantidad, p.stock, p.activo FROM carrito_detalle cd JOIN productos p ON p.id = cd.producto_id WHERE cd.producto_id = :pid AND cd.carrito_id = :cid LIMIT 1');
                $s->execute([':pid' => $productoId, ':cid' => $carritoId]);
            }
            return $s->fetch();
        };

        if ($accion === 'modificar') {
            $item = $buscarItem();
            if (!$item) {
                responderJSON(['success' => false, 'error' => 'El producto no está en tu carrito.'], 404);
            }
            if ($cantidad <= 0) {
                $pdo->prepare('DELETE FROM carrito_detalle WHERE id = :id')->execute([':id' => $item['id']]);
                responderJSON(['success' => true, 'mensaje' => 'Producto eliminado del carrito.']);
            }
            $tope = min((int)$item['stock'], CM_CANTIDAD_MAX_POR_ITEM);
            if ($cantidad > $tope) {
                responderJSON(['success' => false, 'error' => "Cantidad máxima disponible para este producto: {$tope}."], 409);
            }
            $pdo->prepare('UPDATE carrito_detalle SET cantidad = :cant WHERE id = :id')->execute([':cant' => $cantidad, ':id' => $item['id']]);
            responderJSON(['success' => true, 'mensaje' => 'Cantidad actualizada.']);

        } elseif ($accion === 'eliminar') {
            $item = $buscarItem();
            if ($item) {
                $pdo->prepare('DELETE FROM carrito_detalle WHERE id = :id')->execute([':id' => $item['id']]);
            }
            responderJSON(['success' => true, 'mensaje' => 'Producto eliminado del carrito.']);

        } elseif ($accion === 'vaciar') {
            $pdo->prepare('DELETE FROM carrito_detalle WHERE carrito_id = :cid')->execute([':cid' => $carritoId]);
            responderJSON(['success' => true, 'mensaje' => 'El carrito fue vaciado.']);

        } else {
            responderJSON(['success' => false, 'error' => 'Acción no válida.'], 400);
        }

    } catch (PDOException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        responderErrorSQL($e, 'carrito POST', 'No se pudo actualizar el carrito.');
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
