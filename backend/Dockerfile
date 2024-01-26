FROM node AS base
WORKDIR /usr/src/app
COPY index.js .

FROM base AS install
RUN npm install express cors mongoose

FROM base AS release
EXPOSE 3000
COPY --from=install /usr/src/app/node_modules ./node_modules
CMD ["node", "index.js"]
