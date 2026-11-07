# Progreso — App Calendario + To-Do (Flutter)

Especificación: https://claude.ai/artifact/6iyHVc8BPKqx2BQnSdakuC — estado detallado por requisito en [README.md](README.md).

## Estado (2026-11-07)

- Las cuatro fases están escritas. `flutter analyze` sale sin avisos y `flutter test` pasa 62/62.
- El APK de depuración compila (`build/app/outputs/flutter-apk/app-debug.apk`).
- Probado en el emulador Android API 37:
  - creación por texto natural;
  - vistas día, semana, mes y agenda;
  - solapamientos lado a lado;
  - arrastrar un bloque;
  - completar;
  - borrar con deshacer;
  - hoja de detalle;
  - ajustes y cambio a español.

## Pendiente / sin verificar

- iOS: no se puede compilar desde Windows. Falta crear el target del widget en Xcode (ver README).
- Sin probar en dispositivo: que los avisos suenen con la app cerrada, el widget de Android colocado en la pantalla de inicio y las acciones «Completar»/«Posponer» desde la notificación.

## Entorno

- Flutter: `D:\flutter`. Caché de pub: `$env:PUB_CACHE='D:\pub-cache'` (obligatorio en esta máquina).
- Emulador: `Medium_Phone_API_37.0`.
