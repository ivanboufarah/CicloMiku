/**
 * CICLOMIKU - Solicitud de turnos del taller (guardados en MySQL)
 */
document.addEventListener('DOMContentLoaded', function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const esc = API.escapeHTML;
  const $ = id => document.getElementById(id);
  const form = document.querySelector('#formulario-turno form');
  if (!form) return;

  // Mismos precios/tiempos que publica turnosmiku.html (el servidor vuelve a calcular el precio)
  const servicios = {
    basico:     { nombre: 'Mantenimiento Básico',               precio: 20000, tiempo: '24 a 48 hs' },
    integral:   { nombre: 'Service Integral Pro',               precio: 45000, tiempo: '48 a 72 hs' },
    frenos:     { nombre: 'Purga y Frenos Hidráulicos',         precio: 25000, tiempo: '24 hs' },
    suspension: { nombre: 'Service de Horquilla y Suspensión',  precio: 38000, tiempo: '48 hs' }
  };
  const horariosSemana = ['09:00', '11:30', '14:00', '16:30'];
  const horariosSabado = ['09:00', '11:30'];

  function actualizarResumen() {
    const s = servicios[$('tipo-servicio').value] || servicios.basico;
    const r = document.getElementById('resumen-servicio'); if (r) r.textContent = s.nombre;
    const t = document.getElementById('resumen-tiempo'); if (t) t.textContent = s.tiempo;
    const p = document.getElementById('resumen-presupuesto'); if (p) p.textContent = '$' + s.precio.toLocaleString('es-AR');
  }

  function fechaLocal(d) {
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  /** Muestra solo los horarios que el taller atiende ese día (domingo cerrado, sábado hasta las 14) */
  function ajustarHorarios() {
    const sel = $('horario'), f = $('fecha').value;
    const aviso = $('aviso-fecha');
    if (!f) return;
    const dia = new Date(f + 'T12:00:00').getDay();   // 0 = domingo
    const permitidos = dia === 6 ? horariosSabado : horariosSemana;
    Array.from(sel.options).forEach(o => { o.disabled = !permitidos.includes(o.value); o.hidden = o.disabled; });
    if (!permitidos.includes(sel.value)) sel.value = permitidos[0];
    if (aviso) aviso.textContent = dia === 0 ? 'El taller no atiende los domingos. Elegí otra fecha.' : (dia === 6 ? 'Los sábados el taller atiende de 09:00 a 14:00.' : '');
  }

  const hoy = new Date();
  $('fecha').min = fechaLocal(hoy);
  const manana = new Date(hoy.getTime() + 86400000);
  $('fecha').value = fechaLocal(manana);
  $('fecha').addEventListener('change', ajustarHorarios);
  $('tipo-servicio').addEventListener('change', actualizarResumen);
  ajustarHorarios();
  actualizarResumen();

  // Prellenar datos si hay sesión
  API.estadoListo().then(estado => {
    if (estado && estado.autenticado && estado.usuario) {
      const u = estado.usuario;
      if (!$('nombre').value) $('nombre').value = (u.nombre + ' ' + (u.apellido || '')).trim();
      if (!$('email').value) $('email').value = u.email || '';
      if (!$('telefono').value && u.telefono) $('telefono').value = u.telefono;
    }
  });

  form.addEventListener('submit', async function (e) {
    e.preventDefault();
    const btn = form.querySelector('button[type="submit"]');
    const datos = {
      servicio: $('tipo-servicio').value, marca: $('marca-bici').value.trim(), modelo: $('modelo-bici').value.trim(),
      anio: $('anio-bici').value || null, tipo: $('tipo-bici').value, motivo: $('motivo').value.trim(),
      fecha: $('fecha').value, horario: $('horario').value, nombre: $('nombre').value.trim(),
      telefono: $('telefono').value.trim(), email: $('email').value.trim()
    };
    if (!datos.marca || !datos.modelo || !datos.nombre || !datos.telefono || !datos.email || !datos.fecha) {
      return API.mostrarToast('Completá todos los datos obligatorios del formulario.', 'warning');
    }

    btn.disabled = true; const txt = btn.textContent; btn.textContent = 'Enviando solicitud...';
    const res = await API.fetchAPI('PHP/api/turnos.php', { method: 'POST', body: datos });
    btn.disabled = false; btn.textContent = txt;

    if (!res.success) return API.mostrarToast(res.error || 'No se pudo registrar el turno.', 'error');

    API.actualizarEstadoSesion();
    const t = $('ticket-numero'); if (t) t.textContent = res.codigo_turno;
    const cont = $('formulario-turno');
    const logueado = API.estaAutenticado();
    cont.innerHTML = `
      <div class="text-center py-5" style="background:#fff;border-radius:8px;border:2px solid #95C1F5;padding:30px;">
        <div style="font-size:50px;margin-bottom:15px;">🚲</div>
        <h2 style="color:#142E54;font-weight:bold;">¡Solicitud de turno registrada!</h2>
        <div class="my-3 p-3" style="background:#faf8f3;border-radius:6px;display:inline-block;">
          <span class="text-muted d-block small">Tu código de turno:</span>
          <span style="font-size:26px;font-weight:bold;color:#142E54;">${esc(res.codigo_turno)}</span>
        </div>
        <p style="color:#2A467A;max-width:520px;margin:0 auto 20px;">
          Quedó solicitado para el <strong>${esc(datos.fecha)}</strong> a las <strong>${esc(datos.horario)} hs</strong>. El taller lo va a confirmar y se comunicará al teléfono ${esc(datos.telefono)}.
        </p>
        <div class="d-flex justify-content-center gap-2 flex-wrap">
          ${logueado ? '<a href="menu_usuario/historial.html" class="btn-accion">Ver en mi historial</a>' : '<a href="menu_usuario/registro.html#registro" class="btn-accion">Crear cuenta para seguir mis turnos</a>'}
          <button type="button" class="btn-accion btn-secundario" onclick="window.location.reload();">Solicitar otro turno</button>
        </div>
      </div>`;
  });
});
