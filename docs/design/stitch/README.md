# Referencias de diseño (Google Stitch)

Pantallas generadas con [Google Stitch](https://stitch.withgoogle.com) a partir
del documento de diseño, y su sistema de diseño exportado ("Archival Modernist").

| Archivo | Pose |
|---|---|
| `closed-carousel.png` | Duo cerrado: carrusel de portadas |
| `closed-details-sheet.png` | Duo cerrado: hoja de ficha |
| `open-portrait.png` | Duo abierto, vertical (669 pt) |
| `open-landscape.png` | Duo abierto, horizontal (890 pt) |
| `disc-insignia.png` | Ícono del disco |
| `DESIGN.md` | Tokens: colores, tipografía, espaciado, componentes |

Son referencia visual, no código. Lo que se toma y lo que no:

- Se toman la paleta, la tipografía (Bodoni Moda + Plus Jakarta Sans), las
  pastillas, las pestañas segmentadas, el formato de registro de los tracks, el
  riel y la portada en arco con el CD.
- No se toman los datos que Stitch inventó (vinilo, RPM, matriz, condición,
  fidelidad de audio, "142" favoritos), la reproducción de audio ni la barra de
  navegación inferior. La app muestra solo datos de Discogs y los discos son CDs.
- Las portadas se dibujan por código en el estilo de estas referencias; las
  ilustraciones generadas por Stitch no se usan.
- El layout adaptativo lo construye el skill `flutter-build-responsive-layout`;
  el `code.html` exportado por Stitch no se usa ni se versiona.
