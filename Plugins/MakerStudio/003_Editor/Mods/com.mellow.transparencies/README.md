# Transparency — Priority 666 (mod de Maker Studio)

Registra la priority custom **`666: Transparencies`** en el desplegable de
propiedades del tileset, para usarla con el plugin Ruby
**`[MDLN] Building Transparency`**.

## Priority 666 (Transparencies)

Para que un tile active el fade al pasar el jugador detrás, debe tener
**Priority = `666: Transparencies`** (aparece al final del desplegable, debajo
de `5: Above 5`). El runtime trata el dibujado Z como Above 5; solo el valor
`666` dispara la transparencia. No hace falta whitelist de tilesets.

Si al abrir el desplegable ves números sueltos (`6`, `7`, …) sin nombre, usa el
campo **Filter** y escribe `666` o `Transparencies`. El mod también oculta esos
huecos cuando puede.

**Migración:** tiles que antes usaban priority 2–5 para el fade **dejan de
fadear** hasta retaggearlos a `666`. Las priorities 1–5 quedan libres para
dibujado normal sin activar transparencia.

Requiere el mod cargado (Reload Mods) para que la opción aparezca en el
desplegable.

## Cómo funciona internamente

- Registra `ctx.tileset.registerPriority({ id: 666, name: "Transparencies" })`.
- Observa el DOM del dropdown y oculta opciones numéricas 6..665; fuerza el
  label `666: Transparencies`.

## Requisitos

- **Maker Studio** con API `>= 1.0.0` (y `registerPriority` disponible).
- Plugin **`[MDLN] Building Transparency`** en `Plugins/` — declarado en
  `manifest.requires` con `enforcement: "none"` + link a
  [releases/latest](https://github.com/MellowB1/-MDLN-Transparencies/releases/latest).
  Sin el plugin el mod **carga**; Maker Studio avisa con su propio diálogo/link.
  El fade in-game necesita el plugin instalado.
- Repo del mod: [MellowB1/Maker-Studio-Transparecies](https://github.com/MellowB1/Maker-Studio-Transparecies).

## Publicar (Marketplace)

1. Asegura `manifest.json#version` = versión a publicar.
2. Crea tag `vX.Y.Z` (debe coincidir con el manifest) y push del tag.
3. El workflow `publish.yml` genera el zip, la release y abre PR al registry
   (requiere secret `REGISTRY_PAT` y fork de `Toskan4134/maker-studio-mods`).

## Estructura

```
[MDLN] Transparencies/
  manifest.json
  index.js
  README.md
  .github/workflows/publish.yml
```
