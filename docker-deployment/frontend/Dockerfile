FROM nginx:latest
ARG BACKEND_URL="79.114.22.104:3001"
EXPOSE 80
WORKDIR /usr/share/nginx/html
COPY index.html .
RUN sed -i "s/79.114.22.104:3001/${BACKEND_URL}/g" index.html
CMD ["nginx", "-g", "daemon off;"]
