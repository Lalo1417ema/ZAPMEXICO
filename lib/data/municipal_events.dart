import 'package:flutter/material.dart';

import '../presentation/widgets/municipal_events_carousel.dart';

// Programas fechados de ediciones anteriores conservan su año para no
// presentarse como fechas confirmadas para futuras ediciones.
const _monarchFestivalUrl =
    'https://cultura.michoacan.gob.mx/convocatorias/programa-xxxii-festival-biocultural-de-la-mariposa-monarca/';

final Map<String, List<MunicipalEvent>> municipalEvents = {
  'Angangueo': const [
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: 'Marzo · programa 2025: 1 al 16',
      description:
          'Actividades culturales en la región durante la temporada de la mariposa.',
      icon: Icons.eco,
      sourceUrl: _monarchFestivalUrl,
    ),
    MunicipalEvent(
      title: 'Fiesta de la Santa Cruz',
      date: '3 de mayo · fecha tradicional',
      description:
          'Celebración con tapetes de aserrín documentada en la guía local.',
      icon: Icons.add,
      sourceUrl: 'https://vivemaravatio.com/angangueo',
    ),
    MunicipalEvent(
      title: 'Día del Minero',
      date: '11 de julio · fecha tradicional',
      description:
          'Fecha conmemorativa registrada entre las festividades locales.',
      icon: Icons.construction,
      sourceUrl: 'https://vivemaravatio.com/angangueo',
    ),
    MunicipalEvent(
      title: 'Fiesta patronal de San Simón',
      date: '28 de octubre · fecha tradicional',
      description: 'Celebración patronal incluida en la guía de Angangueo.',
      icon: Icons.church,
      sourceUrl: 'https://vivemaravatio.com/angangueo',
    ),
    MunicipalEvent(
      title: 'Fiesta de la Inmaculada Concepción',
      date: '8 de diciembre · fecha tradicional',
      description: 'Festividad local documentada en la guía turística.',
      icon: Icons.celebration,
      sourceUrl: 'https://vivemaravatio.com/angangueo',
    ),
  ],
  'Áporo': const [
    MunicipalEvent(
      title: 'Fiestas y tradiciones de Áporo',
      date: 'Próximas fechas por confirmar',
      description:
          'Consulta los avisos del ayuntamiento para conocer las celebraciones locales.',
      icon: Icons.celebration,
      sourceUrl: 'https://www.aporo.gob.mx/',
    ),
  ],
  'Contepec': const [
    MunicipalEvent(
      title: 'Feria del Tlachiquero en Las Peritas',
      date: '27 y 28 de enero · 8.ª edición, 2024',
      description:
          'Feria con gastronomía, productos del pulque, actividades culturales y cabalgata.',
      icon: Icons.local_drink,
      sourceUrl:
          'https://vivemaravatio.com/invitan-a-la-8-edicion-de-la-feria-del-tlachiquero-en-las-peritas-contepec',
    ),
    MunicipalEvent(
      title: 'Fiesta patronal de Santiago Apóstol',
      date: '20 al 27 de julio · edición 2025',
      description:
          'La parroquia publicó el programa de su fiesta patronal para 2025.',
      icon: Icons.church,
      sourceUrl:
          'https://www.facebook.com/61575309771830/posts/122126441984843659/',
    ),
  ],
  'Epitacio Huerta': const [
    MunicipalEvent(
      title: 'Reto Cerro Frío',
      date: '14 de septiembre · 4.ª edición, 2025',
      description:
          'Evento de ciclismo de montaña con recorridos de 30 y 50 kilómetros.',
      icon: Icons.directions_bike,
      sourceUrl:
          'https://vivemaravatio.com/mas-de-400-ciclistas-llegara-a-epitacio-huerta-para-reto-deportivo-sectur',
    ),
    MunicipalEvent(
      title: 'Fiestas Patrias',
      date: 'Septiembre · bando solemne 2024: 8 de septiembre',
      description:
          'El ayuntamiento anunció la pega del Bando Solemne para las fiestas patrias.',
      icon: Icons.flag,
      sourceUrl:
          'https://www.epitacio-huerta.gob.mx/prensa/tradicional-pega-de-bando-solemne-epitacio-huerta-michoacan-2024',
    ),
  ],
  'Ciudad Hidalgo': const [
    MunicipalEvent(
      title: 'Feria Regional de Todos los Santos',
      date: '24 de octubre al 9 de noviembre · edición 2025',
      description:
          'Feria regional cultural y gastronómica anunciada para Ciudad Hidalgo.',
      icon: Icons.festival,
      sourceUrl:
          'https://michoacanenlinea.mx/gloria-trevi-pandora-flans-y-emmanuel-encabezan-la-feria-regional-en-ciudad-hidalgo/',
    ),
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: '30 de marzo · inauguración 2025',
      description:
          'El programa estatal anunció actividades del festival en el Jardín Municipal.',
      icon: Icons.eco,
      sourceUrl: _monarchFestivalUrl,
    ),
  ],
  'Irimbo': const [
    MunicipalEvent(
      title: 'Fiesta patronal de San Mateo Apóstol',
      date: '21 de septiembre · edición 2024',
      description:
          'El ayuntamiento publicó la convocatoria para la celebración patronal.',
      icon: Icons.church,
      sourceUrl:
          'https://www.facebook.com/municipiodeirimbo/posts/537883675298841/',
    ),
  ],
  'Juárez': const [
    MunicipalEvent(
      title: 'Recorrido ciclista de arranque de feria',
      date: '26 de abril · publicación municipal 2026',
      description:
          'Recorrido desde la Plaza Principal Benito Juárez hasta Buenavista.',
      icon: Icons.directions_bike,
      sourceUrl:
          'https://juarezmich.gob.mx/prensa/arrancamos-la-fiesta-con-toda-la-energia',
    ),
  ],
  'Jungapeo': const [
    MunicipalEvent(
      title: 'Feria de la Guayaba',
      date: '21 al 29 de marzo · edición 2026',
      description:
          'Programa con actividades culturales, artísticas, cívicas y comerciales.',
      icon: Icons.festival,
      sourceUrl:
          'https://www.feriasenmexico.com.mx/feria-jungapeo-2026-feria-de-la-guayaba/',
    ),
  ],
  'Maravatío': const [
    MunicipalEvent(
      title: 'Expo Feria Maravatío',
      date: '19 al 26 de abril · edición 2026',
      description:
          'Cartelera de feria presentada en el marco del 486 aniversario municipal.',
      icon: Icons.festival,
      sourceUrl:
          'https://vivemaravatio.com/todo-listo-para-la-expo-feria-maravatio-2026/',
    ),
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: '22 y 23 de marzo · programa 2025',
      description:
          'La cartelera estatal incluyó actividades en el Jardín Melchor Ocampo.',
      icon: Icons.eco,
      sourceUrl: _monarchFestivalUrl,
    ),
  ],
  'Ocampo': const [
    MunicipalEvent(
      title: 'Feria Ocampo',
      date: '3 al 12 de enero · edición 2026',
      description:
          'Programa artístico publicado para la feria municipal de Ocampo.',
      icon: Icons.festival,
      sourceUrl:
          'https://www.feriasenmexico.com.mx/feria-ocampo-michoacan-2026/',
    ),
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: '1 de marzo · inauguración 2025',
      description:
          'Ocampo fue sede de la inauguración de la edición 2025 del festival.',
      icon: Icons.eco,
      sourceUrl: _monarchFestivalUrl,
    ),
  ],
  'Senguio': const [
    MunicipalEvent(
      title: 'Expo Feria del Hongo',
      date: '21 al 23 de agosto · XXIX edición, 2026',
      description:
          'Encuentro de micoturismo con expositores, conferencias y actividades culturales.',
      icon: Icons.forest,
      sourceUrl:
          'https://nuevo.moreliainformativo.com/senguio-celebra-la-riqueza-de-sus-bosques-con-la-expo-feria-del-hongo-2026/',
    ),
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: '30 de marzo · clausura 2025',
      description:
          'El programa estatal anunció la clausura del festival en Senguio.',
      icon: Icons.eco,
      sourceUrl: _monarchFestivalUrl,
    ),
  ],
  'Susupuato': const [
    MunicipalEvent(
      title: 'Fiesta de San José',
      date: '19 de marzo',
      description: 'Celebración tradicional registrada por el ayuntamiento.',
      icon: Icons.church,
      sourceUrl:
          'https://www.susupuato.gob.mx/tu-municipio/atractivos-turisticos',
    ),
    MunicipalEvent(
      title: 'Fiesta de San Miguel Arcángel',
      date: '29 de septiembre',
      description: 'Fecha tradicional publicada en el portal municipal.',
      icon: Icons.celebration,
      sourceUrl:
          'https://www.susupuato.gob.mx/tu-municipio/atractivos-turisticos',
    ),
  ],
  'Tlalpujahua': const [
    MunicipalEvent(
      title: 'Feria de la Esfera',
      date: '7 de octubre al 15 de diciembre · edición 2026',
      description:
          'Feria de artesanías y esferas; la agenda de actividades se anunciará después.',
      icon: Icons.auto_awesome,
      sourceUrl:
          'https://www.eluniversal.com.mx/destinos/cuando-es-la-feria-de-la-esfera-en-tlalpujahua-y-chignahuapan/',
    ),
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: 'Marzo · programa 2025',
      description:
          'El municipio formó parte de la cartelera regional del festival.',
      icon: Icons.eco,
      sourceUrl: _monarchFestivalUrl,
    ),
  ],
  'Tuxpan': const [
    MunicipalEvent(
      title: 'Fiesta de Santiago Apóstol',
      date: '25 de julio · fecha tradicional (año no indicado)',
      description:
          'El portal cultural local la describe como la fiesta más importante del municipio.',
      icon: Icons.church,
      sourceUrl:
          'http://mituxpan.com/index.php?option=com_content&view=article&id=75&Itemid=84',
    ),
    MunicipalEvent(
      title: 'Feria del Carnaval de Tuxpan',
      date: '4 al 13 de marzo · edición histórica 2011',
      description:
          'Cartelera histórica documentada por el portal cultural local; no representa una fecha futura.',
      icon: Icons.celebration,
      sourceUrl:
          'http://mituxpan.com/index.php?option=com_content&view=article&id=75&Itemid=84',
    ),
    MunicipalEvent(
      title: 'Festival Biocultural de la Mariposa Monarca',
      date: 'Marzo · cartelera 2023',
      description:
          'La Secretaría de Cultura incluyó actividades en Tuxpan en esa edición.',
      icon: Icons.eco,
      sourceUrl:
          'https://cultura.michoacan.gob.mx/noticias/programa-xxx-festival-biocultural-de-la-mariposa-monarca/',
    ),
  ],
  'Tuzantla': const [
    MunicipalEvent(
      title: 'Expo Feria Tuzantla · Fiestas de Pascua',
      date: '5 al 12 de abril · edición 2026',
      description:
          'Programa de feria con actividades artísticas, populares y comerciales.',
      icon: Icons.festival,
      sourceUrl: 'https://www.feriasenmexico.com.mx/feria-tuzantla-2026/',
    ),
  ],
  'Tiquicheo': const [
    MunicipalEvent(
      title: 'Aniversario de elevación a municipio',
      date: '12 de marzo · conmemoración 2023',
      description:
          'Desfile conmemorativo seguido de un acto sociocultural y baile.',
      icon: Icons.flag,
      sourceUrl:
          'https://sigloveinte.mx/encabeza-catalina-perez-negron-el-desfile-por-el-cxvi-aniversario-de-elevacion-a-rango-de-municipio-de-tiquicheo/',
    ),
  ],
  'Zinapécuaro': const [
    MunicipalEvent(
      title: 'Agenda de fiestas y eventos',
      date: 'Fechas por confirmar',
      description:
          'Consulta los avisos municipales para conocer las próximas actividades.',
      icon: Icons.event,
    ),
  ],
  'Zitácuaro': const [
    MunicipalEvent(
      title: 'Feria Expo Monarca',
      date: '2 al 17 de febrero · edición 2025',
      description:
          'Feria anunciada por el gobierno municipal para esa edición.',
      icon: Icons.festival,
      sourceUrl:
          'https://laregionenlinea.com.mx/zitacuaro-del-2-al-17-de-febrero-la-feria-expo-monarca-en-la-ciudad/',
    ),
  ],
};
