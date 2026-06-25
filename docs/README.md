DOCUMENTACION DE RELEVAMIENTO Y ACTUALIZACION DE SITIO GIDAS
Ya habiendo arreglado el build total del proyecto, este commit del 22/6 está hecho para preservar la version funcional del build con algunas cosas actualizadas y el proyecto deployado. Ahora toca analizar la migracion/actualizacion del sistema
Mayormente se recomienda migrar a wordpress debido a que ya contamos con todo lo suficiente como el trio de contenedores suficientes para usar wordpress (mariadb, nginx y php)
Las actualizaciones de Drupal junto a la actualizacion de php que tambien es importante va a llevar a muchas inconsistencias y poca actualizacion y mantenibilidad a futuro
Active el modulo de UPGRADE STATUS de DRUPAL para poder hacer un analisis del lado de drupal, y documente todo el plan que seria de o actualizar el Drupal o de migrar a Wordpress, lo que sea necesario y mas optimo.
Verificque las dependencias y hay algunas que hay que cambiar para la actualizacion a Drupal 10
