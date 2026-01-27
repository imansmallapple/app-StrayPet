(function() {
  document.addEventListener("DOMContentLoaded", function () {
    var input = document.getElementById("id_cover");
    var img   = document.getElementById("cover-preview");
    if (!input || !img) return;

    input.addEventListener("change", function (e) {
      const file = e.target.files && e.target.files[0];
      if (!file) return;
      const url = URL.createObjectURL(file);
      img.src = url;
    });
  });
})();
