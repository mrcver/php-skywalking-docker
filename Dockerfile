FROM php:7.3-cli-buster

ENV GRPC_RELEASE_TAG v1.31.x
ENV PROTOBUF_RELEASE_TAG 3.13.x

RUN set -ex; \
    apt-get update; \
	apt-get -y install git libfreetype6-dev libjpeg62-turbo-dev libpng-dev libcurl4-openssl-dev libcurl4 libzip4 libzip-dev procps net-tools libboost-dev ca-certificates autoconf automake libtool g++ make file re2c pkgconf openssl libssl-dev curl; \
	docker-php-source extract && \
	echo "==== download exts ===" && \
	mkdir -p /var/local/git && cd /var/local/git && \
	curl -fL http://pecl.php.net/get/inotify-2.0.0.tgz -o inotify.tgz && \
	curl -fL http://pecl.php.net/get/redis-4.2.0.tgz -o redis.tgz && \
	curl -fL http://pecl.php.net/get/swoole-4.2.3.tgz -o swoole.tgz && \
	curl -fL https://github.com/SkyAPM/SkyAPM-php-sdk/archive/master.tar.gz -o skywalking.tar.gz && \
	curl -fL https://github.com/wataly/phptars/archive/master.tar.gz -o phptars.tar.gz && \
	echo "==== unzip exts ===" && \
	mkdir -p /usr/src/php/ext/inotify && \
    mkdir -p /usr/src/php/ext/redis && \
    mkdir -p /usr/src/php/ext/skywalking && \
    mkdir -p /usr/src/php/ext/swoole && \
    mkdir -p /usr/src/php/ext/phptars && \
	tar xvf inotify.tgz --strip-components=1 -C /usr/src/php/ext/inotify && \
	tar xvf redis.tgz --strip-components=1 -C /usr/src/php/ext/redis && \
	tar xvf swoole.tgz --strip-components=1 -C /usr/src/php/ext/swoole && \
	tar xvf skywalking.tar.gz --strip-components=1 -C /usr/src/php/ext/skywalking && \
	tar xvf phptars.tar.gz --strip-components=1 -C /usr/src/php/ext/phptars && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ && \
	echo "--- exts installing ---" && \
	docker-php-ext-install pdo pdo_mysql curl gd bcmath zip sockets mysqli swoole inotify redis phptars && \
	echo "--- clone grpc ---" && \
	git clone --depth 1 -b ${GRPC_RELEASE_TAG} https://github.com/grpc/grpc /var/local/git/grpc && \
	cd /var/local/git/grpc && \
	git submodule update --init --recursive && \
	echo "--- download cmake ---" && \
	cd /var/local/git && \
	curl -L -o cmake-3.19.1.tar.gz  https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1.tar.gz && \
	tar zxf cmake-3.19.1.tar.gz && \
	cd cmake-3.19.1 && ./bootstrap && make -j$(nproc) && make install && \
	echo "--- installing grpc ---" && \
	cd /var/local/git/grpc && \
	mkdir -p cmake/build && cd cmake/build && cmake ../.. && make -j$(nproc) && \
	echo "--- installing skywalking php ---" && \
	cd /usr/src/php/ext/skywalking && phpize && ./configure --with-grpc=/var/local/git/grpc && make && make install && \
	cp php.ini $PHP_INI_DIR/conf.d/ext-skywalking.ini
	# echo "--- clean ---" && \
	# apk del .build-deps && \
	# docker-php-source delete && \
	# rm -rf /var/cache/apk/* && \
	# rm -fr /var/local/git && \
	# apk add --no-cache libst&& \dc++ libpng brotli-libs
