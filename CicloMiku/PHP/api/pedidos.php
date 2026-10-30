<?php
/**
 * CICLOMIKU - API de pedidos (historial y registro del pedido)
 *   GET  -> pedidos del usuario autenticado con sus productos
 *   POST -> convierte el carrito del usuario en un pedido (transacción SQL)
 *
 * IMPORTANTE: el sitio NO tiene pasarela de pago. El pedido se registra como "pendiente" y
 * CicloMiku coordina pago y entrega. No se simula ningún cobro.
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';
require_once __DIR__ . '/../includes/preferencias.php';

$pdo       = obtenerConexion();
$usuarioId = requerirAutenticacion();
$metodo    = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'GET') {
    try {
        $s = $pdo->prepare('SELECT id, numero_pedido, subtotal, descuento, total, metodo_pago, estado, direccion_envio, codigo_seguimiento, creado_en
                            FROM pedidos WHERE usuario_id = :uid ORDER BY creado_en DESC, id DESC');
        $s->execute([':uid' => $usuarioId]);
        $pedidos = $s->fetchAll();

        $detallesPorPedido = [];
        if ($pedidos) {
            $ids = array_column($pedidos, 'id');
            $marcas = implode(',', array_fill(0, count($ids), '?'));
            $d = $pdo->prepare("SELECT pd.pedido_id, pd.producto_id, pd.nombre_producto, pd.precio_unitario, pd.cantidad, pd.subtotal, p.imagen
                                FROM pedido_detalle pd LEFT JOIN productos p ON p.id = pd.producto_id
                                WHERE pd.pedido_id IN ($marcas) ORDER BY pd.id ASC");
            $d->execute($ids);
            foreach ($d->fetchAll() as $fila) {
                $fila['precio_unitario']     = (float)$fila['precio_unitario'];
                $fila['subtotal']            = (float)$fila['subtotal'];
                $fila['cantidad']            = (int)$fila['cantidad'];
                $fila['precio_formateado']   = formatoMonto($fila['precio_unitario']);
                $fila['subtotal_formateado'] = formatoMonto($fila['subtotal']);
                $detallesPorPedido[$fila['pedido_id']][] = $fila;
            }
        }

        foreach ($pedidos as &$p) {
            $p['subtotal']          = (float)$p['subtotal'];
            $p['descuento']         = (float)$p['descuento'];
            $p['total']             = (float)$p['total'];
            $p['total_formateado']  = formatoMonto($p['total']);
            $p['fecha_formateada']  = fechaEspanol($p['creado_en'], true);
            $p['estado_texto']      = CM_ESTADOS_PEDIDO[$p['estado']] ?? ucfirst((string)$p['estado']);
            $p['detalles']          = $detallesPorPedido[$p['id']] ?? [];
        }
        unset($p);

        responderJSON(['success' => true, 'pedidos' => $pedidos]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'pedidos GET', 'No se pudo consultar tu historial de compras.');
    }

} elseif ($metodo === 'POST') {
    validarTokenCSRF();

    try {
        $s = $pdo->prepare('SELECT id FROM carrito WHERE usuario_id = :uid ORDER BY id ASC LIMIT 1');
        $s->execute([':uid' => $usuarioId]);
        $carritoId = $s->fetchColumn();
        if (!$carritoId) {
            responderJSON(['success' => false, 'error' => 'Tu carrito está vacío.'], 400);
        }

        $pdo->beginTransaction();

        // Se bloquean ítems y productos: precio y stock se toman del servidor, nunca del navegador
        $s = $pdo->prepare('
            SELECT cd.id AS detalle_id, cd.producto_id, cd.cantidad, p.nombre, p.precio, p.stock, p.activo
            FROM carrito_detalle cd
            JOIN productos p ON p.id = cd.producto_id
            WHERE cd.carrito_id = :cid
            FOR UPDATE
        ');
        $s->execute([':cid' => $carritoId]);
        $items = $s->fetchAll();

        if (!$items) {
            $pdo->rollBack();
            responderJSON(['success' => false, 'error' => 'Tu carrito está vacío.'], 400);
        }

        $subtotal = 0.0;
        foreach ($items as $it) {
            if ((int)$it['activo'] !== 1) {
                $pdo->rollBack();
                responderJSON(['success' => false, 'error' => "«{$it['nombre']}» ya no está disponible. Quitalo del carrito para continuar."], 409);
            }
            if ((int)$it['stock'] < (int)$it['cantidad']) {
                $pdo->rollBack();
                responderJSON(['success' => false, 'error' => "Stock insuficiente de «{$it['nombre']}». Quedan {$it['stock']} unidades."], 409);
            }
            $subtotal += (float)$it['precio'] * (int)$it['cantidad'];
        }
        $descuento = 0.0;                 // No hay descuentos reales configurados
        $total     = $subtotal - $descuento;

        // Dirección (si el usuario cargó una) y preferencia de pago
        $s = $pdo->prepare('SELECT direccion, ciudad, codigo_postal FROM usuarios WHERE id = :uid');
        $s->execute([':uid' => $usuarioId]);
        $u = $s->fetch() ?: [];
        $partes = array_filter([trim($u['direccion'] ?? ''), trim($u['ciudad'] ?? ''), trim($u['codigo_postal'] ?? '')], 'strlen');
        $dirEnvio = $partes ? implode(', ', $partes) : null;

        $s = $pdo->prepare('SELECT metodo_pago_defecto FROM configuraciones WHERE usuario_id = :uid');
        $s->execute([':uid' => $usuarioId]);
        $metodoPago = etiquetaMetodoPago($s->fetchColumn() ?: 'sin_definir');

        // Número de pedido único
        $insPedido = $pdo->prepare("INSERT INTO pedidos (numero_pedido, usuario_id, subtotal, descuento, total, metodo_pago, estado, direccion_envio)
                                    VALUES (:np, :uid, :sub, :des, :tot, :mp, 'pendiente', :dir)");
        $numeroPedido = null;
        for ($intento = 0; $intento < 5 && $numeroPedido === null; $intento++) {
            $candidato = 'CM-' . date('ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
            try {
                $insPedido->execute([':np' => $candidato, ':uid' => $usuarioId, ':sub' => $subtotal, ':des' => $descuento,
                                     ':tot' => $total, ':mp' => $metodoPago, ':dir' => $dirEnvio]);
                $numeroPedido = $candidato;
            } catch (PDOException $e) {
                if ($e->getCode() !== '23000') throw $e;   // 23000 = número repetido: se reintenta
            }
        }
        if ($numeroPedido === null) {
            throw new RuntimeException('No se pudo generar un número de pedido único.');
        }
        $pedidoId = (int)$pdo->lastInsertId();

        $insDet = $pdo->prepare('INSERT INTO pedido_detalle (pedido_id, producto_id, nombre_producto, precio_unitario, cantidad, subtotal)
                                 VALUES (:pid, :prod, :nombre, :precio, :cant, :sub)');
        // OJO: con consultas preparadas nativas cada marcador debe tener un nombre distinto
        $descStock = $pdo->prepare('UPDATE productos SET stock = stock - :cant_a WHERE id = :id AND stock >= :cant_b');

        foreach ($items as $it) {
            $cant = (int)$it['cantidad'];
            $insDet->execute([':pid' => $pedidoId, ':prod' => $it['producto_id'], ':nombre' => $it['nombre'],
                              ':precio' => $it['precio'], ':cant' => $cant, ':sub' => (float)$it['precio'] * $cant]);

            $descStock->execute([':cant_a' => $cant, ':id' => $it['producto_id'], ':cant_b' => $cant]);
            if ($descStock->rowCount() !== 1) {
                throw new RuntimeException('El stock cambió mientras se procesaba el pedido.');
            }
        }

        $pdo->prepare('DELETE FROM carrito_detalle WHERE carrito_id = :cid')->execute([':cid' => $carritoId]);

        $pdo->prepare("INSERT INTO notificaciones (usuario_id, tipo, icono, titulo, mensaje, leida) VALUES (:uid, 'pedido', '📦', :t, :m, 0)")
            ->execute([
                ':uid' => $usuarioId,
                ':t'   => "Pedido {$numeroPedido} registrado",
                ':m'   => 'Registramos tu pedido por ' . formatoMonto($total) . '. Está pendiente: CicloMiku se va a comunicar con vos para coordinar el pago y la entrega.'
            ]);

        $pdo->commit();

        responderJSON([
            'success'          => true,
            'mensaje'          => "Pedido {$numeroPedido} registrado. CicloMiku se comunicará con vos para coordinar el pago y la entrega.",
            'numero_pedido'    => $numeroPedido,
            'total'            => $total,
            'total_formateado' => formatoMonto($total)
        ], 201);

    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        error_log('CicloMiku - pedidos POST: ' . $e->getMessage());
        $r = ['success' => false, 'error' => 'No se pudo registrar el pedido. No se realizó ningún cambio.'];
        if (CM_DEBUG) $r['detalle'] = $e->getMessage();
        responderJSON($r, 500);
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
