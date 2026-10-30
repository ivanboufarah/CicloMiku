/**
 * ==============================================================================
 * CICLOMIKU - FILTRADO INTERACTIVO DEL CATÁLOGO HTML
 * ==============================================================================
 * Controla el filtrado en tiempo real de las tarjetas escritas directamente en el
 * HTML de index.html y accesoriomikus.html.
 * CONSERVA TODAS LAS TARJETAS Y BOTONES DE FAVORITOS EN EL DOM sin destruirlos.
 */

document.addEventListener('DOMContentLoaded', function () {
  'use strict';

  const contenedorProductos = document.getElementById('productos');
  if (!contenedorProductos) return;

  const formFiltros = document.querySelector('#filtros form');
  const sliderPrecio = document.getElementById('precio');
  const labelPrecioMax = document.querySelector('.filtro-precio label');

  // Obtener todas las tarjetas de producto existentes en el HTML
  const tarjetas = Array.from(contenedorProductos.querySelectorAll('.producto-card, .bici, .accesorio'));

  /**
   * Actualiza la etiqueta visible con el valor actual del deslizador
   */
  function actualizarEtiquetaPrecio() {
    if (sliderPrecio && labelPrecioMax) {
      const valor = Number(sliderPrecio.value);
      labelPrecioMax.textContent = `Precio máximo: $${valor.toLocaleString('es-AR')}`;
    }
  }

  /**
   * Aplica los filtros sobre las tarjetas HTML sin reconstruirlas ni eliminarlas del DOM.
   */
  function filtrarTarjetas() {
    if (!formFiltros && !sliderPrecio) return;

    // Obtener valores seleccionados
    const gamasSeleccionadas = Array.from(formFiltros.querySelectorAll('input[name="gama"]:checked')).map(cb => cb.value.toLowerCase());
    const modelosSeleccionados = Array.from(formFiltros.querySelectorAll('input[name="modelo"]:checked')).map(cb => cb.value.toLowerCase());
    const categoriasSeleccionadas = Array.from(formFiltros.querySelectorAll('input[name="categoria"]:checked')).map(cb => cb.value.toLowerCase());
    const marcasSeleccionadas = Array.from(formFiltros.querySelectorAll('input[name="marca"]:checked')).map(cb => cb.value.toLowerCase());
    const precioMax = sliderPrecio ? Number(sliderPrecio.value) : Infinity;

    let visibles = 0;

    tarjetas.forEach(card => {
      const cardGama = (card.getAttribute('data-gama') || '').toLowerCase();
      const cardModelo = (card.getAttribute('data-modelo') || '').toLowerCase();
      const cardCategoria = (card.getAttribute('data-categoria') || '').toLowerCase();
      const cardMarca = (card.getAttribute('data-marca') || '').toLowerCase();
      const cardPrecio = Number(card.getAttribute('data-precio') || 0);

      // Evaluación de condiciones
      const cumpleGama = gamasSeleccionadas.length === 0 || gamasSeleccionadas.includes(cardGama);
      const cumpleModelo = modelosSeleccionados.length === 0 || modelosSeleccionados.includes(cardModelo);
      const cumpleCategoria = categoriasSeleccionadas.length === 0 || categoriasSeleccionadas.includes(cardCategoria) || categoriasSeleccionadas.some(cat => cardCategoria.includes(cat));
      const cumpleMarca = marcasSeleccionadas.length === 0 || marcasSeleccionadas.includes(cardMarca);
      const cumplePrecio = isNaN(precioMax) || cardPrecio <= precioMax;

      if (cumpleGama && cumpleModelo && cumpleCategoria && cumpleMarca && cumplePrecio) {
        card.style.display = '';
        visibles++;
      } else {
        card.style.display = 'none';
      }
    });

    // Mensaje de sin resultados si ninguna tarjeta coincide
    let avisoVacio = document.getElementById('aviso-catalogo-vacio');
    if (visibles === 0) {
      if (!avisoVacio) {
        avisoVacio = document.createElement('div');
        avisoVacio.id = 'aviso-catalogo-vacio';
        avisoVacio.className = 'col-12 text-center py-5';
        avisoVacio.style.gridColumn = '1 / -1';
        avisoVacio.innerHTML = `
          <div style="background-color: #faf8f3; border: 2px dashed #95C1F5; border-radius: 8px; padding: 35px;">
            <div style="font-size: 36px; margin-bottom: 10px;">🔍</div>
            <h4 style="color: #142E54;">No se encontraron productos con estos filtros</h4>
            <p style="color: #2A467A; font-size: 14px; margin-bottom: 15px;">Probá ajustando el rango de precio o seleccionando otras categorías.</p>
            <button type="button" class="btn-aplicar" style="max-width: 220px; margin: 0 auto;" id="btn-restablecer-filtros">Restablecer Filtros</button>
          </div>
        `;
        contenedorProductos.appendChild(avisoVacio);

        const btnRestablecer = avisoVacio.querySelector('#btn-restablecer-filtros');
        if (btnRestablecer) {
          btnRestablecer.addEventListener('click', () => {
            if (formFiltros) {
              formFiltros.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.checked = true);
            }
            if (sliderPrecio) {
              sliderPrecio.value = sliderPrecio.max;
            }
            actualizarEtiquetaPrecio();
            filtrarTarjetas();
          });
        }
      }
      avisoVacio.style.display = 'block';
    } else if (avisoVacio) {
      avisoVacio.style.display = 'none';
    }
  }

  // Eventos de interactividad en filtros
  if (sliderPrecio) {
    sliderPrecio.addEventListener('input', () => {
      actualizarEtiquetaPrecio();
      filtrarTarjetas();
    });
  }

  if (formFiltros) {
    formFiltros.addEventListener('change', filtrarTarjetas);
    formFiltros.addEventListener('submit', (e) => {
      e.preventDefault();
      filtrarTarjetas();
    });
  }

  // Inicialización de etiqueta y filtros iniciales
  actualizarEtiquetaPrecio();
});
