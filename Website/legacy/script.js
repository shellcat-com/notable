const downloadLinks = document.querySelectorAll('a[href="downloads/Notable.zip"]');

downloadLinks.forEach((link) => {
  link.addEventListener("click", () => {
    link.dataset.clicked = "true";
  });
});
