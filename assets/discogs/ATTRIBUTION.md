# Datos de Discogs

Los archivos `*.json` de esta carpeta vienen de la API pública de Discogs
(https://api.discogs.com) y contienen solo campos que Discogs publica bajo
licencia CC0 ("No Rights Reserved"): títulos, artistas, fechas, país, sellos,
formatos, géneros, estilos, tracklist, créditos y notas.

No se incluyen imágenes de portada, datos de comunidad ni de marketplace. Las
portadas de la app se generan por código y no reproducen las originales.

| Archivo | Release | URL |
|---|---|---|
| `4214311.json` | Gorillaz — Gorillaz (2001) | https://www.discogs.com/release/4214311 |
| `13115020.json` | Daft Punk — Random Access Memories (2013) | https://www.discogs.com/release/13115020 |
| `9100081.json` | Sal y Mileto — Disko 0 (2001) | https://www.discogs.com/release/9100081 |
| `11066248.json` | Gondwana — Alabanza (2000) | https://www.discogs.com/release/11066248 |
| `8172924.json` | Cultura Profética — La Dulzura (2010) | https://www.discogs.com/release/8172924 |

Para regenerarlos: `fvm dart run tool/fetch_discogs.dart`.
