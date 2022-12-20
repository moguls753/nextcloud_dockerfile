FROM php:8.1-apache-bullseye AS bz2-builder

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions bz2

FROM nextcloud:apache as builder

# Build and install dlib on builder

RUN apt-get update ; \
    apt-get install -y build-essential wget cmake libx11-dev libopenblas-dev git liblapack-dev

RUN git clone https://github.com/davisking/dlib.git \
    && cd dlib/dlib \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make \
    && make install

# Build and install PDLib on builder

RUN git clone https://github.com/goodspb/pdlib.git \
    && cd pdlib \
    && phpize \
    && cat configure | sed 's/std=c++11/std=c++14/g' > configure_new \
    && chmod +x configure_new \
    && ./configure_new --enable-debug \
    && make \
    && make install

# Enable PDlib on builder

RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini

FROM nextcloud:apache

# Install dependencies to image

RUN apt-get update ; \
    apt-get install -y libopenblas-base vim ffmpeg ghostscript imagemagick

# Install dlib and PDlib to image

COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/

# If is necesary take the php extention folder uncommenting the next line
# RUN php -i | grep extension_dir
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20210902/pdlib.so /usr/local/lib/php/extensions/no-debug-non-zts-20210902/
COPY --from=bz2-builder /usr/local/lib/php/extensions/no-debug-non-zts-20210902/bz2.so /usr/local/lib/php/extensions/no-debug-non-zts-20210902/

# Enable PDlib on final image

RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini
RUN echo "extension=bz2.so" > /usr/local/etc/php/conf.d/bz2.ini

# Increse memory limits

RUN echo memory_limit=2048M > /usr/local/etc/php/conf.d/memory-limit.ini
RUN rm /usr/local/etc/php/conf.d/nextcloud.ini
RUN echo memory_limit=2048M > /usr/local/etc/php/conf.d/nextcloud.ini
RUN echo upload_max_filesize=16G >> /usr/local/etc/php/conf.d/nextcloud.ini
RUN echo post_max_size=16G >> /usr/local/etc/php/conf.d/nextcloud.ini

# At this point you meet all the dependencies to install the application
# If is available you can skip this step and install the application from the application store

RUN apt-get install -y wget unzip nodejs npm
RUN git clone https://github.com/matiasdelellis/facerecognition.git \
  && mv facerecognition /usr/src/nextcloud/custom_apps/ \
  && cd /usr/src/nextcloud/custom_apps/facerecognition \
  && mv webpack.common.js webpack.common.js.backup \
  && sed '44d' webpack.common.js.backup > webpack.common.js \
  && make
