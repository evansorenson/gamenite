###
### Fist Stage - Building the Release
###
ARG BUILDER_IMAGE="hexpm/elixir:1.12.3-erlang-24.1.4-debian-bullseye-20210902-slim"
ARG RUNNER_IMAGE="debian:bullseye-20210902-slim"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
RUN apt-get update -y && \
    apt-get install -y \
    build-essential \
    git \
    nodejs \
    npm \
    yarn \
    python3 \
    make \
    cmake \
    openssl \ 
    libssl-dev \
    libsrtp2-dev \
    libnice-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libopus-dev \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# extend hex timeout
ENV HEX_HTTP_TIMEOUT=20

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV as prod
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey

# Copy over the mix.exs and mix.lock files to load the dependencies. If those
# files don't change, then we don't keep re-fetching and rebuilding the deps.
COPY mix.exs mix.lock ./
COPY config config

COPY apps/gamenite/mix.exs /app/apps/gamenite/
COPY apps/gamenite_web/mix.exs /app/apps/gamenite_web/
COPY apps/gamenite_persistance/mix.exs /app/apps/gamenite_persistance/
COPY apps/rooms/mix.exs /app/apps/rooms/

# NOTE: If using TailwindCSS, it uses a special "purge" step and that requires
# the code in `lib` to see what is being used.
COPY apps/gamenite/lib /app/apps/gamenite/lib
COPY apps/gamenite_web/lib /app/apps/gamenite_web/lib
COPY apps/gamenite_persistance/lib /app/apps/gamenite_persistance/lib
COPY apps/rooms/lib /app/apps/rooms/lib

COPY apps/gamenite_web/priv /app/apps/gamenite_web/priv
COPY apps/gamenite_persistance/priv /app/apps/gamenite_persistance/priv

RUN mix deps.get --only prod && \ 
    mix deps.compile

# build assets
WORKDIR /app/apps/gamenite_web
RUN MIX_ENV=prod mix compile
COPY apps/gamenite_web/assets ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN mix assets.deploy

# compile and build release
WORKDIR /app
COPY rel rel
RUN mix do compile, release

###
### Second Stage - Setup the Runtime Environment
###

# prepare release docker image
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y \
    libstdc++6 \
    openssl \
    libncurses5 \
    locales \
    ffmpeg \
    libsrtp2-dev \
    libnice-dev \
    libopus-dev \
    clang \ 
    curl && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*
    
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/gamenite ./

USER nobody

ENV HOME=/app
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey
ENV PORT=4000

CMD ["bin/gamenite", "start"]