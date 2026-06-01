FROM nginx:1.25-alpine

# Eliminar configuración por defecto
RUN rm /etc/nginx/conf.d/default.conf

# Copiar configuraciones personalizadas
COPY nginx.conf /etc/nginx/nginx.conf
COPY drupal.conf /etc/nginx/conf.d/drupal.conf.template

# Script de entrada para variables de entorno
RUN apk add --no-cache gettext

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]