<?php
/**
 * CICLOMIKU - Validación compartida de datos personales (perfil y configuración)
 */

/**
 * Valida y limpia los datos personales enviados. Solo procesa las claves presentes en $datos.
 * @return array [array $limpios, string|null $error]
 */
function validarDatosPersonales(array $datos) {
    $limpios = [];

    if (array_key_exists('nombre', $datos)) {
        $nombre = limpiarTexto($datos['nombre'], 100);
        $apellido = array_key_exists('apellido', $datos) ? limpiarTexto($datos['apellido'], 100) : null;
        if ($apellido === null && strpos($nombre, ' ') !== false) {   // compatibilidad: "Juan Pérez" en un solo campo
            [$nombre, $apellido] = explode(' ', $nombre, 2);
            $apellido = trim($apellido);
        }
        if ($nombre === '') return [[], 'El nombre no puede estar vacío.'];
        $limpios['nombre'] = $nombre;
        if ($apellido !== null) {
            if ($apellido === '') return [[], 'El apellido no puede estar vacío.'];
            $limpios['apellido'] = $apellido;
        }
    }

    if (array_key_exists('telefono', $datos)) {
        $tel = limpiarTexto($datos['telefono'], 50);
        if ($tel !== '' && !preg_match('/^[0-9 +().-]{6,25}$/', $tel)) {
            return [[], 'El teléfono solo puede contener números, espacios y los símbolos + ( ) - .'];
        }
        $limpios['telefono'] = $tel;
    }

    if (array_key_exists('dni', $datos)) {
        $dni = limpiarTexto($datos['dni'], 30);
        if ($dni !== '' && !preg_match('/^[0-9A-Za-z. -]{5,30}$/', $dni)) {
            return [[], 'El documento ingresado no es válido.'];
        }
        $limpios['dni'] = $dni;
    }

    if (array_key_exists('fecha_nacimiento', $datos)) {
        $f = limpiarTexto($datos['fecha_nacimiento'], 10);
        if ($f === '') {
            $limpios['fecha_nacimiento'] = null;
        } else {
            $d = DateTime::createFromFormat('Y-m-d', $f);
            if (!$d || $d->format('Y-m-d') !== $f || $f > date('Y-m-d') || $f < '1900-01-01') {
                return [[], 'La fecha de nacimiento no es válida.'];
            }
            $limpios['fecha_nacimiento'] = $f;
        }
    }

    foreach (['direccion' => 255, 'ciudad' => 100, 'codigo_postal' => 20, 'instrucciones_entrega' => 500, 'bici_actual_modelo' => 150] as $campo => $max) {
        if (array_key_exists($campo, $datos)) {
            $limpios[$campo] = limpiarTexto($datos[$campo], $max);
        }
    }
    if (isset($limpios['codigo_postal']) && $limpios['codigo_postal'] !== '' && !preg_match('/^[0-9A-Za-z -]{3,20}$/', $limpios['codigo_postal'])) {
        return [[], 'El código postal no es válido.'];
    }

    return [$limpios, null];
}

/** UPDATE dinámico de usuarios con los campos ya validados (los nombres de columna salen de una lista fija). */
function actualizarUsuario(PDO $pdo, $usuarioId, array $campos) {
    $permitidos = ['nombre','apellido','telefono','dni','fecha_nacimiento','direccion','ciudad','codigo_postal','instrucciones_entrega','bici_actual_modelo'];
    $sets = []; $params = [':uid' => $usuarioId];
    foreach ($campos as $col => $valor) {
        if (!in_array($col, $permitidos, true)) continue;
        $sets[] = "`$col` = :$col";
        $params[":$col"] = $valor;
    }
    if (!$sets) return;
    $pdo->prepare('UPDATE usuarios SET ' . implode(', ', $sets) . ' WHERE id = :uid')->execute($params);
}
