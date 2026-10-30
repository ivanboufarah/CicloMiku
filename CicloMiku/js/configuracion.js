/**
 * CICLOMIKU - Configuración: datos, contraseña y preferencias guardadas en MySQL
 */
document.addEventListener('DOMContentLoaded', async function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const $ = id => document.getElementById(id);
  const form = $('form-config');
  const main = document.querySelector('main');

  const texto = ['nombre', 'apellido', 'telefono', 'dni', 'direccion', 'ciudad', 'codigo_postal', 'instrucciones_entrega'];
  const flags = { 'notif-wa': 'notif_whatsapp_taller', 'notif-recordatorio': 'notif_recordatorio_turno', 'notif-email': 'notif_email_pedidos', 'notif-promos': 'notif_promos_club' };

  window.alternarPass = function (inputId, btn) {
    const el = $(inputId); if (!el) return;
    const oculto = el.type === 'password';
    el.type = oculto ? 'text' : 'password';
    btn.textContent = oculto ? 'Ocultar' : 'Mostrar';
  };

  const res = await API.fetchAPI('PHP/api/configuracion.php');
  if (!res.success) {
    const sinLogin = res.requiere_login;
    main.innerHTML = `<div class="tarjeta-usuario text-center py-5"><div style="font-size:40px;">${sinLogin ? '🔒' : '⚠️'}</div>
      <h3 style="color:#142E54;">${sinLogin ? 'Iniciá sesión para ver tu configuración' : 'No se pudo cargar la configuración'}</h3>
      <p style="color:#2A467A;margin-bottom:20px;">${API.escapeHTML(sinLogin ? '' : res.error)}</p>
      ${sinLogin ? '<a href="registro.html" class="btn-accion">Iniciar sesión</a>' : ''}</div>`;
    return;
  }

  const c = res.configuracion;
  texto.forEach(k => { if ($('conf-' + k)) $('conf-' + k).value = c[k] || ''; });
  $('conf-email').value = c.email || '';
  Object.keys(flags).forEach(id => { $(id).checked = !!c[flags[id]]; });

  const selPago = $('conf-metodo-pago');
  selPago.innerHTML = '';
  Object.entries(res.metodos_pago).forEach(([k, v]) => {
    const o = document.createElement('option'); o.value = k; o.textContent = v; selPago.appendChild(o);
  });
  selPago.value = c.metodo_pago_defecto;
  $('conf-tema').value = c.tema_visual;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = $('btn-guardar-config');
    const nueva = $('conf-pass-nueva').value;

    if (!$('conf-nombre').value.trim() || !$('conf-apellido').value.trim()) return API.mostrarToast('Nombre y apellido son obligatorios.', 'warning');
    if (nueva) {
      if (nueva.length < 8) return API.mostrarToast('La nueva contraseña debe tener al menos 8 caracteres.', 'warning');
      if (nueva !== $('conf-pass-confirm').value) return API.mostrarToast('Las contraseñas nuevas no coinciden.', 'warning');
      if (!$('conf-pass-actual').value) return API.mostrarToast('Ingresá tu contraseña actual para cambiarla.', 'warning');
    }

    const body = { tema_visual: $('conf-tema').value, metodo_pago_defecto: selPago.value };
    texto.forEach(k => { body[k] = $('conf-' + k).value.trim(); });
    Object.keys(flags).forEach(id => { body[flags[id]] = $(id).checked ? 1 : 0; });
    if (nueva) { body.pass_actual = $('conf-pass-actual').value; body.pass_nueva = nueva; }

    btn.disabled = true; btn.textContent = 'Guardando...';
    const r = await API.fetchAPI('PHP/api/configuracion.php', { method: 'POST', body });
    btn.disabled = false; btn.textContent = '💾 Guardar cambios';

    if (r.success) {
      ['conf-pass-actual', 'conf-pass-nueva', 'conf-pass-confirm'].forEach(id => { $(id).value = ''; });
      API.mostrarToast(r.mensaje, 'success');
      API.actualizarEstadoSesion();
    } else {
      API.mostrarToast(r.error || 'No se pudieron guardar los cambios.', 'error');
    }
  });

  const salir = $('btn-cerrar-sesion');
  if (salir) salir.addEventListener('click', (e) => { e.preventDefault(); API.cerrarSesion(); });
});
