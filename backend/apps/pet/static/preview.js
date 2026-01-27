(function () {
  function ready(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  ready(function () {
    var input = document.getElementById('id_cover');        // Django admin 的 file input id
    var img   = document.getElementById('cover-preview');    // 我们在 admin 里渲染的 <img>

    if (!input || !img) return;

    input.addEventListener('change', function (e) {
      var file = e.target.files && e.target.files[0];
      if (!file) return;
      var url = (window.URL || window.webkitURL).createObjectURL(file);
      img.src = url;
      img.style.display = 'block';
    });
  });
})();
