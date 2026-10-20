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

No se puede asignar el rol desde la app: las reglas bloquean escrituras en `admins`. Los administradores pueden crear fichas desde **Agregar negocio**; se guardan automáticamente en Firestore con estado pendiente. Desde el panel pueden aprobar/rechazar solicitudes, modificar fichas y subir imágenes. El público solo puede leer negocios aprobados.

Las solicitudes de usuarios también se guardan en Firestore y aparecen en la pestaña **Pendientes** para revisión. Al registrar un negocio se selecciona un municipio y categoría disponibles; si falta una opción, se puede proponer desde el formulario. Las propuestas quedan pendientes en **Catálogos**, junto al negocio que las originó, y solo se incorporan al catálogo cuando un administrador las aprueba. Las propuestas de municipios se validan contra la lista oficial de Michoacán. Al registrar un negocio se pueden seleccionar un logo y al menos tres fotos para su carrusel; el logo es opcional y, si no se carga, se usa la ilustración de categoría. Los archivos se guardan en Firebase Storage. Solo el propietario de una ficha pendiente puede subir sus imágenes; el administrador puede cambiar logo, fotos y datos. Para proteger la publicación, una ficha nueva no se puede aprobar hasta que tenga tres fotos.

El panel también permite editar, agregar y ocultar eventos del carrusel por municipio, con imagen opcional y enlace de referencia. Los eventos existentes se conservan como contenido base y se pueden sobrescribir u ocultar. En **Bloqueos**, el administrador puede bloquear/desbloquear negocios (se ocultan del directorio) y usuarios (se suspende el uso de la app). Vuelve a desplegar `firestore.rules` y `storage.rules` después de cualquier cambio en esos archivos. Las reglas de Firestore incluyen lecturas públicas de catálogos, altas de propuestas ligadas al negocio enviado y escrituras administrativas para su aprobación.

Si las reglas ya se desplegaron antes de habilitar la carga de imágenes por propietarios, vuelve a publicarlas después de actualizar el código:

```sh
firebase deploy --only firestore:rules,storage --project zap2026-382a1
```

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
