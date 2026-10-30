/**
 * CICLOMIKU - Historial de compras (pedidos) y turnos del taller, desde MySQL
 */
document.addEventListener('DOMContentLoaded', async function () {
  'use strict';
  const API = window.CicloMikuAPI;
  const esc = API.escapeHTML;
  const cont = document.getElementById('contenedor-historial');
  if (!cont) return;
  const botones = document.querySelectorAll('.pestanas-historial button');

  let items = [];
  let filtroActual = 'todos';

  const claseEstado = e => ({ entregado: 'estado-entregado', completado: 'estado-completado', cancelado: 'estado-cancelado' }[e] || 'estado-taller');

  async function cargar() {
    cont.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" role="status"></div></div>';
    const [rp, rt] = await Promise.all([API.fetchAPI('PHP/api/pedidos.php'), API.fetchAPI('PHP/api/turnos.php')]);

    if (rp.requiere_login) {
      botones.forEach(b => b.style.display = 'none');
      cont.innerHTML = `<div class="text-center py-5" style="background:#faf8f3;border:2px dashed #95C1F5;border-radius:8px;padding:40px;">
        <div style="font-size:40px;">📋</div><h4 style="color:#142E54;">Iniciá sesión para ver tu historial</h4>
        <a href="registro.html" class="btn-accion">Iniciar sesión</a></div>`;
      return;
    }
    if (!rp.success) { cont.innerHTML = `<div class="alert alert-danger">${esc(rp.error)}</div>`; return; }

    items = [];
    rp.pedidos.forEach(p => items.push({ tipo: 'compras', ts: new Date(p.creado_en.replace(' ', 'T')).getTime(), p }));
    if (rt.success) rt.turnos.forEach(t => items.push({ tipo: 'taller', ts: new Date(t.creado_en.replace(' ', 'T')).getTime(), t }));
    items.sort((a, b) => b.ts - a.ts);

    const nc = items.filter(i => i.tipo === 'compras').length, nt = items.length - nc;
    if (botones[0]) botones[0].textContent = `Todos (${items.length})`;
    if (botones[1]) botones[1].textContent = `📦 Compras online (${nc})`;
    if (botones[2]) botones[2].textContent = `🔧 Turnos de taller (${nt})`;
    render();
  }

  function renderPedido(p) {
    const det = p.detalles.map(d => `
      <div class="d-flex flex-wrap align-items-center gap-3 my-2">
        ${d.imagen ? `<img src="${esc(d.imagen)}" alt="${esc(d.nombre_producto)}" style="width:60px;height:60px;object-fit:cover;border-radius:6px;">` : ''}
        <div class="flex-grow-1">
          <h4 style="font-size:15px;color:#142E54;margin-bottom:2px;font-weight:bold;">${esc(d.nombre_producto)}</h4>
          <p style="font-size:13px;color:#718096;margin-bottom:0;">Cantidad: ${d.cantidad} | Precio unitario: ${esc(d.precio_formateado)}</p>
        </div>
        <div style="font-size:16px;font-weight:bold;color:#142E54;">${esc(d.subtotal_formateado)}</div>
      </div>`).join('');
    return `
      <div class="cabecera-registro">
        <div><span class="id-registro">📦 Pedido ${esc(p.numero_pedido)}</span><div class="fecha-registro">Registrado el ${esc(p.fecha_formateada)}</div></div>
        <div><span class="estado-badge ${claseEstado(p.estado)}">${esc(p.estado_texto)}</span></div>
      </div>${det}
      <div class="d-flex justify-content-between align-items-center mt-3 pt-2 border-top flex-wrap gap-2">
        <div><strong>Total:</strong> <span style="font-size:18px;color:#142E54;font-weight:bold;">${esc(p.total_formateado)}</span>
          <div class="small text-muted">Pago: ${esc(p.metodo_pago || 'A coordinar')} · Envío: ${esc(p.direccion_envio || 'A coordinar')}</div></div>
        <a href="../index.html" class="btn-accion">🔁 Comprar más</a>
      </div>`;
  }

  function renderTurno(t) {
    return `
      <div class="cabecera-registro">
        <div><span class="id-registro">🔧 Turno ${esc(t.codigo_turno)}</span><div class="fecha-registro">Para el ${esc(t.fecha_formateada)} a las ${esc(t.horario_turno)} hs</div></div>
        <div><span class="estado-badge ${claseEstado(t.estado)}">${esc(t.estado_texto)}</span></div>
      </div>
      <div class="d-flex flex-wrap align-items-center gap-3 my-2">
        <div style="font-size:32px;background:#eaf2fd;width:60px;height:60px;display:flex;align-items:center;justify-content:center;border-radius:6px;">🚲</div>
        <div class="flex-grow-1">
          <h4 style="font-size:15px;color:#142E54;margin-bottom:2px;font-weight:bold;">${esc(t.marca_bici)} ${esc(t.modelo_bici)}</h4>
          <p style="font-size:13px;color:#718096;margin-bottom:0;">${esc(t.servicio)}${t.mecanico_asignado ? ' | Mecánico: ' + esc(t.mecanico_asignado) : ''}</p>
        </div>
        <div style="font-size:16px;font-weight:bold;color:#142E54;">${t.presupuesto_formateado ? esc(t.presupuesto_formateado) + '<div class="small text-muted" style="font-weight:normal;">presupuesto base</div>' : ''}</div>
      </div>`;
  }

  function render() {
    const lista = items.filter(i => filtroActual === 'todos' || i.tipo === filtroActual);
    if (!lista.length) {
      cont.innerHTML = `<div class="text-center py-5" style="background:#faf8f3;border:2px dashed #95C1F5;border-radius:8px;padding:40px;">
        <div style="font-size:40px;">📋</div><h4 style="color:#142E54;">No hay registros</h4><p class="text-muted">Todavía no tenés movimientos en esta categoría.</p></div>`;
      return;
    }
    cont.innerHTML = '';
    lista.forEach(i => {
      const card = document.createElement('div');
      card.className = 'tarjeta-registro-historial item-tipo-' + i.tipo;
      card.innerHTML = i.tipo === 'compras' ? renderPedido(i.p) : renderTurno(i.t);
      cont.appendChild(card);
    });
  }

  window.filtrarHistorial = function (filtro, boton) {
    filtroActual = filtro;
    botones.forEach(b => b.classList.remove('activo'));
    if (boton) boton.classList.add('activo');
    render();
  };

  cargar();
});
