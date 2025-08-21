FROM debian:trixie-slim AS dependencies

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ccache \
    clang-19 \
    cmake \
    ninja-build \
    git \
    wget \
    ca-certificates \
    libssl-dev \
    libsdl2-dev \
    && ln -s /usr/bin/clang-19 /usr/bin/clang \
    && ln -s /usr/bin/clang++-19 /usr/bin/clang++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV CCACHE_DIR=/ccache
ENV CCACHE_COMPILERCHECK=content
ENV CCACHE_SLOPPINESS=time_macros
RUN mkdir -p $CCACHE_DIR

FROM dependencies AS builder

WORKDIR /build

COPY . . 

WORKDIR /build/build

RUN cmake .. -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DENABLE_QT=OFF \
    -DENABLE_SDL2=OFF \
    -DENABLE_ROOM_STANDALONE=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DENABLE_FFMPEG_VIDEO_DUMPER=OFF \
    -DCITRA_USE_PRECOMPILED_HEADERS=OFF \
    -DCITRA_WARNINGS_AS_ERRORS=OFF

RUN ninja citra_room_standalone

RUN strip -s bin/Release/azahar-room

RUN mkdir /azahar && chown 2048 /azahar

FROM gcr.io/distroless/static-debian12

ENV AZAHAR_PORT=24872
ENV AZAHAR_ROOMNAME="Azahar Room"
ENV AZAHAR_MAXMEMBERS=4
ENV AZAHAR_ROOMDESC=""
ENV AZAHAR_PREFAPP=""
ENV AZAHAR_PREFAPPID="0"
ENV AZAHAR_PASSWORD=""
ENV AZAHAR_ISPUBLIC=0
ENV AZAHAR_USERNAME="azahar"
ENV AZAHAR_TOKEN=""
ENV AZAHAR_WEBAPIURL=""
ENV AZAHAR_BANLISTFILE="bannedlist.cbl"
ENV AZAHAR_LOGFILE="azahar-room.log"

COPY --from=builder --chmod=755 /build/build/bin/Release/azahar-room /azahar-room
COPY --from=builder --chmod=755 /azahar /azahar

USER 2048
WORKDIR /azahar

EXPOSE $AZAHAR_PORT/udp

ENTRYPOINT ["/azahar-room"]