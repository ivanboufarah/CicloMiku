<?php
/**
 * CICLOMIKU - API de turnos del taller
 *   GET  -> turnos del usuario autenticado (visitantes: lista vacía)
 *   POST -> solicita un turno (vinculado al usuario si hay sesión). Queda "solicitado": lo confirma el taller.
 */
require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';
require_once __DIR__ . '/../includes/preferencias.php';

// Servicios y precios: son los publicados en turnosmiku.html
const CM_SERVICIOS = [
    'basico'     => ['nombre' => 'Mantenimiento Básico (Ajuste, lubricación y regulación)',          'precio' => 20000],
    'integral'   => ['nombre' => 'Service Integral Pro (Desarme completo, engrase y centrado)',      'precio' => 45000],
    'frenos'     => ['nombre' => 'Purga y Calibración de Frenos Hidráulicos',                        'precio' => 25000],
    'suspension' => ['nombre' => 'Service de Horquilla y Suspensión',                                'precio' => 38000]
];
const CM_TIPOS_BICI = ['mtb', 'ruta', 'urbana', 'gravel'];
// Horarios del formulario. Según el pie de página: Lun-Vie 09:00-18:00, Sáb 09:00-14:00, domingo cerrado.
const CM_HORARIOS_SEMANA = ['09:00', '11:30', '14:00', '16:30'];
const CM_HORARIOS_SABADO = ['09:00', '11:30'];
const CM_BICIS_POR_FRANJA = 3;

$pdo       = obtenerConexion();
$usuarioId = obtenerUsuarioId();
$metodo    = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'GET') {
    try {
        $turnos = [];
        if ($usuarioId) {
            $s = $pdo->prepare('SELECT id, codigo_turno, servicio, marca_bici, modelo_bici, anio_bici, tipo_bici, motivo, fecha_turno, horario_turno,
                                       nombre_cliente, telefono_cliente, email_cliente, presupuesto_base, mecanico_asignado, estado, creado_en
                                FROM turnos WHERE usuario_id = :uid ORDER BY fecha_turno DESC, horario_turno DESC');
            $s->execute([':uid' => $usuarioId]);
            $turnos = $s->fetchAll();
        }
        foreach ($turnos as &$t) {
            $t['presupuesto_base']       = $t['presupuesto_base'] !== null ? (float)$t['presupuesto_base'] : null;
            $t['presupuesto_formateado'] = $t['presupuesto_base'] !== null ? formatoMonto($t['presupuesto_base']) : null;
            $t['fecha_formateada']       = fechaEspanol($t['fecha_turno']);
            $t['estado_texto']           = CM_ESTADOS_TURNO[$t['estado']] ?? ucfirst((string)$t['estado']);
        }
        unset($t);
        responderJSON(['success' => true, 'turnos' => $turnos]);
    } catch (PDOException $e) {
        responderErrorSQL($e, 'turnos GET', 'No se pudieron consultar los turnos.');
    }

} elseif ($metodo === 'POST') {
    validarTokenCSRF();
    $d = obtenerEntrada();

    $servicioKey = limpiarTexto($d['servicio'] ?? '', 20);
    $marca    = limpiarTexto($d['marca'] ?? '', 100);
    $modelo   = limpiarTexto($d['modelo'] ?? '', 100);
    $anioRaw  = $d['anio'] ?? null;
    $tipo     = limpiarTexto($d['tipo'] ?? 'mtb', 20);
    $motivo   = limpiarTexto($d['motivo'] ?? '', 1000);
    $fecha    = limpiarTexto($d['fecha'] ?? '', 10);
    $horario  = limpiarTexto($d['horario'] ?? '', 5);
    $nombre   = limpiarTexto($d['nombre'] ?? '', 100);
    $telefono = limpiarTexto($d['telefono'] ?? '', 50);
    $email    = filter_var(limpiarTexto($d['email'] ?? '', 150), FILTER_VALIDATE_EMAIL);

    $errores = [];
    if (!isset(CM_SERVICIOS[$servicioKey]))            $errores[] = 'Elegí un servicio válido.';
    if ($marca === '')                                  $errores[] = 'Ingresá la marca de la bicicleta.';
    if ($modelo === '')                                 $errores[] = 'Ingresá el modelo de la bicicleta.';
    if (!in_array($tipo, CM_TIPOS_BICI, true))          $errores[] = 'Elegí un tipo de bicicleta válido.';
    $anio = null;
    if ($anioRaw !== null && $anioRaw !== '') {
        $anio = (int)$anioRaw;
        if ($anio < 1950 || $anio > (int)date('Y') + 1) $errores[] = 'El año de la bicicleta no es válido.';
    }
    if ($nombre === '')                                 $errores[] = 'Ingresá tu nombre.';
    if (!preg_match('/^[0-9 +().-]{6,25}$/', $telefono)) $errores[] = 'Ingresá un teléfono válido.';
    if (!$email)                                        $errores[] = 'Ingresá un correo electrónico válido.';

    $dt = DateTime::createFromFormat('Y-m-d', $fecha);
    if (!$dt || $dt->format('Y-m-d') !== $fecha) {
        $errores[] = 'Elegí una fecha válida.';
    } else {
        $hoy = date('Y-m-d');
        $dia = (int)$dt->format('N');   // 1 = lunes ... 7 = domingo
        if ($fecha < $hoy)                                  $errores[] = 'La fecha del turno no puede ser anterior a hoy.';
        elseif ($fecha > date('Y-m-d', strtotime('+1 year'))) $errores[] = 'La fecha del turno es demasiado lejana.';
        elseif ($dia === 7)                                 $errores[] = 'El taller no atiende los domingos.';
        else {
            $permitidos = ($dia === 6) ? CM_HORARIOS_SABADO : CM_HORARIOS_SEMANA;
            if (!in_array($horario, $permitidos, true)) {
                $errores[] = 'Ese horario no está disponible ese día. Horarios: ' . implode(', ', $permitidos) . ' hs.';
            } elseif ($fecha === $hoy && $horario <= date('H:i')) {
                $errores[] = 'Ese horario ya pasó. Elegí otro.';
            }
        }
    }
    if ($errores) {
        responderJSON(['success' => false, 'error' => implode(' ', $errores), 'errores' => $errores], 400);
    }

    $servicio = CM_SERVICIOS[$servicioKey];

    try {
        $pdo->beginTransaction();

        // Cupo de la franja (bloquea las filas de esa fecha para evitar sobreventa de cupos)
        $s = $pdo->prepare("SELECT id, usuario_id, email_cliente FROM turnos WHERE fecha_turno = :f AND horario_turno = :h AND estado <> 'cancelado' FOR UPDATE");
        $s->execute([':f' => $fecha, ':h' => $horario]);
        $enFranja = $s->fetchAll();

        if (count($enFranja) >= CM_BICIS_POR_FRANJA) {
            $pdo->rollBack();
            responderJSON(['success' => false, 'error' => "El horario {$horario} del {$fecha} está completo. Elegí otro horario u otro día."], 409);
        }
        foreach ($enFranja as $t) {
            if (($usuarioId && (int)$t['usuario_id'] === $usuarioId) || strcasecmp($t['email_cliente'], $email) === 0) {
                $pdo->rollBack();
                responderJSON(['success' => false, 'error' => 'Ya tenés un turno solicitado en ese mismo día y horario.'], 409);
            }
        }

        $ins = $pdo->prepare("INSERT INTO turnos (codigo_turno, usuario_id, servicio, marca_bici, modelo_bici, anio_bici, tipo_bici, motivo,
                                                  fecha_turno, horario_turno, nombre_cliente, telefono_cliente, email_cliente, presupuesto_base, estado)
                              VALUES (:codigo, :uid, :servicio, :marca, :modelo, :anio, :tipo, :motivo, :fecha, :horario, :nombre, :tel, :email, :presupuesto, 'solicitado')");

        $codigo = null;
        for ($i = 0; $i < 5 && $codigo === null; $i++) {
            $candidato = 'CM-T' . date('ymd') . '-' . strtoupper(bin2hex(random_bytes(2)));
            try {
                $ins->execute([':codigo' => $candidato, ':uid' => $usuarioId, ':servicio' => $servicio['nombre'], ':marca' => $marca,
                               ':modelo' => $modelo, ':anio' => $anio, ':tipo' => $tipo, ':motivo' => $motivo, ':fecha' => $fecha,
                               ':horario' => $horario, ':nombre' => $nombre, ':tel' => $telefono, ':email' => $email,
                               ':presupuesto' => $servicio['precio']]);
                $codigo = $candidato;
            } catch (PDOException $e) {
                if ($e->getCode() !== '23000') throw $e;   // código repetido: se reintenta
            }
        }
        if ($codigo === null) throw new RuntimeException('No se pudo generar un código de turno único.');

        if ($usuarioId) {
            $pdo->prepare("INSERT INTO notificaciones (usuario_id, tipo, icono, titulo, mensaje, leida) VALUES (:uid, 'turno', '🔧', :t, :m, 0)")
                ->execute([
                    ':uid' => $usuarioId,
                    ':t'   => "Turno solicitado: {$codigo}",
                    ':m'   => "Recibimos tu solicitud de turno para {$marca} {$modelo} el {$fecha} a las {$horario} hs. El taller la va a confirmar."
                ]);
        }

        $pdo->commit();

        responderJSON([
            'success'                => true,
            'mensaje'                => 'Solicitud de turno registrada. El taller la va a confirmar.',
            'codigo_turno'           => $codigo,
            'servicio'               => $servicio['nombre'],
            'presupuesto_base'       => $servicio['precio'],
            'presupuesto_formateado' => formatoMonto($servicio['precio']),
            'fecha'                  => $fecha,
            'horario'                => $horario,
            'estado'                 => 'solicitado'
        ], 201);

    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        error_log('CicloMiku - turnos POST: ' . $e->getMessage());
        $r = ['success' => false, 'error' => 'No se pudo registrar el turno.'];
        if (CM_DEBUG) $r['detalle'] = $e->getMessage();
        responderJSON($r, 500);
    }

} else {
    responderJSON(['success' => false, 'error' => 'Método no soportado.'], 405);
}
