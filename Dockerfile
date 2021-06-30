FROM debian:buster-slim
MAINTAINER Michael Aschauer <m@ash.to>

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install \
  wget \
  lua5.1 luarocks \
  postgresql postgresql-client \
  libpcre3-dev \
  libssl-dev \
  perl make build-essential curl

RUN apt-get -y install --no-install-recommends wget gnupg ca-certificates
RUN wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN echo "deb http://openresty.org/package/debian buster openresty" \
    | tee /etc/apt/sources.list.d/openresty.list
RUN apt-get update
RUN apt-get -y install openresty
    
#WORKDIR /usr/local/src
#RUN wget https://openresty.org/download/openresty-1.19.3.2.tar.gz && \
#  tar xfv openresty-1.19.3.2.tar.gz  && \
#  cd openresty-1.19.3.2  && \ 
#  ./configure -j2 && \
#  make -j2 && make install

RUN luarocks install lapis
RUN luarocks install xml
RUN luarocks install bcrypt 
RUN luarocks install luaposix 
RUN luarocks install luasec 
RUN luarocks install md5

WORKDIR /app

#don't copy app code and data for now
#COPY . .

EXPOSE 8000 80
CMD lapis server production
