FROM node AS base
ARG DATABASE_URL="my-mongodb:27017"
WORKDIR /usr/src/app
COPY index.js .
RUN sed -i "s/my-mongodb:27017/$DATABASE_URL/g" index.js

FROM base AS install
RUN npm install express cors mongoose

FROM base AS release
EXPOSE 3000
COPY --from=install /usr/src/app/node_modules ./node_modules
CMD ["node", "index.js"]
