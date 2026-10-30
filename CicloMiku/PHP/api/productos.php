<?php
/**
 * ==============================================================================
 * CICLOMIKU - API DE PRODUCTOS Y FILTROS DESDE MARIADB
 * ==============================================================================
 */

require_once __DIR__ . '/../config/conexion.php';
require_once __DIR__ . '/../includes/sesion.php';

$pdo = obtenerConexion();
$usuarioId = obtenerUsuarioId();

// Parámetros de filtro
$categoria    = trim($_GET['categoria'] ?? '');
$subcategoria = $_GET['subcategoria'] ?? null;
$gama         = $_GET['gama'] ?? null;
$marca        = $_GET['marca'] ?? null;
$precioMax    = isset($_GET['precio_max']) ? (float)$_GET['precio_max'] : null;
$buscar       = trim($_GET['buscar'] ?? '');

$sql = "SELECT id, nombre, descripcion, categoria, subcategoria, marca, gama, precio, cuotas_texto, stock, imagen, activo FROM productos WHERE activo = 1";
$params = [];

// Filtro por categoría principal (bicicleta / accesorio)
if (!empty($categoria)) {
    $sql .= " AND categoria = :categoria";
    $params[':categoria'] = $categoria;
}

// Filtro por gama (puede ser string separado por comas o array)
if (!empty($gama)) {
    $gamas = is_array($gama) ? $gama : explode(',', $gama);
    $gamas = array_filter(array_map('trim', $gamas));
    if (!empty($gamas)) {
        $placeholders = [];
        foreach ($gamas as $i => $g) {
            $key = ":gama_{$i}";
            $placeholders[] = $key;
            $params[$key] = $g;
        }
        $sql .= " AND gama IN (" . implode(',', $placeholders) . ")";
    }
}

// Filtro por marcas
if (!empty($marca)) {
    $marcas = is_array($marca) ? $marca : explode(',', $marca);
    $marcas = array_filter(array_map('trim', $marcas));
    if (!empty($marcas)) {
        $placeholders = [];
        foreach ($marcas as $i => $m) {
            $key = ":marca_{$i}";
            $placeholders[] = $key;
            $params[$key] = strtolower($m);
        }
        $sql .= " AND LOWER(marca) IN (" . implode(',', $placeholders) . ")";
    }
}

// Filtro por tipo / modelo / subcategoría
if (!empty($subcategoria)) {
    $subs = is_array($subcategoria) ? $subcategoria : explode(',', $subcategoria);
    $subs = array_filter(array_map('trim', $subs));
    if (!empty($subs)) {
        $subConds = [];
        foreach ($subs as $i => $s) {
            $key = ":sub_{$i}";
            $subConds[] = "LOWER(subcategoria) LIKE {$key}";
            $params[$key] = '%' . strtolower($s) . '%';
        }
        $sql .= " AND (" . implode(' OR ', $subConds) . ")";
    }
}

// Filtro por precio máximo
if ($precioMax !== null && $precioMax > 0) {
    $sql .= " AND precio <= :precio_max";
    $params[':precio_max'] = $precioMax;
}

// Búsqueda por texto
if (!empty($buscar)) {
    // Con consultas preparadas nativas un marcador no puede repetirse: se usan dos distintos
    $sql .= " AND (nombre LIKE :buscar_a OR descripcion LIKE :buscar_b)";
    $params[':buscar_a'] = '%' . $buscar . '%';
    $params[':buscar_b'] = '%' . $buscar . '%';
}

$sql .= " ORDER BY id ASC";

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $productos = $stmt->fetchAll();

    // Obtener lista de IDs favoritos del usuario para marcar los corazones
    $favoritosIds = [];
    if ($usuarioId) {
        $stmtFav = $pdo->prepare("SELECT producto_id FROM favoritos WHERE usuario_id = :uid");
        $stmtFav->execute([':uid' => $usuarioId]);
        $favoritosIds = $stmtFav->fetchAll(PDO::FETCH_COLUMN);
    }

    foreach ($productos as &$p) {
        $p['precio'] = (float)$p['precio'];
        $p['precio_formateado'] = '$' . number_format($p['precio'], 0, ',', '.');
        $p['es_favorito'] = in_array((int)$p['id'], array_map('intval', $favoritosIds), true);
    }

    responderJSON([
        'success'   => true,
        'total'     => count($productos),
        'productos' => $productos
    ]);

} catch (PDOException $e) {
    responderErrorSQL($e, 'productos.php', 'Error al consultar el catálogo de productos.');
}
