/**
 * CICLOMIKU - Favoritos
 * Los botones de corazón están escritos en el HTML (index.html y accesoriomikus.html).
 * Este script SOLO maneja sus eventos, su estado visual y la comunicación con PHP/MySQL.
 */
document.addEventListener('DOMContentLoaded', function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const esc = API.escapeHTML;

  const grillaFavs = document.getElementById('grilla-favs');
  const contadorFavs = document.getElementById('contador-favs');

  function pintarCorazon(btn, activo) {
    const icono = btn.querySelector('span') || btn;
    const nombre = btn.getAttribute('data-nombre') || '';
    btn.classList.toggle('activo', activo);
    btn.setAttribute('aria-pressed', activo ? 'true' : 'false');
    btn.setAttribute('title', activo ? 'Quitar de favoritos' : 'Agregar a favoritos');
    if (!btn.dataset.labelOriginal) btn.dataset.labelOriginal = btn.getAttribute('aria-label') || '';
    icono.textContent = activo ? '♥' : '♡';
  }

  /** Marca los corazones según los favoritos reales guardados en la base de datos */
  async function sincronizarCorazones() {
    const botones = document.querySelectorAll('.btn-favorito');
    if (!botones.length) return;
    const estado = await API.estadoListo();
    if (!estado || !estado.autenticado) { botones.forEach(b => pintarCorazon(b, false)); return; }

    const res = await API.fetchAPI('PHP/api/favoritos.php');
    if (res && res.success) {
      const ids = new Set(res.favoritos.map(f => Number(f.producto_id)));
      botones.forEach(b => pintarCorazon(b, ids.has(Number(b.dataset.productoId))));
    } else if (res && res.error) {
      console.warn('[CicloMiku] favoritos:', res.error);
    }
  }

  document.addEventListener('click', async function (e) {
    const btn = e.target.closest('.btn-favorito');
    if (!btn) return;
    e.preventDefault();
    e.stopPropagation();

    const pid = Number(btn.dataset.productoId);
    if (!pid) { console.error('Corazón sin data-producto-id válido', btn); return; }
    if (btn.disabled) return;

    const estado = await API.estadoListo();
    if (!estado || !estado.autenticado) {
      API.mostrarToast('Iniciá sesión para guardar productos en favoritos.', 'warning');
      const ruta = window.location.pathname.includes('/menu_usuario/') ? 'registro.html' : 'menu_usuario/registro.html';
      setTimeout(() => { if (confirm('Necesitás iniciar sesión para guardar favoritos. ¿Ir a Iniciar sesión ahora?')) window.location.href = ruta; }, 250);
      return;
    }

    btn.disabled = true;
    const deseado = btn.getAttribute('aria-pressed') !== 'true';
    const res = await API.fetchAPI('PHP/api/favoritos.php', { method: 'POST', body: { producto_id: pid, activo: deseado } });
    btn.disabled = false;

    if (res && res.success) {
      pintarCorazon(btn, !!res.activo);
      API.mostrarToast(res.mensaje, res.activo ? 'success' : 'warning');
      API.actualizarEstadoSesion();
    } else {
      API.mostrarToast((res && res.error) || 'No se pudo actualizar favoritos.', 'error');
    }
  });

  // ---------------------------- menu_usuario/favoritos.html ----------------------------
  function vacio(icono, titulo, texto, enlace) {
    return `<div class="text-center py-5" style="grid-column:1/-1;background:#faf8f3;border:2px dashed #95C1F5;border-radius:8px;padding:40px;">
      <div style="font-size:40px;margin-bottom:10px;">${icono}</div>
      <h3 style="color:#142E54;margin-bottom:8px;">${titulo}</h3>
      <p style="color:#2A467A;margin-bottom:20px;">${texto}</p>${enlace || ''}</div>`;
  }

  async function cargarPanel() {
    if (!grillaFavs) return;
    grillaFavs.innerHTML = '<div class="text-center py-5" style="grid-column:1/-1;"><div class="spinner-border text-primary" role="status"></div><p class="mt-2 text-muted">Cargando tus favoritos...</p></div>';
    const data = await API.fetchAPI('PHP/api/favoritos.php');

    if (!data.success) {
      if (data.requiere_login) {
        grillaFavs.innerHTML = vacio('🔒', 'Iniciá sesión para ver tus favoritos', 'Guardá las bicicletas y accesorios que más te gustan en tu cuenta.', '<a href="registro.html" class="btn-accion">Iniciar sesión / Registrarse</a>');
      } else {
        grillaFavs.innerHTML = `<div class="alert alert-danger" style="grid-column:1/-1;">${esc(data.error || 'Error al cargar tus favoritos.')}</div>`;
      }
      if (contadorFavs) contadorFavs.textContent = '0';
      return;
    }

    const favs = data.favoritos || [];
    if (contadorFavs) contadorFavs.textContent = favs.length;
    if (!favs.length) {
      grillaFavs.innerHTML = vacio('🤍', 'Aún no tenés productos guardados', 'Tocá el corazón en los productos que te gusten.', '<a href="../index.html" class="btn-accion">Explorar bicicletas</a>');
      return;
    }

    grillaFavs.innerHTML = '';
    favs.forEach(f => {
      const card = document.createElement('div');
      card.className = 'tarjeta-favorito';
      card.id = 'fav-' + f.producto_id;
      card.innerHTML = `
        <button type="button" class="btn-quitar-fav" title="Quitar de favoritos" aria-label="Quitar ${esc(f.nombre)} de favoritos" data-quitar="${Number(f.producto_id)}">✕</button>
        <img src="${esc(f.imagen)}" alt="${esc(f.nombre)}">
        <span class="badge" style="display:inline-block;font-size:11px;font-weight:bold;color:#142E54;background-color:#eaf2fd;padding:3px 8px;border-radius:4px;margin-bottom:6px;align-self:flex-start;">${esc(f.subcategoria || f.categoria)}</span>
        <h4 style="font-size:16px;color:#142E54;margin-bottom:6px;font-weight:bold;">${esc(f.nombre)}</h4>
        <p style="font-size:13px;color:#2A467A;margin-bottom:8px;">${esc(f.descripcion || '')}</p>
        <div style="font-size:18px;font-weight:bold;color:#142E54;margin-bottom:10px;">${esc(f.precio_formateado)}</div>
        <button type="button" class="btn-accion w-100" data-mover="${Number(f.producto_id)}" data-nombre="${esc(f.nombre)}">🛒 Mover al carrito</button>`;
      grillaFavs.appendChild(card);
    });
  }

  if (grillaFavs) {
    grillaFavs.addEventListener('click', async (e) => {
      const q = e.target.closest('[data-quitar]');
      const m = e.target.closest('[data-mover]');
      if (q) {
        const r = await API.fetchAPI('PHP/api/favoritos.php', { method: 'POST', body: { producto_id: Number(q.dataset.quitar), activo: false } });
        if (r.success) { API.mostrarToast('Producto quitado de tus favoritos.', 'warning'); cargarPanel(); API.actualizarEstadoSesion(); }
        else API.mostrarToast(r.error || 'No se pudo quitar de favoritos.', 'error');
      } else if (m) {
        const r = await API.agregarAlCarrito(m.dataset.mover, m.dataset.nombre);
        if (r && r.success) {
          const q2 = await API.fetchAPI('PHP/api/favoritos.php', { method: 'POST', body: { producto_id: Number(m.dataset.mover), activo: false } });
          if (q2.success) cargarPanel();
        }
      }
    });
    cargarPanel();
  }

  sincronizarCorazones();
});
