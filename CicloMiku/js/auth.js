/**
 * CICLOMIKU - Inicio de sesión y registro (PHP + MySQL)
 */
document.addEventListener('DOMContentLoaded', function () {
  'use strict';
  const API = window.CicloMikuAPI;

  const tabLogin = document.getElementById('tab-login');
  const tabRegistro = document.getElementById('tab-registro');
  const formLogin = document.getElementById('form-login');
  const formRegistro = document.getElementById('form-registro');
  const alerta = document.getElementById('alerta');

  function mostrarAlerta(msg, tipo) {
    if (!alerta) return;
    alerta.className = 'alerta-mensaje alert alert-' + (tipo || 'danger');
    alerta.textContent = msg;
    alerta.style.display = 'block';
  }
  function ocultarAlerta() { if (alerta) alerta.style.display = 'none'; }

  function mostrarLogin() {
    tabLogin.classList.add('pestana-activa'); tabRegistro.classList.remove('pestana-activa');
    formLogin.style.display = 'block'; formRegistro.style.display = 'none'; ocultarAlerta();
  }
  function mostrarRegistro() {
    tabRegistro.classList.add('pestana-activa'); tabLogin.classList.remove('pestana-activa');
    formRegistro.style.display = 'block'; formLogin.style.display = 'none'; ocultarAlerta();
  }
  if (tabLogin && tabRegistro && formLogin && formRegistro) {
    tabLogin.addEventListener('click', mostrarLogin);
    tabRegistro.addEventListener('click', mostrarRegistro);
    const a = document.getElementById('ir-a-registro'), b = document.getElementById('ir-a-login');
    if (a) a.addEventListener('click', e => { e.preventDefault(); mostrarRegistro(); });
    if (b) b.addEventListener('click', e => { e.preventDefault(); mostrarLogin(); });
    if (window.location.hash === '#registro') mostrarRegistro();
  }

  function enlazarMostrar(btnId, inputId) {
    const btn = document.getElementById(btnId), inp = document.getElementById(inputId);
    if (!btn || !inp) return;
    btn.addEventListener('click', () => {
      const oculto = inp.type === 'password';
      inp.type = oculto ? 'text' : 'password';
      btn.textContent = oculto ? 'Ocultar' : 'Mostrar';
    });
  }
  enlazarMostrar('toggleBtnLogin', 'login-contrasena');
  enlazarMostrar('toggleBtn', 'contrasena');

  const olvido = document.getElementById('olvide-clave');
  if (olvido) olvido.addEventListener('click', e => {
    e.preventDefault();
    mostrarAlerta('Todavía no hay recuperación automática de contraseña. Escribinos a ventas@ciclomiku.com para restablecerla.', 'info');
  });

  function irAlPerfil() { setTimeout(() => { window.location.href = 'perfil.html'; }, 900); }

  if (formLogin) formLogin.addEventListener('submit', async function (e) {
    e.preventDefault(); ocultarAlerta();
    const email = document.getElementById('login-correo').value.trim();
    const password = document.getElementById('login-contrasena').value;
    const btn = formLogin.querySelector('button[type="submit"]');
    if (!email || !password) { mostrarAlerta('Completá tu correo y tu contraseña.', 'warning'); return; }

    btn.disabled = true; btn.textContent = 'Ingresando...';
    const res = await API.fetchAPI('PHP/auth/login.php', { method: 'POST', body: { correo: email, contrasena: password } });
    btn.disabled = false; btn.textContent = 'Iniciar Sesión';

    if (res.success) {
      mostrarAlerta(res.mensaje + ' Te llevamos a tu perfil...', 'success');
      await API.actualizarEstadoSesion();
      irAlPerfil();
    } else {
      mostrarAlerta(res.error || 'No se pudo iniciar sesión.', 'danger');
    }
  });

  if (formRegistro) formRegistro.addEventListener('submit', async function (e) {
    e.preventDefault(); ocultarAlerta();
    const v = id => (document.getElementById(id) ? document.getElementById(id).value.trim() : '');
    const nombre = v('nombre'), apellido = v('apellido'), correo = v('correo'), telefono = v('telefono');
    const pass = document.getElementById('contrasena').value;
    const pass2 = document.getElementById('confirmar-contrasena').value;
    const terminos = document.getElementById('terminos').checked;
    const wa = document.getElementById('ter1') ? document.getElementById('ter1').checked : false;
    const btn = formRegistro.querySelector('button[type="submit"]');

    if (!nombre || !apellido) return mostrarAlerta('Ingresá tu nombre y tu apellido.', 'warning');
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(correo)) return mostrarAlerta('Ingresá un correo electrónico válido.', 'warning');
    if (telefono && !/^[0-9 +().-]{6,25}$/.test(telefono)) return mostrarAlerta('El teléfono solo puede tener números, espacios y + ( ) - .', 'warning');
    if (pass.length < 8) return mostrarAlerta('La contraseña debe tener al menos 8 caracteres.', 'warning');
    if (pass !== pass2) return mostrarAlerta('Las contraseñas no coinciden.', 'warning');
    if (!terminos) return mostrarAlerta('Tenés que aceptar los términos y condiciones para registrarte.', 'warning');

    btn.disabled = true; btn.textContent = 'Creando cuenta...';
    const res = await API.fetchAPI('PHP/auth/registro.php', {
      method: 'POST',
      body: { nombre, apellido, correo, telefono, contrasena: pass, acepta_whatsapp: wa }
    });
    btn.disabled = false; btn.textContent = 'Crear Cuenta';

    if (res.success) {
      mostrarAlerta(res.mensaje + ' Te llevamos a tu perfil...', 'success');
      await API.actualizarEstadoSesion();
      irAlPerfil();
    } else {
      mostrarAlerta(res.error || 'No se pudo crear la cuenta.', 'danger');
    }
  });
});
