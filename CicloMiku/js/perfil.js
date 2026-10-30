/**
 * CICLOMIKU - Perfil: ver y editar los datos guardados en MySQL
 */
document.addEventListener('DOMContentLoaded', async function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const $ = id => document.getElementById(id);
  const main = document.querySelector('main');
  const NO = 'Sin completar';

  const campos = ['nombre', 'apellido', 'dni', 'telefono', 'fecha_nacimiento', 'direccion', 'ciudad', 'codigo_postal', 'instrucciones_entrega', 'bici_actual_modelo'];
  let perfil = null;

  function fechaLarga(iso) {
    if (!iso) return NO;
    const m = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    const p = iso.split('-');
    return p.length === 3 ? `${Number(p[2])} de ${m[Number(p[1]) - 1]} de ${p[0]}` : iso;
  }

  function mostrar(p) {
    perfil = p;
    const nombreCompleto = (p.nombre + ' ' + (p.apellido || '')).trim();
    $('perfil-avatar').textContent = ((p.nombre[0] || '') + ((p.apellido || '')[0] || '')).toUpperCase() || 'CM';
    $('perfil-nombre-completo').textContent = nombreCompleto;
    $('perfil-contacto').textContent = p.email + ' | ' + (p.telefono || 'Sin teléfono');
    const rango = $('perfil-rango');
    rango.textContent = p.rango_socio || '';
    rango.style.display = p.rango_socio ? '' : 'none';

    $('v-nombre').textContent = nombreCompleto;
    $('v-dni').textContent = p.dni || NO;
    $('v-email').textContent = p.email;
    $('v-telefono').textContent = p.telefono || NO;
    $('v-fecha_nacimiento').textContent = fechaLarga(p.fecha_nacimiento);
    $('v-miembro').textContent = p.miembro_desde;
    $('v-direccion').textContent = p.direccion || NO;
    $('v-ciudad').textContent = p.ciudad || NO;
    $('v-codigo_postal').textContent = p.codigo_postal || NO;
    $('v-instrucciones_entrega').textContent = p.instrucciones_entrega || NO;
    $('v-bici_actual_modelo').textContent = p.bici_actual_modelo || NO;
    $('v-ultimo_service').textContent = p.ultimo_service || 'Sin services registrados';
  }

  function setEdicion(editando) {
    $('vista-perfil').style.display = editando ? 'none' : '';
    $('form-perfil').style.display = editando ? '' : 'none';
    $('btn-editar-perfil').style.display = editando ? 'none' : '';
    if (editando) campos.forEach(c => { $('f-' + c).value = perfil[c] || ''; });
  }

  const data = await API.fetchAPI('PHP/api/perfil.php');
  if (!data.success) {
    const sinLogin = data.requiere_login;
    main.innerHTML = `<div class="tarjeta-usuario text-center py-5">
      <div style="font-size:40px;margin-bottom:10px;">${sinLogin ? '👤' : '⚠️'}</div>
      <h3 style="color:#142E54;">${sinLogin ? 'Sesión no iniciada' : 'No se pudo cargar tu perfil'}</h3>
      <p style="color:#2A467A;margin-bottom:20px;">${API.escapeHTML(sinLogin ? 'Ingresá con tu cuenta para ver tu perfil.' : data.error)}</p>
      ${sinLogin ? '<a href="registro.html" class="btn-accion-primario">Iniciar sesión</a>' : ''}</div>`;
    return;
  }
  mostrar(data.perfil);

  $('btn-editar-perfil').addEventListener('click', () => setEdicion(true));
  $('btn-cancelar-perfil').addEventListener('click', () => setEdicion(false));

  $('form-perfil').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = $('btn-guardar-perfil');
    const body = {};
    campos.forEach(c => { body[c] = $('f-' + c).value.trim(); });
    if (!body.nombre || !body.apellido) return API.mostrarToast('Nombre y apellido son obligatorios.', 'warning');

    btn.disabled = true; btn.textContent = 'Guardando...';
    const r = await API.fetchAPI('PHP/api/perfil.php', { method: 'POST', body });
    btn.disabled = false; btn.textContent = '💾 Guardar cambios';
    if (r.success) {
      mostrar(r.perfil); setEdicion(false);
      API.mostrarToast(r.mensaje, 'success');
      API.actualizarEstadoSesion();
    } else {
      API.mostrarToast(r.error || 'No se pudieron guardar los cambios.', 'error');
    }
  });
});
