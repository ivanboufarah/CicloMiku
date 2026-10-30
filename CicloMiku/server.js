import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

// Enable JSON and URL-encoded body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ==============================================================================
// BASE DE DATOS EN MEMORIA PARA PREVIEW EN AI STUDIO (IDÉNTICA A ciclo_miku.sql)
// ==============================================================================

const db = {
  usuarios: [
    {
      id: 1,
      nombre: 'Ivan',
      apellido: 'Boufarah',
      email: 'ivanboufarah@gmail.com',
      password: 'mipassword123',
      telefono: '+54 9 299 123-4567',
      dni: '42.859.102',
      fecha_nacimiento: '14 de Mayo de 1999',
      direccion: 'Av. del Libertador 4580, Piso 4 Depto B',
      ciudad: 'CABA (Buenos Aires)',
      codigo_postal: 'C1426BWP',
      instrucciones_entrega: 'Tocar timbre en portería, dejar con encargado si no estoy.',
      bici_actual_modelo: 'Specialized Demo 7 - Rodado 27.5',
      ultimo_service: '15 de Noviembre 2024 (Taller CicloMiku)',
      rango_socio: '⭐ Socio CicloClub Oro (1.450 puntos acumulados)',
      rol: 'cliente',
      creado_en: '2024-01-15 10:00:00'
    }
  ],
  productos: [
    {
      id: 1,
      nombre: 'Specialized Demo 7',
      descripcion: 'Cuadro reforzado de aluminio, suspensión Fox 180mm y frenos hidráulicos de 4 pistones.',
      categoria: 'bicicleta',
      subcategoria: 'MTB / Descenso',
      marca: 'specialized',
      gama: 'alta',
      precio: 450000.00,
      cuotas_texto: '12 cuotas fijas de $37.500',
      stock: 5,
      imagen: 'https://assets.specialized.com/i/specialized/5719?$scom-pdp-product-image-xl$&fmt=webp',
      activo: 1
    },
    {
      id: 2,
      nombre: 'Giant Talon 1 29er',
      descripcion: 'Rodado 29, transmisión Shimano Deore 1x10 y horquilla con bloqueo hidráulico.',
      categoria: 'bicicleta',
      subcategoria: 'Mountain Bike',
      marca: 'giant',
      gama: 'media',
      precio: 315000.00,
      cuotas_texto: '6 cuotas sin interés de $52.500',
      stock: 8,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQR-5w0M_8YYLQM3LWM8Lv_PP__TH6e2U1iiqrWT2UnzQ&s=10',
      activo: 1
    },
    {
      id: 3,
      nombre: 'Specialized Allez Sprint',
      descripcion: 'Bicicleta de ruta aerodinámica, grupo Shimano 105 2x11 y horquilla de carbono.',
      categoria: 'bicicleta',
      subcategoria: 'Ruta / Carrera',
      marca: 'specialized',
      gama: 'alta',
      precio: 490000.00,
      cuotas_texto: '12 cuotas fijas de $40.833',
      stock: 4,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxAWO8qBMbtB16eGTt7z0RXuIhhrfMB3xhCKvkqu-IZQ&s=10',
      activo: 1
    },
    {
      id: 4,
      nombre: 'Trek Marlin 7 Gen 3',
      descripcion: 'Geometría moderna, frenos a disco hidráulicos Tektro y cubiertas Bontrager.',
      categoria: 'bicicleta',
      subcategoria: 'MTB / Trail',
      marca: 'trek',
      gama: 'media',
      precio: 280000.00,
      cuotas_texto: '12 cuotas fijas de $23.333',
      stock: 12,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ16NyCSLKyWKzg27YN0Y8yfJ8xo66hy4GUYklaumhMk3l9SO69SUQHan8&s=10',
      activo: 1
    },
    {
      id: 5,
      nombre: 'Scott Aspect 940',
      descripcion: 'Cuadro de aleación liviana, componentes Syncros y 18 velocidades Shimano.',
      categoria: 'bicicleta',
      subcategoria: 'Mountain Bike',
      marca: 'scott',
      gama: 'media',
      precio: 385000.00,
      cuotas_texto: '6 cuotas sin interés de $64.166',
      stock: 6,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ-IiFtxgRpViO2nmq2AhnIFrHRIfo7FfYHVeCqL0rmijS6NSztOrhHEkk&s=10',
      activo: 1
    },
    {
      id: 6,
      nombre: 'Cannondale Quick 4 Urban',
      descripcion: 'Bicicleta urbana ágil y ligera con sensor de rueda integrado para conectividad.',
      categoria: 'bicicleta',
      subcategoria: 'Urbana / Paseo',
      marca: 'giant',
      gama: 'media',
      precio: 320000.00,
      cuotas_texto: '6 cuotas sin interés de $53.333',
      stock: 7,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWKaiT3S3bqYqyCz5eQx2JTsoCBXbSQG28TIgQ42rKTQ&s',
      activo: 1
    },
    {
      id: 7,
      nombre: 'Casco Fox Proframe Enduro MIPS',
      descripcion: 'Tecnología de protección contra impactos rotacionales MIPS, ventilación Sweat Guide.',
      categoria: 'accesorio',
      subcategoria: 'Seguridad',
      marca: 'bell',
      gama: 'alta',
      precio: 85000.00,
      cuotas_texto: '3 cuotas sin interés de $28.333',
      stock: 15,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQfWw5r40XNNS3xnzC94kJ7d-G9c9o5gix_4gSf0jYRcQ&s=10',
      activo: 1
    },
    {
      id: 8,
      nombre: 'Luz LED Delantera Recargable 1200LM',
      descripcion: 'Batería 4000mAh, resistente al agua IPX6 y 5 modos de iluminación.',
      categoria: 'accesorio',
      subcategoria: 'Iluminación',
      marca: 'bell',
      gama: 'media',
      precio: 28000.00,
      cuotas_texto: '3 cuotas de $9.333',
      stock: 25,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSU1UlO6_X81B6t4Hxj6een3AYOM7_D92tnYAclQNjTC_DjBQXho8x1to6D&s=10',
      activo: 1
    },
    {
      id: 9,
      nombre: 'Guantes Giro DND Gel Antideslizantes',
      descripcion: 'Acolchado con gel antideslizante, tela transpirable y refuerzo en palma para mayor agarre.',
      categoria: 'accesorio',
      subcategoria: 'Indumentaria',
      marca: 'giro',
      gama: 'media',
      precio: 18500.00,
      cuotas_texto: '3 cuotas sin interés de $6.166',
      stock: 30,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQsq_UQxmKmQ5jPb4FNkEVwWD4QL8AwmfNtLKq6WLZzWtax3PG_fgYWGgE&s=10',
      activo: 1
    },
    {
      id: 10,
      nombre: 'Inflador Portátil con Manómetro',
      descripcion: 'Compatible con válvulas Presta y Schrader (auto), presión máxima de 120 PSI.',
      categoria: 'accesorio',
      subcategoria: 'Repuestos',
      marca: 'shimano',
      gama: 'media',
      precio: 15200.00,
      cuotas_texto: 'Efectivo 10% de descuento',
      stock: 20,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeYu7rnstXqO_GTcFsV8P8ME_eBO_CReXAypGEhFWFNw&s',
      activo: 1
    },
    {
      id: 11,
      nombre: 'Candado U-Lock Antirrobo Acero',
      descripcion: 'Grillete de acero endurecido de 14mm con cable de acero flexible de 1.2m incluido.',
      categoria: 'accesorio',
      subcategoria: 'Seguridad',
      marca: 'onguard',
      gama: 'alta',
      precio: 42000.00,
      cuotas_texto: '6 cuotas fijas de $7.000',
      stock: 18,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS_FFx-L0xsRI4ivSTyVh86yHlaVph-6Zf8EC15jDnJXKJRu54qERPA3oU&s=10',
      activo: 1
    },
    {
      id: 12,
      nombre: 'Cadena Shimano Deore 11V HG-X',
      descripcion: 'Cadena original de 116 eslabones con Quick-Link para transmisiones de 11 velocidades.',
      categoria: 'accesorio',
      subcategoria: 'Repuestos',
      marca: 'shimano',
      gama: 'media',
      precio: 32500.00,
      cuotas_texto: '3 cuotas sin interés de $10.833',
      stock: 22,
      imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_SET1Eq6_cT5TC1vH2vBMmknwKpmyR6AKIqM_p_cGB7CgT9lLL0-W6rQ&s=10',
      activo: 1
    }
  ],
  favoritos: [
    { id: 1, usuario_id: 1, producto_id: 1 },
    { id: 2, usuario_id: 1, producto_id: 7 },
    { id: 3, usuario_id: 1, producto_id: 8 },
    { id: 4, usuario_id: 1, producto_id: 4 }
  ],
  carrito: [
    { detalle_id: 1, producto_id: 7, cantidad: 1, color: 'Negro Mate', talle: 'L (58-61cm)' },
    { detalle_id: 2, producto_id: 8, cantidad: 1, color: 'Negro', talle: 'Único' },
    { detalle_id: 3, producto_id: 9, cantidad: 1, color: 'Azul Marino', talle: 'M' }
  ],
  pedidos: [
    {
      id: 1,
      numero_pedido: '#CM-PED-8942',
      subtotal: 520000,
      descuento: 0,
      total: 520000,
      total_formateado: '$520.000',
      fecha_formateada: '28/08/2026 15:40',
      estado: 'entregado',
      direccion_envio: 'Av. del Libertador 4580, CABA',
      creado_en: '2026-08-28 15:40:00',
      detalles: [
        {
          id: 1,
          producto_id: 4,
          nombre_producto: 'Trek Marlin 7 Gen 3 (Color Azul / Cuadro L)',
          precio_unitario: 520000,
          precio_formateado: '$520.000',
          cantidad: 1,
          subtotal: 520000,
          subtotal_formateado: '$520.000',
          imagen: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ16NyCSLKyWKzg27YN0Y8yfJ8xo66hy4GUYklaumhMk3l9SO69SUQHan8&s=10'
        }
      ]
    }
  ],
  turnos: [
    {
      id: 1,
      codigo_turno: '#CM-TUR-1054',
      servicio: 'Service Integral Pro',
      marca_bici: 'Specialized',
      modelo_bici: 'Demo 7',
      anio_bici: 2024,
      tipo_bici: 'mtb',
      fecha_turno: '2026-08-15',
      horario_turno: '14:00',
      fecha_formateada: '15/08/2026',
      presupuesto_base: 45000,
      presupuesto_formateado: '$45.000',
      mecanico_asignado: 'Martín Gómez (Jefe de Taller CicloMiku)',
      estado: 'completado',
      creado_en: '2026-08-10 11:00:00'
    }
  ],
  notificaciones: [
    {
      id: 1,
      tipo: 'taller',
      icono: '🔧',
      titulo: '¡Tu bicicleta Specialized Demo 7 ya está lista!',
      mensaje: 'El servicio de mantenimiento general y purga de frenos de 4 pistones ha finalizado con éxito. Podés pasar a retirarla por nuestro taller.',
      leida: false,
      fecha_formateada: 'Hace 2 horas'
    },
    {
      id: 2,
      tipo: 'envio',
      icono: '📦',
      titulo: 'Tu pedido #CM-PED-8942 fue entregado',
      mensaje: 'La empresa de transporte confirmó la entrega de tu bicicleta Trek Marlin 7 Gen 3 en tu domicilio.',
      leida: false,
      fecha_formateada: 'Ayer a las 15:40 hs'
    },
    {
      id: 3,
      tipo: 'promocion',
      icono: '🏷️',
      titulo: 'Beneficio CicloClub Oro: 15% OFF en Cubiertas',
      mensaje: 'Por ser cliente Oro, tenés un 15% de descuento adicional en cubiertas tubeless y cámaras.',
      leida: true,
      fecha_formateada: 'Hace 3 días'
    }
  ],
  configuracion: {
    nombre: 'Ivan',
    apellido: 'Boufarah',
    email: 'ivanboufarah@gmail.com',
    telefono: '+54 9 299 123-4567',
    dni: '42.859.102',
    direccion: 'Av. del Libertador 4580, Piso 4 Depto B',
    ciudad: 'CABA (Buenos Aires)',
    codigo_postal: 'C1426BWP',
    instrucciones_entrega: 'Tocar timbre en portería, dejar con encargado si no estoy.',
    notif_whatsapp_taller: 1,
    notif_recordatorio_turno: 1,
    notif_email_pedidos: 1,
    notif_promos_club: 0
  },
  usuarioActivo: 1 // Por defecto iniciamos con sesión de Ivan para demostración fluida
};

// ==============================================================================
// RUTAS DE LA API PHP (Mapeadas para Preview en Vivo en AI Studio)
// ==============================================================================

// 1. Estado de Sesión (PHP/auth/estado.php)
app.get(['/PHP/auth/estado.php', '/auth/estado.php'], (req, res) => {
  const user = db.usuarios.find(u => u.id === db.usuarioActivo);
  const sinLeer = db.notificaciones.filter(n => !n.leida).length;
  const itemsCarrito = db.carrito.reduce((sum, item) => sum + item.cantidad, 0);

  res.json({
    success: true,
    autenticado: !!user,
    usuario: user ? {
      id: user.id,
      nombre: user.nombre + (user.apellido ? ' ' + user.apellido : ''),
      email: user.email,
      telefono: user.telefono,
      rol: user.rol,
      rango_socio: user.rango_socio
    } : null,
    total_notificaciones_sin_leer: sinLeer,
    total_items_carrito: itemsCarrito,
    csrf_token: 'csrf_preview_token_123456789'
  });
});

// 2. Login (PHP/auth/login.php)
app.post(['/PHP/auth/login.php', '/auth/login.php'], (req, res) => {
  const email = (req.body.correo || req.body.email || '').toLowerCase().trim();
  const password = req.body.contrasena || req.body.password || '';

  const user = db.usuarios.find(u => u.email.toLowerCase() === email);
  if (!user || user.password !== password) {
    return res.status(401).json({
      success: false,
      error: 'El correo electrónico o la contraseña ingresada son incorrectos.'
    });
  }

  db.usuarioActivo = user.id;
  res.json({
    success: true,
    mensaje: 'Sesión iniciada correctamente',
    usuario: {
      id: user.id,
      nombre: user.nombre + (user.apellido ? ' ' + user.apellido : ''),
      email: user.email
    }
  });
});

// 3. Registro (PHP/auth/registro.php)
app.post(['/PHP/auth/registro.php', '/auth/registro.php'], (req, res) => {
  const nombre = req.body.nombre || '';
  const email = (req.body.correo || req.body.email || '').toLowerCase().trim();
  const telefono = req.body.telefono || '';
  const password = req.body.contrasena || req.body.password || '';

  if (!email || !password) {
    return res.status(400).json({ success: false, error: 'Datos incompletos.' });
  }

  const nuevoId = db.usuarios.length + 1;
  const nuevoUser = {
    id: nuevoId,
    nombre: nombre,
    apellido: '',
    email: email,
    password: password,
    telefono: telefono,
    dni: '',
    fecha_nacimiento: '',
    direccion: '',
    ciudad: '',
    codigo_postal: '',
    instrucciones_entrega: '',
    bici_actual_modelo: 'Bicicleta nueva',
    ultimo_service: 'Sin services previos',
    rango_socio: '⭐ Socio CicloClub Bronce',
    rol: 'cliente',
    creado_en: new Date().toISOString()
  };

  db.usuarios.push(nuevoUser);
  db.usuarioActivo = nuevoId;

  res.json({
    success: true,
    mensaje: 'Cuenta registrada exitosamente',
    usuario: {
      id: nuevoUser.id,
      nombre: nuevoUser.nombre,
      email: nuevoUser.email
    }
  });
});

// 4. Logout (PHP/auth/logout.php)
app.post(['/PHP/auth/logout.php', '/auth/logout.php'], (req, res) => {
  db.usuarioActivo = null;
  res.json({ success: true, mensaje: 'Sesión cerrada exitosamente' });
});

// 5. Catálogo de Productos (PHP/api/productos.php)
app.get(['/PHP/api/productos.php', '/api/productos.php'], (req, res) => {
  const { categoria, gama, subcategoria, marca, precio_max } = req.query;

  let filtrados = db.productos.filter(p => p.activo === 1);

  if (categoria) {
    filtrados = filtrados.filter(p => p.categoria.toLowerCase() === categoria.toLowerCase());
  }

  if (gama) {
    const gamasArr = gama.split(',').map(s => s.trim().toLowerCase());
    filtrados = filtrados.filter(p => gamasArr.includes(p.gama.toLowerCase()));
  }

  if (marca) {
    const marcasArr = marca.split(',').map(s => s.trim().toLowerCase());
    filtrados = filtrados.filter(p => marcasArr.includes(p.marca.toLowerCase()));
  }

  if (precio_max) {
    const maxVal = parseFloat(precio_max);
    if (!isNaN(maxVal)) {
      filtrados = filtrados.filter(p => p.precio <= maxVal);
    }
  }

  const items = filtrados.map(p => ({
    ...p,
    precio_formateado: '$' + Number(p.precio).toLocaleString('es-AR'),
    es_favorito: db.favoritos.some(f => f.usuario_id === db.usuarioActivo && f.producto_id === p.id)
  }));

  res.json({
    success: true,
    total: items.length,
    productos: items
  });
});

// 6. Carrito (PHP/api/carrito.php)
app.get(['/PHP/api/carrito.php', '/api/carrito.php'], (req, res) => {
  let subtotal = 0;
  const items = db.carrito.map(item => {
    const prod = db.productos.find(p => p.id === item.producto_id);
    const itemSubtotal = (prod ? prod.precio : 0) * item.cantidad;
    subtotal += itemSubtotal;

    return {
      detalle_id: item.detalle_id,
      producto_id: item.producto_id,
      cantidad: item.cantidad,
      color: item.color,
      talle: item.talle,
      nombre: prod ? prod.nombre : 'Producto',
      precio: prod ? prod.precio : 0,
      stock: prod ? prod.stock : 10,
      imagen: prod ? prod.imagen : '',
      subtotal: itemSubtotal,
      precio_formateado: '$' + Number(prod ? prod.precio : 0).toLocaleString('es-AR'),
      subtotal_formateado: '$' + Number(itemSubtotal).toLocaleString('es-AR')
    };
  });

  const descuento = Math.round(subtotal * 0.10);
  const total = subtotal - descuento;

  res.json({
    success: true,
    items: items,
    resumen: {
      subtotal: subtotal,
      subtotal_formateado: '$' + Number(subtotal).toLocaleString('es-AR'),
      descuento: descuento,
      descuento_formateado: '-$' + Number(descuento).toLocaleString('es-AR'),
      envio: 0,
      total: total,
      total_formateado: '$' + Number(total).toLocaleString('es-AR'),
      total_items: items.reduce((sum, i) => sum + i.cantidad, 0)
    }
  });
});

app.post(['/PHP/api/carrito.php', '/api/carrito.php'], (req, res) => {
  const { accion, producto_id, detalle_id, cantidad, color, talle } = req.body;

  if (accion === 'agregar') {
    const pid = parseInt(producto_id);
    const prod = db.productos.find(p => p.id === pid);
    if (!prod) return res.status(404).json({ success: false, error: 'Producto no encontrado.' });

    const existing = db.carrito.find(c => c.producto_id === pid);
    if (existing) {
      existing.cantidad += (parseInt(cantidad) || 1);
    } else {
      const nextId = db.carrito.length > 0 ? Math.max(...db.carrito.map(c => c.detalle_id)) + 1 : 1;
      db.carrito.push({
        detalle_id: nextId,
        producto_id: pid,
        cantidad: parseInt(cantidad) || 1,
        color: color || 'Estándar',
        talle: talle || 'Único'
      });
    }
    return res.json({ success: true, mensaje: 'Producto agregado al carrito.' });
  }

  if (accion === 'actualizar') {
    const did = parseInt(detalle_id);
    const item = db.carrito.find(c => c.detalle_id === did);
    if (item) {
      item.cantidad = Math.max(1, parseInt(cantidad) || 1);
    }
    return res.json({ success: true, mensaje: 'Cantidad actualizada.' });
  }

  if (accion === 'eliminar') {
    const did = parseInt(detalle_id);
    db.carrito = db.carrito.filter(c => c.detalle_id !== did);
    return res.json({ success: true, mensaje: 'Producto eliminado del carrito.' });
  }

  res.status(400).json({ success: false, error: 'Acción no reconocida.' });
});

// 7. Pedidos / Checkout (PHP/api/pedidos.php)
app.get(['/PHP/api/pedidos.php', '/api/pedidos.php'], (req, res) => {
  res.json({ success: true, pedidos: db.pedidos });
});

app.post(['/PHP/api/pedidos.php', '/api/pedidos.php'], (req, res) => {
  if (db.carrito.length === 0) {
    return res.status(400).json({ success: false, error: 'El carrito está vacío.' });
  }

  let subtotal = 0;
  const detalles = db.carrito.map(c => {
    const p = db.productos.find(x => x.id === c.producto_id);
    const itemSub = (p ? p.precio : 0) * c.cantidad;
    subtotal += itemSub;
    return {
      id: Math.floor(Math.random() * 10000),
      producto_id: c.producto_id,
      nombre_producto: p ? p.nombre : 'Producto',
      precio_unitario: p ? p.precio : 0,
      precio_formateado: '$' + Number(p ? p.precio : 0).toLocaleString('es-AR'),
      cantidad: c.cantidad,
      subtotal: itemSub,
      subtotal_formateado: '$' + Number(itemSub).toLocaleString('es-AR'),
      imagen: p ? p.imagen : ''
    };
  });

  const descuento = Math.round(subtotal * 0.10);
  const total = subtotal - descuento;
  const numeroPedido = '#CM-PED-' + Math.floor(1000 + Math.random() * 9000);

  const nuevoPedido = {
    id: db.pedidos.length + 1,
    numero_pedido: numeroPedido,
    subtotal: subtotal,
    descuento: descuento,
    total: total,
    total_formateado: '$' + Number(total).toLocaleString('es-AR'),
    fecha_formateada: new Date().toLocaleDateString('es-AR') + ' ' + new Date().toLocaleTimeString('es-AR').slice(0, 5),
    estado: 'en preparación',
    direccion_envio: db.configuracion.direccion || 'Av. del Libertador 4580, CABA',
    creado_en: new Date().toISOString(),
    detalles: detalles
  };

  db.pedidos.unshift(nuevoPedido);
  db.carrito = []; // Vaciar carrito tras checkout

  // Crear notificación del pedido
  db.notificaciones.unshift({
    id: db.notificaciones.length + 1,
    tipo: 'envio',
    icono: '📦',
    titulo: `¡Tu compra ${numeroPedido} ha sido confirmada!`,
    mensaje: `Estamos preparando tus productos para enviarlos a tu dirección.`,
    leida: false,
    fecha_formateada: 'Reciente'
  });

  res.json({
    success: true,
    mensaje: 'Pedido creado exitosamente',
    numero_pedido: numeroPedido
  });
});

// 8. Favoritos (PHP/api/favoritos.php)
app.get(['/PHP/api/favoritos.php', '/api/favoritos.php'], (req, res) => {
  const items = db.favoritos
    .filter(f => f.usuario_id === db.usuarioActivo)
    .map(f => {
      const p = db.productos.find(x => x.id === f.producto_id);
      if (!p) return null;
      return {
        id: f.id,
        producto_id: p.id,
        nombre: p.nombre,
        descripcion: p.descripcion,
        precio: p.precio,
        precio_formateado: '$' + Number(p.precio).toLocaleString('es-AR'),
        imagen: p.imagen,
        categoria: p.categoria,
        subcategoria: p.subcategoria
      };
    })
    .filter(Boolean);

  res.json({ success: true, total: items.length, favoritos: items });
});

app.post(['/PHP/api/favoritos.php', '/api/favoritos.php'], (req, res) => {
  const pid = parseInt(req.body.producto_id);
  const idx = db.favoritos.findIndex(f => f.usuario_id === db.usuarioActivo && f.producto_id === pid);

  if (idx >= 0) {
    db.favoritos.splice(idx, 1);
    return res.json({ success: true, activo: false, mensaje: 'Eliminado de favoritos.' });
  } else {
    const nextId = db.favoritos.length > 0 ? Math.max(...db.favoritos.map(f => f.id)) + 1 : 1;
    db.favoritos.push({ id: nextId, usuario_id: db.usuarioActivo, producto_id: pid });
    return res.json({ success: true, activo: true, mensaje: 'Guardado en favoritos.' });
  }
});

app.delete(['/PHP/api/favoritos.php', '/api/favoritos.php'], (req, res) => {
  const pid = parseInt(req.body.producto_id);
  db.favoritos = db.favoritos.filter(f => !(f.usuario_id === db.usuarioActivo && f.producto_id === pid));
  res.json({ success: true, mensaje: 'Eliminado de favoritos.' });
});

// 9. Turnos (PHP/api/turnos.php)
app.get(['/PHP/api/turnos.php', '/api/turnos.php'], (req, res) => {
  res.json({ success: true, turnos: db.turnos });
});

app.post(['/PHP/api/turnos.php', '/api/turnos.php'], (req, res) => {
  const { servicio, marca, modelo, anio, tipo, motivo, fecha, horario, nombre, telefono, email } = req.body;
  const codigo = '#CM-TUR-' + Math.floor(1000 + Math.random() * 9000);

  const precios = { basico: 20000, integral: 45000, frenos: 25000, suspension: 38000 };
  const precioBase = precios[servicio] || 20000;

  const nuevoTurno = {
    id: db.turnos.length + 1,
    codigo_turno: codigo,
    servicio: servicio || 'Mantenimiento Básico',
    marca_bici: marca || 'Genérica',
    modelo_bici: modelo || 'Estándar',
    anio_bici: anio || 2024,
    tipo_bici: tipo || 'mtb',
    motivo: motivo || '',
    fecha_turno: fecha || '2026-09-02',
    horario_turno: horario || '09:00',
    fecha_formateada: fecha || '2026-09-02',
    presupuesto_base: precioBase,
    presupuesto_formateado: '$' + Number(precioBase).toLocaleString('es-AR'),
    mecanico_asignado: 'Martín Gómez (Jefe de Taller CicloMiku)',
    estado: 'solicitado',
    creado_en: new Date().toISOString()
  };

  db.turnos.unshift(nuevoTurno);

  // Notificación del turno
  db.notificaciones.unshift({
    id: db.notificaciones.length + 1,
    tipo: 'taller',
    icono: '🔧',
    titulo: `Turno de Taller ${codigo} Solicitado`,
    mensaje: `Tu turno para ${servicio} el día ${fecha} (${horario} hs) fue registrado.`,
    leida: false,
    fecha_formateada: 'Reciente'
  });

  res.json({
    success: true,
    mensaje: 'Turno agendado exitosamente',
    codigo_turno: codigo
  });
});

// 10. Notificaciones (PHP/api/notificaciones.php)
app.get(['/PHP/api/notificaciones.php', '/api/notificaciones.php'], (req, res) => {
  const sinLeer = db.notificaciones.filter(n => !n.leida).length;
  res.json({
    success: true,
    total: db.notificaciones.length,
    sin_leer: sinLeer,
    notificaciones: db.notificaciones
  });
});

app.post(['/PHP/api/notificaciones.php', '/api/notificaciones.php'], (req, res) => {
  const { accion, id } = req.body;
  if (accion === 'marcar_todas_leidas') {
    db.notificaciones.forEach(n => n.leida = true);
    return res.json({ success: true, mensaje: 'Todas marcadas como leídas' });
  }
  if (accion === 'marcar_leida' && id) {
    const notif = db.notificaciones.find(n => n.id === parseInt(id));
    if (notif) notif.leida = true;
    return res.json({ success: true, mensaje: 'Notificación actualizada' });
  }
  res.json({ success: true });
});

// 11. Perfil (PHP/api/perfil.php)
app.get(['/PHP/api/perfil.php', '/api/perfil.php'], (req, res) => {
  const user = db.usuarios.find(u => u.id === db.usuarioActivo);
  if (!user) return res.status(401).json({ success: false, error: 'Debe iniciar sesión.' });

  res.json({
    success: true,
    perfil: {
      ...user,
      miembro_desde: 'Enero de 2024'
    }
  });
});

// 12. Configuración (PHP/api/configuracion.php)
app.get(['/PHP/api/configuracion.php', '/api/configuracion.php'], (req, res) => {
  res.json({
    success: true,
    configuracion: db.configuracion
  });
});

app.post(['/PHP/api/configuracion.php', '/api/configuracion.php'], (req, res) => {
  Object.assign(db.configuracion, req.body);
  const user = db.usuarios.find(u => u.id === db.usuarioActivo);
  if (user && req.body.nombre) {
    user.nombre = req.body.nombre;
  }
  res.json({ success: true, mensaje: 'Configuración actualizada.' });
});

// 13. Diagnóstico / Test de conexión visual
app.get('/PHP/test_conexion.php', (req, res) => {
  res.sendFile(path.join(__dirname, 'PHP', 'test_conexion.php'));
});

// ==============================================================================
// RUTAS ESTÁTICAS Y NAVEGACIÓN
// ==============================================================================

// Servir archivos estáticos del proyecto
app.use(express.static(__dirname));

// Mapeos de compatibilidad para enlaces
app.get(['/CicloMiku.html', '/menu_usuario/CicloMiku.html'], (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/menu_usuario/accesoriomikus.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'accesoriomikus.html'));
});

app.get('/menu_usuario/turnosmiku.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'turnosmiku.html'));
});

app.get('/menu_usuario/index.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, HOST, () => {
  console.log(`CicloMiku Server running on http://${HOST}:${PORT}`);
});
