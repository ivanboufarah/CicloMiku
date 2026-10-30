/**
 * CICLOMIKU - Carrito (datos reales desde MySQL) y registro del pedido
 */
document.addEventListener('DOMContentLoaded', function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const esc = API.escapeHTML;

  const cont = document.getElementById('contenedor-items-carrito');
  const elSub = document.getElementById('resumen-subtotal');
  const elTotal = document.getElementById('resumen-total');
  const btnComprar = document.getElementById('btn-finalizar-compra');
  if (!cont) return;

  let hayItems = false;

  function pintarResumen(r) {
    if (elSub) elSub.textContent = r.subtotal_formateado || '$0';
    if (elTotal) elTotal.textContent = r.total_formateado || '$0';
  }

  async function cargar() {
    cont.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" role="status"></div><p class="mt-2 text-muted">Cargando tu carrito...</p></div>';
    const data = await API.fetchAPI('PHP/api/carrito.php');
    if (!data.success) {
      cont.innerHTML = `<div class="alert alert-danger">${esc(data.error || 'No se pudo cargar el carrito.')}</div>`;
      pintarResumen({}); hayItems = false; if (btnComprar) btnComprar.disabled = true;
      return;
    }
    render(data.items || [], data.resumen || {});
  }

  function render(items, resumen) {
    hayItems = items.length > 0;
    if (btnComprar) btnComprar.disabled = !hayItems || !!resumen.hay_sin_stock;
    pintarResumen(resumen);

    if (!hayItems) {
      cont.innerHTML = `<div style="text-align:center;padding:40px;background:#faf8f3;border:2px dashed #95C1F5;border-radius:8px;">
        <div style="font-size:40px;margin-bottom:10px;">🛒</div>
        <h3 style="color:#142E54;margin-bottom:8px;">Tu carrito está vacío</h3>
        <p style="color:#2A467A;margin-bottom:15px;">Todavía no agregaste productos.</p>
        <a href="../index.html" class="btn-accion">Ir al catálogo de bicicletas</a></div>`;
      return;
    }

    cont.innerHTML = '';
    items.forEach(it => {
      const sub = [it.color ? 'Color: ' + esc(it.color) : '', it.talle ? 'Talle: ' + esc(it.talle) : '',
                   it.disponible ? '' : '<strong style="color:#c53030;">Sin stock: quitalo para poder comprar</strong>']
                  .filter(Boolean).join(' | ');
      const el = document.createElement('div');
      el.className = 'item-carrito';
      el.innerHTML = `
        <img src="${esc(it.imagen)}" alt="${esc(it.nombre)}">
        <div class="detalles-item">
          <h4>${esc(it.nombre)}</h4>
          <p>${esc(it.precio_formateado)} c/u${sub ? ' | ' + sub : ''}</p>
          <div class="control-cantidad">
            <button type="button" class="btn-qty" data-accion="menos" aria-label="Quitar una unidad">-</button>
            <span class="num-qty">${Number(it.cantidad)}</span>
            <button type="button" class="btn-qty" data-accion="mas" aria-label="Agregar una unidad">+</button>
          </div>
          <button type="button" class="btn-eliminar-item" data-accion="eliminar">Eliminar</button>
        </div>
        <div class="precio-item">${esc(it.subtotal_formateado)}</div>`;
      el.dataset.detalle = it.detalle_id;
      el.dataset.cantidad = it.cantidad;
      cont.appendChild(el);
    });
    const volver = document.createElement('div');
    volver.className = 'mt-3';
    volver.innerHTML = '<a href="../index.html" class="btn-accion btn-secundario">← Agregar más productos</a>';
    cont.appendChild(volver);
  }

  cont.addEventListener('click', async (e) => {
    const b = e.target.closest('[data-accion]');
    const item = e.target.closest('.item-carrito');
    if (!b || !item) return;
    const detalle = Number(item.dataset.detalle), cant = Number(item.dataset.cantidad);
    let body = { detalle_id: detalle };

    if (b.dataset.accion === 'eliminar' || (b.dataset.accion === 'menos' && cant <= 1)) {
      if (b.dataset.accion === 'menos' && !confirm('¿Querés quitar este producto del carrito?')) return;
      body.accion = 'eliminar';
    } else {
      body.accion = 'modificar';
      body.cantidad = cant + (b.dataset.accion === 'mas' ? 1 : -1);
    }
    b.disabled = true;
    const r = await API.fetchAPI('PHP/api/carrito.php', { method: 'POST', body });
    if (r.success) { await cargar(); API.actualizarEstadoSesion(); }
    else { b.disabled = false; API.mostrarToast(r.error || 'No se pudo actualizar el carrito.', 'error'); }
  });

  window.confirmarCompra = async function () {
    const estado = await API.estadoListo();
    if (!estado || !estado.autenticado) {
      if (confirm('Para registrar tu pedido tenés que iniciar sesión. ¿Ir a Iniciar sesión?')) window.location.href = 'registro.html';
      return;
    }
    if (!hayItems) return;
    if (!confirm('Se va a registrar tu pedido. CicloMiku se comunicará con vos para coordinar el pago y la entrega (no se cobra nada en este sitio). ¿Continuar?')) return;

    btnComprar.disabled = true;
    const r = await API.fetchAPI('PHP/api/pedidos.php', { method: 'POST', body: {} });
    if (r.success) {
      API.mostrarToast(r.mensaje, 'success');
      API.actualizarEstadoSesion();
      setTimeout(() => { window.location.href = 'historial.html'; }, 1800);
    } else {
      btnComprar.disabled = false;
      API.mostrarToast(r.error || 'No se pudo registrar el pedido.', 'error');
      cargar();
    }
  };

  cargar();
});
