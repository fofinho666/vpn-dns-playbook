(function () {
  if (!window.location.pathname.startsWith('/admin/login')) return;
  if (window.location.search.includes('s=logout')) return;
  if (sessionStorage.getItem('_hp_auto')) return;

  function submit() {
    sessionStorage.setItem('_hp_auto', '1');
    var f = document.createElement('form');
    f.method = 'POST';
    f.action = '/admin/login';
    var i = document.createElement('input');
    i.type = 'hidden';
    i.name = 'api_key';
    i.value = '{{ headscale_api_key }}';
    f.appendChild(i);
    document.body.appendChild(f);
    f.submit();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', submit);
  } else {
    submit();
  }
})();
