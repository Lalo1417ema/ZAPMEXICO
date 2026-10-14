# Zap México

Aplicación Flutter con un directorio local de negocios. No requiere Firebase ni conexión a internet para consultar el catálogo.

El catálogo contiene negocios nombrados en OpenStreetMap y en directorios/perfiles públicos de negocios. Los datos de OpenStreetMap se distribuyen bajo ODbL 1.0; se incluye el enlace a la fuente por ficha y los datos pueden estar desactualizados. Las direcciones, teléfonos y horarios solo se muestran cuando la fuente los publica. No se inventan calificaciones: las fichas importadas comienzan con cero reseñas y sin puntuación.

El directorio se enfoca en Ciudad Hidalgo y Senguio. Sus categorías se limitan a las que tienen al menos un negocio publicado: Mecánica, Salud, Restaurantes, Hoteles, Ferretería, Abarrotes, Tecnología, Turismo, Comercio y Productores locales. Las categorías vacías se retiran del selector y pueden agregarse cuando se documente un negocio que las necesite.

Para mostrar una ficha de negocio, la fuente debe publicar al menos dos de estos tres datos requeridos: dirección, teléfono y horario. Los atractivos turísticos no siempre publican teléfono u horario; esas fichas requieren ubicación y fuente pública verificable y muestran únicamente los datos confirmados. Senguihongo se incluye con solo la dirección por solicitud expresa; la ficha no completa ni inventa teléfono u horario.

Las fichas de otros municipios se excluyen del catálogo. La cobertura en Ciudad Hidalgo y Senguio es desigual y el directorio no pretende incluir todos los establecimientos. Se añaden enlaces de redes sociales solo cuando se puede identificar una cuenta pública del negocio.

Las tarjetas y detalles usan una imagen ilustrativa de categoría, nunca una foto atribuida al establecimiento. Son recursos locales con licencias reutilizables; sus atribuciones están en [ATTRIBUTIONS.txt](assets/images/business_categories/ATTRIBUTIONS.txt). Cada ficha indica en su descripción que la imagen es ilustrativa. Las altas de usuarios también usan esa ilustración mientras esperan aprobación.

Datos © [colaboradores de OpenStreetMap](https://www.openstreetmap.org/copyright), disponibles bajo ODbL 1.0. Algunas fichas adicionales se basan en directorios públicos de [Ciudad Hidalgo](https://www.cdhidalgo.com/servicios), resultados públicos de negocios y páginas públicas de Facebook; los enlaces se guardan como fuentes para consulta.

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
