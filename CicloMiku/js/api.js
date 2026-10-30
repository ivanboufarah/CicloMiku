/**
 * ==============================================================================
 * CICLOMIKU - CLIENTE API CENTRAL (fetch + CSRF + sesión + menú de usuario)
 * Cargar SIEMPRE antes que los demás scripts de js/.
 * ==============================================================================
 */
(function () {
  'use strict';

  // Ruta hacia la raíz del sitio según la carpeta de la página actual
  const esSubdirectorio = window.location.pathname.includes('/menu_usuario/');
  const basePath = esSubdirectorio ? '../' : './';

  let csrfToken = null;
  let estadoUsuario = null;
  let estadoPromesa = null;

  function escapeHTML(valor) {
    return String(valor == null ? '' : valor)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  /** Respuesta de error uniforme para fallos de red o respuestas que no son JSON */
  function errorRed(status, texto) {
    let msg = 'No se pudo conectar con el servidor. Verificá que Apache y MySQL estén iniciados en XAMPP.';
    if (status) {
      msg = 'El servidor respondió con un error inesperado (HTTP ' + status + '). ';
      if (/<b>(Parse|Fatal) error|Warning:|Notice:/i.test(texto || '')) {
        msg += 'Hay un error de PHP: revisá C:\\xampp\\apache\\logs\\error.log.';
      } else if (status === 404) {
        msg = 'No se encontró el archivo PHP solicitado (HTTP 404). Verificá que el proyecto esté en C:\\xampp\\htdocs\\CicloMiku y abras el sitio desde http://localhost/CicloMiku/.';
      }
    }
    return { success: false, error: msg, error_red: true };
  }

  async function peticion(endpoint, opciones) {
    const url = /^https?:/.test(endpoint) ? endpoint : basePath + endpoint;
    const metodo = (opciones.method || 'GET').toUpperCase();
    const headers = Object.assign({ 'Accept': 'application/json' }, opciones.headers || {});
    let body = opciones.body;

    if (metodo !== 'GET' && metodo !== 'HEAD') {
      if (csrfToken) headers['X-CSRF-Token'] = csrfToken;
      if (body && typeof body === 'object' && !(body instanceof FormData)) {
        headers['Content-Type'] = 'application/json';
        body = JSON.stringify(Object.assign({}, body, csrfToken ? { csrf_token: csrfToken } : {}));
      }
    }

    let resp, texto;
    try {
      resp = await fetch(url, { method: metodo, headers, body, credentials: 'same-origin', cache: 'no-store' });
      texto = await resp.text();
    } catch (e) {
      console.warn('[CicloMiku] error de red en', url, e);
      return errorRed(0);
    }

    let data;
    try { data = JSON.parse(texto); }
    catch (e) {
      console.warn('[CicloMiku] respuesta no JSON de', url, resp.status, texto.slice(0, 300));
      return errorRed(resp.status, texto);
    }
    if (data && data.csrf_token) csrfToken = data.csrf_token;
    return data;
  }

  /** Garantiza tener el token CSRF antes de cualquier petición que modifique datos */
  async function asegurarCSRF() {
    if (csrfToken) return;
    await actualizarEstadoSesion();
  }

  async function fetchAPI(endpoint, opciones = {}) {
    const metodo = (opciones.method || 'GET').toUpperCase();
    if (metodo !== 'GET' && !csrfToken && !/estado\.php/.test(endpoint)) await asegurarCSRF();
    let data = await peticion(endpoint, opciones);
    // Token vencido (sesión nueva): se renueva y se reintenta una vez
    if (data && data.success === false && !data.error_red && /Token de seguridad/.test(data.error || '') && metodo !== 'GET') {
      csrfToken = null;
      await actualizarEstadoSesion();
      data = await peticion(endpoint, opciones);
    }
    return data;
  }

  function actualizarEstadoSesion() {
    estadoPromesa = (async () => {
      const res = await peticion('PHP/auth/estado.php', {});
      if (res && res.success) {
        estadoUsuario = res;
        if (res.csrf_token) csrfToken = res.csrf_token;
        pintarMenuUsuario(res);
      } else if (res && res.error) {
        console.warn('[CicloMiku] estado de sesión:', res.error);
      }
      return res;
    })();
    return estadoPromesa;
  }

  function pintarMenuUsuario(res) {
    const menu = document.getElementById('menu-usuario');
    if (menu) {
      const enlaces = menu.querySelectorAll('a');
      const enlaceSesion = enlaces[enlaces.length - 1];
      if (enlaceSesion) {
        if (res.autenticado) {
          enlaceSesion.textContent = '🚪 Cerrar sesión (' + (res.usuario.nombre || 'Mi cuenta') + ')';
          enlaceSesion.setAttribute('href', '#');
          enlaceSesion.onclick = function (e) { e.preventDefault(); cerrarSesion(); };
        } else {
          enlaceSesion.textContent = '🚪 Iniciar sesión';
          enlaceSesion.setAttribute('href', esSubdirectorio ? 'registro.html' : 'menu_usuario/registro.html');
          enlaceSesion.onclick = null;
        }
      }
    }

    const btnUsuario = document.getElementById('btn-usuario');
    if (btnUsuario) {
      let badge = document.getElementById('badge-notif-usuario');
      const n = res.total_notificaciones_sin_leer || 0;
      if (n > 0) {
        if (!badge) {
          badge = document.createElement('span');
          badge.id = 'badge-notif-usuario';
          badge.className = 'badge rounded-pill bg-danger';
          badge.style.cssText = 'position:absolute;top:-4px;right:-4px;font-size:10px;';
          btnUsuario.parentElement.style.position = 'relative';
          btnUsuario.parentElement.appendChild(badge);
        }
        badge.textContent = n;
        badge.style.display = 'inline-block';
      } else if (badge) {
        badge.style.display = 'none';
      }
    }

    const enlaceCarrito = document.querySelector('#menu-usuario a[href*="carrito.html"]');
    if (enlaceCarrito) {
      let cb = enlaceCarrito.querySelector('.cart-counter-badge');
      const n = res.total_items_carrito || 0;
      if (n > 0) {
        if (!cb) {
          cb = document.createElement('span');
          cb.className = 'cart-counter-badge badge bg-warning text-dark ms-1';
          enlaceCarrito.appendChild(cb);
        }
        cb.textContent = n;
      } else if (cb) {
        cb.remove();
      }
    }
  }

  async function cerrarSesion() {
    if (!confirm('¿Querés cerrar tu sesión en CicloMiku?')) return;
    const r = await fetchAPI('PHP/auth/logout.php', { method: 'POST' });
    if (r && r.success) {
      window.location.href = esSubdirectorio ? '../index.html' : 'index.html';
    } else {
      mostrarToast((r && r.error) || 'No se pudo cerrar la sesión.', 'error');
    }
  }

  function mostrarToast(mensaje, tipo = 'success') {
    let cont = document.getElementById('toast-container-ciclomiku');
    if (!cont) {
      cont = document.createElement('div');
      cont.id = 'toast-container-ciclomiku';
      cont.setAttribute('role', 'status');
      cont.setAttribute('aria-live', 'polite');
      cont.style.cssText = 'position:fixed;bottom:25px;right:25px;z-index:99999;display:flex;flex-direction:column;gap:10px;max-width:min(380px,calc(100vw - 50px));';
      document.body.appendChild(cont);
    }
    const colores = { success: '#142E54', warning: '#b7791f', error: '#c53030' };
    const iconos = { success: '✓', warning: '⚠️', error: '✕' };
    const t = document.createElement('div');
    t.style.cssText = 'background:' + (colores[tipo] || colores.success) + ';color:#F2ECDC;padding:12px 18px;border-radius:8px;border:2px solid #95C1F5;box-shadow:0 4px 15px rgba(0,0,0,.25);font-size:14px;font-weight:bold;display:flex;align-items:center;gap:10px;';
    const i = document.createElement('span'); i.textContent = iconos[tipo] || '';
    const m = document.createElement('span'); m.textContent = mensaje;
    t.appendChild(i); t.appendChild(m);
    cont.appendChild(t);
    setTimeout(() => { t.style.transition = 'opacity .4s'; t.style.opacity = '0'; setTimeout(() => t.remove(), 400); }, 3500);
  }

  /** Agregar al carrito: lo guarda en MySQL; solo muestra éxito si el servidor lo confirma */
  async function agregarAlCarrito(productoId, nombreProducto) {
    const res = await fetchAPI('PHP/api/carrito.php', {
      method: 'POST',
      body: { accion: 'agregar', producto_id: Number(productoId), cantidad: 1 }
    });
    if (res && res.success) {
      mostrarToast((nombreProducto || 'Producto') + ' agregado al carrito.', 'success');
      actualizarEstadoSesion();
    } else {
      mostrarToast((res && res.error) || 'No se pudo agregar al carrito.', 'error');
    }
    return res;
  }

  window.CicloMikuAPI = {
    fetchAPI, escapeHTML, mostrarToast, actualizarEstadoSesion, cerrarSesion, agregarAlCarrito, basePath,
    obtenerTokenCSRF: () => csrfToken,
    obtenerEstadoUsuario: () => estadoUsuario,
    estaAutenticado: () => !!(estadoUsuario && estadoUsuario.autenticado),
    /** Espera a que el estado de sesión esté cargado (útil para decidir si hay login) */
    estadoListo: () => estadoPromesa || actualizarEstadoSesion()
  };
  window.agregarAlCarrito = agregarAlCarrito;   // compatibilidad con onclick antiguos

  document.addEventListener('DOMContentLoaded', () => {
    actualizarEstadoSesion();

    // Botones "Agregar al Carrito" escritos en el HTML (usan data-producto-id y data-nombre)
    document.addEventListener('click', (e) => {
      const btn = e.target.closest('.btn-agregar[data-producto-id]');
      if (!btn) return;
      e.preventDefault();
      btn.disabled = true;
      agregarAlCarrito(btn.dataset.productoId, btn.dataset.nombre).finally(() => { btn.disabled = false; });
    });
  });
})();
