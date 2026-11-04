# Zap México

Aplicación Flutter con un directorio local de negocios. Firebase administra la autenticación y las fichas registradas; el catálogo local inicial se conserva para consulta sin conexión.

El catálogo contiene negocios nombrados en OpenStreetMap y en directorios/perfiles públicos de negocios. Los datos de OpenStreetMap se distribuyen bajo ODbL 1.0; se incluye el enlace a la fuente por ficha y los datos pueden estar desactualizados. Las direcciones, teléfonos y horarios solo se muestran cuando la fuente los publica. No se inventan calificaciones: las fichas importadas comienzan con cero reseñas y sin puntuación.

El catálogo local inicial contiene negocios de Ciudad Hidalgo y Senguio. La app ofrece esos municipios y las categorías base al inicio; el administrador puede habilitar cualquiera de los 113 municipios de Michoacán y agregar categorías desde **Catálogos** en el panel. Los cambios se guardan en Firestore y se reflejan en los selectores del directorio, registro de negocios y eventos.

Para mostrar una ficha de negocio, la fuente debe publicar al menos dos de estos tres datos requeridos: dirección, teléfono y horario. Los atractivos turísticos no siempre publican teléfono u horario; esas fichas requieren ubicación y fuente pública verificable y muestran únicamente los datos confirmados. Senguihongo se incluye con solo la dirección por solicitud expresa; la ficha no completa ni inventa teléfono u horario.

La cobertura inicial es desigual y el directorio no pretende incluir todos los establecimientos. Se añaden enlaces de redes sociales solo cuando se puede identificar una cuenta pública del negocio.

Las tarjetas y detalles usan una imagen ilustrativa de categoría, nunca una foto atribuida al establecimiento. Son recursos locales con licencias reutilizables; sus atribuciones están en [ATTRIBUTIONS.txt](assets/images/business_categories/ATTRIBUTIONS.txt). Cada ficha indica en su descripción que la imagen es ilustrativa. Las altas de usuarios también usan esa ilustración mientras esperan aprobación.

Datos © [colaboradores de OpenStreetMap](https://www.openstreetmap.org/copyright), disponibles bajo ODbL 1.0. Algunas fichas adicionales se basan en directorios públicos de [Ciudad Hidalgo](https://www.cdhidalgo.com/servicios), resultados públicos de negocios y páginas públicas de Facebook; los enlaces se guardan como fuentes para consulta.

## Firebase y Google Cloud

La aplicación ya está configurada para el proyecto Firebase `zap2026-382a1`. La facturación de Google Cloud no se activa desde Flutter; verifica en Google Cloud Console que la facturación esté vinculada al proyecto. En Firebase Console habilita:

1. **Authentication**: proveedores Correo/contraseña, Google y Anónimo.
2. **Firestore Database**: crea la base de datos.
3. **Storage**: crea el bucket para las imágenes.

Instala Firebase CLI, inicia sesión con una cuenta autorizada y publica las reglas del repositorio:

```sh
firebase login
firebase deploy --only firestore:rules,storage
```

### Crear la cuenta administradora

1. Crea/inicia sesión con la cuenta que será administradora mediante correo/contraseña o Google.
2. En Firebase Console, abre **Authentication > Users** y copia el UID de esa cuenta.
3. En **Firestore Database**, crea la colección `admins` y un documento cuyo ID sea exactamente ese UID. Agrega el campo `role` (tipo string) con valor `admin`.
4. Cierra y vuelve a iniciar sesión en la app. El panel de administración aparecerá para esa cuenta.

Al iniciar con Google, el formulario de cuenta nueva toma el nombre y correo del perfil de Google; si el perfil de la app aún está incompleto, se solicita terminarlo antes de continuar. En el acceso normal se recuerda localmente el último correo usado y se habilita el autocompletado seguro del dispositivo para las credenciales. La app no guarda contraseñas. Después de iniciar sesión, en dispositivos Android/iOS con biometría configurada se puede activar el desbloqueo con huella o Face ID para volver a abrir la sesión existente. El atajo biométrico no guarda credenciales y se desactiva al cerrar sesión explícitamente.

Los visitantes pueden explorar el directorio, pero deben crear una cuenta o iniciar sesión para registrar negocios, guardar favoritos, calificar o editar su perfil. Los perfiles registrados pueden cambiar nombre y usuario y subir una foto desde **Mi perfil**. Las fotos se guardan en Storage bajo una ruta privada de usuario.

No se puede asignar el rol desde la app: las reglas bloquean escrituras en `admins`. Los administradores pueden crear fichas desde **Agregar negocio**; se guardan automáticamente en Firestore con estado pendiente. Desde el panel pueden aprobar/rechazar solicitudes, modificar fichas y subir imágenes. El público solo puede leer negocios aprobados.

Las solicitudes de usuarios también se guardan en Firestore y aparecen en la pestaña **Pendientes** para revisión. El formulario permite registrar un negocio o un prestador de servicios. Los prestadores, como arquitectos, aparecen en el mismo directorio bajo el filtro **Servicios** y pasan por la misma aprobación administrativa; pueden dejar dirección, horario y logo vacíos. En ambas modalidades se selecciona un municipio y una categoría disponibles; si falta una opción, se puede proponer desde el formulario. Las propuestas quedan pendientes en **Catálogos**, junto a la ficha que las originó, y solo se incorporan al catálogo cuando un administrador las aprueba. Las propuestas de municipios se validan contra la lista oficial de Michoacán. Se requieren al menos tres fotos para el carrusel; el logo es opcional y, si no se carga, se usa una ilustración de categoría. Los archivos se guardan en Firebase Storage. Solo el propietario de una ficha pendiente puede subir sus imágenes; el administrador puede cambiar logo, fotos y datos. Para proteger la publicación, una ficha nueva no se puede aprobar hasta que tenga tres fotos.

El panel también permite editar, agregar y ocultar eventos del carrusel por municipio, con imagen opcional y enlace de referencia. Los eventos existentes se conservan como contenido base y se pueden sobrescribir u ocultar. En **Bloqueos**, el administrador puede bloquear/desbloquear negocios (se ocultan del directorio) y usuarios (se suspende el uso de la app). Vuelve a desplegar `firestore.rules` y `storage.rules` después de cualquier cambio en esos archivos. Las reglas de Firestore incluyen lecturas públicas de catálogos, altas de propuestas ligadas al negocio enviado y escrituras administrativas para su aprobación.

Si las reglas ya se desplegaron antes de habilitar la carga de imágenes por propietarios, vuelve a publicarlas después de actualizar el código:

```sh
firebase deploy --only firestore:rules,storage --project zap2026-382a1
```

### Marketplace

El Marketplace está disponible desde el menú principal. Cualquier persona puede consultar publicaciones vigentes; para publicar se requiere una cuenta registrada, un nombre de producto, precio mayor que cero y entre una y tres fotos. La ubicación y el nombre del vendedor se toman del perfil, y se muestra la fecha y hora de publicación. Cada propietario puede eliminar sus anuncios.

Las publicaciones vencen cinco días después de publicarse. La función programada `expireMarketplaceProducts` revisa los anuncios una vez al día y elimina los vencidos junto con sus fotos de Firebase Storage; por ello, el borrado puede ocurrir hasta 24 horas después de cumplir cinco días. Para instalar sus dependencias y desplegar la función y las reglas:

```sh
npm --prefix functions install
npm --prefix functions run lint
firebase deploy --only functions,firestore:rules,storage --project zap2026-382a1
```

Las funciones programadas requieren que el proyecto tenga facturación de Google Cloud habilitada.

### Prestadores y notificaciones

En **Registrar negocio o servicio**, selecciona **Prestador de servicios** para publicar a un profesional (por ejemplo, arquitectura y diseño). Los prestadores usan la misma revisión administrativa que los negocios; se puede proponer una profesión/categoría si no existe. Dirección, horario y logo son opcionales para prestadores. Los anuncios aprobados se encuentran en el directorio con los filtros **Negocios** y **Servicios**.

La app guarda una bandeja de notificaciones por usuario. Cloud Functions la alimenta al recibir nuevas solicitudes, al aprobar/rechazar una ficha y al eliminar un producto vencido de Marketplace. También envía push a dispositivos registrados. Para activarlas en producción, publica reglas y funciones:

```sh
firebase deploy --only firestore:rules,functions --project zap2026-382a1
```

En Android se pide permiso para notificaciones al iniciar sesión y los avisos push se muestran también con la app abierta. En iOS debe estar configurada la clave APNs en Firebase Console para la app iOS. En web la bandeja funciona sin configuración adicional; para push del navegador, habilita Firebase Cloud Messaging, configura una clave VAPID y ejecuta la app compilada con `--dart-define=FCM_WEB_VAPID_KEY=<clave-publica-vapid>`. El worker web está en `web/firebase-messaging-sw.js`.

## Ejecutar

```sh
flutter pub get
flutter run
```

## Validar

```sh
flutter analyze
flutter test
```

## Firma estable de Android App Bundle en GitHub Actions

El workflow de Android requiere una keystore estable para que las siguientes versiones se firmen con el mismo certificado. Crea la keystore en un lugar seguro y conserva una copia de respaldo; no la subas al repositorio ni la compartas. En Windows, desde la raíz del proyecto:

```powershell
keytool -genkeypair -v -keystore android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zapmexico
```

Guarda en un administrador de contraseñas las contraseñas que generes; no las subas al repositorio ni las compartas. La keystore está excluida de Git. Obtén la huella SHA-1 del certificado:

```powershell
keytool -list -v -keystore android\app\upload-keystore.jks -alias zapmexico
```

Agrega esa SHA-1 en Firebase Console, en la app Android `mx.tecnm.cdhidalgo.zap_mexico`. Configura las credenciales de firma como **Actions secrets** en GitHub (`Settings > Secrets and variables > Actions`), usando los nombres que requiere el workflow. Para copiar el contenido codificado de la keystore al portapapeles en PowerShell:
  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\upload-keystore.jks")) | Set-Clipboard
  ```

Después de guardar los secretos, ejecuta el workflow **Build Android App Bundle** y descarga el artifact `zap-mexico-aab`. No registres la SHA-1 de un APK firmado con `debug`: el workflow exige los secretos y usa exclusivamente la keystore de subida. Conserva una copia segura de la keystore; si se pierde, no se podrán firmar actualizaciones compatibles con esta app. Con Play App Signing, registra también en Firebase la huella SHA-1 del certificado de firma de la app que muestra Play Console.

## Eliminación de cuenta

Las cuentas registradas pueden eliminarse desde **Mi perfil > Eliminar cuenta** o desde la página web:

`https://zap2026-382a1.web.app/account-deletion.html`

La solicitud elimina la cuenta de Firebase Authentication, el perfil y sus subcolecciones, la foto de perfil, los negocios del usuario, sus solicitudes de catálogo y sus publicaciones de Marketplace con las imágenes. La pantalla solicita confirmación porque la eliminación no se puede deshacer. Publica la función y la página cuando actualices el proyecto:

```sh
firebase deploy --only functions,hosting --project zap2026-382a1
```

Agrega la URL de eliminación de cuenta en la sección **Seguridad de los datos** de Play Console. La página web permite iniciar sesión con correo y contraseña o Google antes de solicitar el borrado.

La política de privacidad pública está en `https://zap2026-382a1.web.app/privacy-policy.html`. Despliega Hosting antes de enviar la app y confirma que `zap2026-382a1.web.app` esté autorizado en **Firebase Authentication > Settings > Authorized domains** para el inicio de sesión web. Agrega la URL de la política en Play Console y revisa que sus declaraciones coincidan con el uso real de datos de la app.
