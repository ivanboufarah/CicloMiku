/**
 * CICLOMIKU - Notificaciones reales del usuario (tabla notificaciones)
 */
document.addEventListener('DOMContentLoaded', function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const esc = API.escapeHTML;
  const cont = document.getElementById('contenedor-notifs');
  if (!cont) return;

  const caja = (icono, titulo, texto, extra) => `<div class="text-center py-5" style="background:#faf8f3;border:2px dashed #95C1F5;border-radius:8px;padding:40px;">
    <div style="font-size:40px;margin-bottom:10px;">${icono}</div><h4 style="color:#142E54;">${titulo}</h4>
    <p style="color:#2A467A;margin-bottom:15px;">${texto}</p>${extra || ''}</div>`;

  async function cargar() {
    cont.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" role="status"></div></div>';
    const res = await API.fetchAPI('PHP/api/notificaciones.php');
    if (!res.success) {
      cont.innerHTML = res.requiere_login
        ? caja('🔔', 'Iniciá sesión para ver tus avisos', 'Acá vas a ver el estado de tus pedidos y turnos.', '<a href="registro.html" class="btn-accion">Iniciar sesión</a>')
        : `<div class="alert alert-danger">${esc(res.error || 'No se pudieron cargar las notificaciones.')}</div>`;
      return;
    }
    if (!res.notificaciones.length) { cont.innerHTML = caja('✨', 'No tenés notificaciones', 'Cuando haya novedades de tus pedidos o turnos van a aparecer acá.'); return; }

    cont.innerHTML = '';
    res.notificaciones.forEach(n => {
      const el = document.createElement('div');
      el.className = 'item-notificacion' + (n.leida ? '' : ' no-leida');
      el.innerHTML = `
        <div class="icono-notif">${esc(n.icono || '🔔')}</div>
        <div class="contenido-notif">
          <div class="d-flex justify-content-between align-items-center"><h4>${esc(n.titulo)}</h4>${n.leida ? '' : '<span class="badge bg-primary text-white">Nueva</span>'}</div>
          <p>${esc(n.mensaje)}</p><div class="fecha-notif">${esc(n.fecha_formateada)}</div>
        </div>
        <div class="d-flex flex-column gap-1">
          ${n.leida ? '' : `<button type="button" data-leer="${n.id}" title="Marcar como leída" style="background:none;border:none;cursor:pointer;color:#2A467A;font-size:16px;">✓</button>`}
          <button type="button" data-borrar="${n.id}" title="Eliminar" style="background:none;border:none;cursor:pointer;color:#718096;font-size:16px;">✕</button>
        </div>`;
      cont.appendChild(el);
    });
  }

  async function accion(body, okMsg) {
    const r = await API.fetchAPI('PHP/api/notificaciones.php', { method: 'POST', body });
    if (r.success) { if (okMsg) API.mostrarToast(okMsg, 'success'); await cargar(); API.actualizarEstadoSesion(); }
    else API.mostrarToast(r.error || 'No se pudo actualizar.', 'error');
  }

  cont.addEventListener('click', (e) => {
    const l = e.target.closest('[data-leer]'), b = e.target.closest('[data-borrar]');
    if (l) accion({ accion: 'marcar_leida', id: Number(l.dataset.leer) });
    if (b) accion({ accion: 'eliminar', id: Number(b.dataset.borrar) });
  });
  window.marcarTodasLeidas = () => accion({ accion: 'marcar_todas' }, 'Todas las notificaciones quedaron como leídas.');

  cargar();
});
