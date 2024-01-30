ARG BACKEND_URL="localhost:3000"
FROM nginx:latest
EXPOSE 80
WORKDIR /usr/share/nginx/html
COPY index.html .
RUN sed -i "s/localhost:3000/${BACKEND_URL}/g" index.html
CMD ["nginx", "-g", "daemon off;"]
