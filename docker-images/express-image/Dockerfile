# Create image
# docker build -t res/express_locations .

# Run container
# docker run -p 9090:3000 res/express_students

# Interactif
# docker run -it res/express_locations /bin/bash

FROM node:4.4

RUN apt-get update && \
 apt-get install -y vim

COPY src /opt/app

WORKDIR /opt/app/
RUN npm install

CMD ["node", "/opt/app/index.js"]

