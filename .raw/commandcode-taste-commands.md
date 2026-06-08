# TASTE: Referencia de Comandos — Documentación CommandCode

**URL:** https://commandcode.ai/docs/taste/commands
**Ingestado:** 2026-06-08

## Comandos disponibles

| Comando | Sintaxis                                                             | Descripción                              |
|---------|----------------------------------------------------------------------|------------------------------------------|
| Push    | `npx taste push [package]`<br>`npx taste push --all`<br>`npx taste push [package] -g` | Sube paquetes a remoto o global |
| Pull    | `npx taste pull [package]`<br>`npx taste pull [namespace/package]`<br>`npx taste pull [package] -g` | Descarga paquetes desde remoto o global |
| List    | `npx taste list`                                                     | Lista todos los paquetes disponibles     |
| Lint    | `npx taste lint`                                                     | Valida formato y estructura de paquete   |
| Open    | `npx taste open`                                                     | Abre paquetes en el editor predeterminado|

## Flags y opciones

- **`--all`**: Empuja toda la carpeta de taste del proyecto como unidad
- **`-g`**: Interactúa con paquetes globales (`~/.commandcode/taste/`)
- Sin flag: Interactúa con paquetes remotos por defecto

## Ejemplos de uso

```bash
# Proyecto completo
npx taste push --all
npx taste pull username/project-name

# Paquetes individuales
npx taste push cli
npx taste push myorg/cli
npx taste pull cli -g
```

## Ubicaciones de almacenamiento

- **Proyecto**: `.commandcode/taste/`
- **Global**: `~/.commandcode/taste/`
- **Remoto**: `commandcode.ai/username/taste`

Nota: `npx taste` y `cmd taste` son equivalentes; el segundo requiere instalación global.
