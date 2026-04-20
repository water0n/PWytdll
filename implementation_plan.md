# Modernización de la Interfaz Gráfica (Migración a WPF)

El objetivo de este plan es reescribir la capa de presentación de la aplicación (actualmente en WinForms) para utilizar **WPF (Windows Presentation Foundation)**, dándole un aspecto moderno, fluido y nativo, **sin perder ninguna funcionalidad existente** y manteniendo la compatibilidad con PowerShell 5.1.

> [!IMPORTANT]
> Al migrar de WinForms a WPF, las propiedades de los controles cambian de nombre (por ejemplo: `.Text` en un botón pasa a ser `.Content`, `.Enabled` pasa a ser `.IsEnabled`, y los colores usan `SolidColorBrush` en lugar de `System.Drawing.Color`). Por lo tanto, será necesario hacer pequeños ajustes en `Main.ps1` y `Functions.ps1` para que se comuniquen correctamente con los nuevos controles.

## Open Questions
1. **Paleta de Colores:** Propongo un **Dark Theme** moderno (Fondo principal `#1E1E1E` o `#202020`) con acentos en **Índigo** (`#5E5CE6`) para los botones de acción, y texto en blanco o gris claro. ¿Te gusta esta paleta o prefieres un modo claro / otros colores?
Respuesta: Modo claro como los que usa APPLE.
2. **Vista Previa:** Actualmente se usa un `PictureBox` con bordes. En WPF podemos usar un `Image` con bordes redondeados y sombra. ¿Te parece bien mantener la miniatura centrada abajo como está ahora, o la ampliamos sutilmente?
Respuesta: Se puede ampliar y mejorar la vista previa.
3. **Menú de Dependencias (`Show-AppInfo`):** ¿Mantenemos la estructura actual de texto + botones de actualizar al lado, pero con diseño moderno, o te gustaría que se vea como una tabla/rejilla elegante?
Respuesta: Rejilla elegante, tiene que ser facil de usar para cualquier usuario.

## Proposed Changes

### Interfaz Gráfica (WPF)
El cambio más grande. Se reemplazará la creación de controles WinForms por plantillas **XAML** limpias y estructuradas.

#### [MODIFY] `GUI.ps1`
- **Eliminar** las funciones de fábrica antiguas de WinForms (`Create-Button`, `Create-Label`, etc.).
- **Agregar** una plantilla XAML central para el `$formPrincipal` utilizando `Grid`, `StackPanel` y `Border` para lograr bordes redondeados nativos, sombras (DropShadowEffect) y diseño responsivo.
- **Convertir** la lógica de color dinámica en `Set-DownloadButtonVisual` para usar `SolidColorBrush` y afectar la propiedad `.Background` en lugar de `.BackColor`.
- **Refactorizar** `Show-PreviewImage` y `Show-PreviewUniversal` para usar `System.Windows.Media.Imaging.BitmapImage` en lugar de `System.Drawing.Image`.
- **Reescribir** `Show-AppInfo`, `Show-SitesDialog` y `Show-UrlHistoryMenu` utilizando ventanas y controles WPF (`Window`, `ListBox`, `ContextMenu`).

### Integración de la Lógica
Los scripts que "tocan" la interfaz deben adaptarse a los nombres de propiedades de WPF.

#### [MODIFY] `Main.ps1`
- Cambiar referencias a `.Text` por `.Content` en los controles tipo Button o Label (en WPF los Labels o TextBlocks usan `.Text` o `.Content` dependiendo del tipo elegido, unificaremos esto).
- Cambiar `.Enabled` por `.IsEnabled`.
- Cambiar el manejo de cierre de ventana (WPF no usa `.Dispose()`, solo `.Close()`).
- Reemplazar `[System.Windows.Forms.MessageBox]` por `[System.Windows.MessageBox]`.
- Reemplazar diálogos de selección de carpetas/archivos (`FolderBrowserDialog`, `OpenFileDialog`) por sus equivalentes nativos que funcionen bien en WPF.

#### [MODIFY] `Functions.ps1`
- Ajustar cualquier referencia de color (`.ForeColor` -> `.Foreground`).
- Si interactúa con el `ComboBox` (`$cmbVideoFmt`), asegurar que agregue los ítems de manera compatible con WPF (WPF soporta objetos en `.Items.Add()`, por lo que el comportamiento debería ser casi idéntico).

## Verification Plan

### Manual Verification
1. **Ejecutar `.\Main.ps1`**: Verificar que la ventana principal carga con el nuevo diseño XAML sin errores de "tipo no encontrado".
2. **Funcionalidad UI**: Comprobar que el arrastre de ventana sin bordes funcione, los tooltips se muestren y los bordes redondeados se vean bien.
3. **Flujo de Descarga**: Escribir una URL, comprobar que el botón cambie de color y texto (Buscar Video -> Descargar Video).
4. **Vista Previa**: Validar que la miniatura cargue correctamente en el nuevo control WPF `Image`.
5. **Ventanas Secundarias**: Abrir `AppInfo` (?) y `Sitios compatibles` para asegurar que las nuevas ventanas XAML se abren y funcionan igual.
