FROM alpine as builder

RUN apk --no-cache add --virtual inspectrum-build-dependencies \
    git \
    build-base \
    cmake \
    autoconf \
    automake \
    fftw-dev \
    pkgconfig

RUN apk --no-cache add --virtual inspectrum-edge-build-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    qt5-qtbase-dev

RUN git clone --depth 1 git://github.com/jgaeddert/liquid-dsp /liquid

WORKDIR /liquid

RUN ./bootstrap.sh
RUN ./configure --prefix=/opt/liquid
RUN make
RUN make install

RUN git clone --depth 1 https://github.com/miek/inspectrum.git /inspectrum

RUN mkdir -p /inspectrum/build
WORKDIR /inspectrum/build

RUN cmake \
    -DLIQUID_INCLUDES=/opt/liquid/include \
    -DLIQUID_LIBRARIES=/opt/liquid/lib/libliquid.so \
    -DCMAKE_INSTALL_PREFIX=/opt/inspectrum \
    ..
RUN make
RUN make install

FROM 0x01be/xpra

COPY --from=builder /opt/inspectrum/ /opt/inspectrum/
COPY --from=builder /opt/liquid/ /opt/liquid/

RUN apk --no-cache add --virtual inspectrum-edge-runtime-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    qt5-qtbase \
    qt5-qtbase-x11

RUN apk --no-cache add --virtual inspectrum-runtime-dependencies \
    fftw

ENV PATH $PATH:/opt/inspectrum/bin/

VOLUME /workspace
WORKDIR /workspace

