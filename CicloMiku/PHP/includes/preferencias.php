<?php
/**
 * CICLOMIKU - Valores permitidos para preferencias y estados (una sola fuente de verdad)
 * IMPORTANTE: nunca se guardan datos de tarjetas. Solo una preferencia de forma de pago.
 */

const CM_METODOS_PAGO = [
    'sin_definir'   => 'A coordinar con CicloMiku',
    'efectivo'      => 'Efectivo (en el local)',
    'transferencia' => 'Transferencia bancaria',
    'tarjeta'       => 'Tarjeta (se coordina con el local)'
];

const CM_TEMAS = ['claro', 'oscuro'];

const CM_ESTADOS_PEDIDO = [
    'pendiente'      => 'Pendiente de confirmación',
    'confirmado'     => 'Confirmado',
    'en_preparacion' => 'En preparación',
    'enviado'        => 'Enviado',
    'entregado'      => 'Entregado',
    'cancelado'      => 'Cancelado'
];

const CM_ESTADOS_TURNO = [
    'solicitado' => 'Solicitado (a confirmar por el taller)',
    'confirmado' => 'Confirmado',
    'en_taller'  => 'En el taller',
    'completado' => 'Completado',
    'cancelado'  => 'Cancelado'
];

function etiquetaMetodoPago($clave) {
    return CM_METODOS_PAGO[$clave] ?? CM_METODOS_PAGO['sin_definir'];
}

function formatoMonto($n) {
    return '$' . number_format((float)$n, 0, ',', '.');
}

function fechaEspanol($fechaSql, $conHora = false) {
    $meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    $t = strtotime($fechaSql);
    if (!$t) return (string)$fechaSql;
    $txt = date('j', $t) . ' de ' . $meses[(int)date('n', $t) - 1] . ' de ' . date('Y', $t);
    return $conHora ? $txt . ' a las ' . date('H:i', $t) . ' hs' : $txt;
}
