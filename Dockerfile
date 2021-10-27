###
### Fist Stage - Building the Release
###
FROM hexpm/elixir:1.12.1-erlang-24.0.1-alpine-3.13.3 AS build

# install build dependencies
RUN apk add --no-cache build-base npm

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

RUN mix deps.get --only prod && \
    mix deps.compile

# install npm dependencies
WORKDIR /app/apps/gamenite_web
RUN MIX_ENV=prod mix compile
COPY apps/gamenite_web/assets/package.json apps/gamenite_web/assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY apps/gamenite_web/assets /app/apps/gamenite_web/assets

COPY apps/gamenite_web/priv /app/apps/gamenite_web/priv
COPY apps/gamenite_persistance/priv /app/apps/gamenite_persistance/priv

# NOTE: If using TailwindCSS, it uses a special "purge" step and that requires
# the code in `lib` to see what is being used. Uncomment that here before
# running the npm deploy script if that's the case.
COPY apps/gamenite/lib /app/apps/gamenite/lib
COPY apps/gamenite_web/lib /app/apps/gamenite_web/lib
COPY apps/gamenite_persistance/lib /app/apps/gamenite_persistance/lib

# build assets
WORKDIR /app/apps/gamenite_web
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
WORKDIR /app
COPY rel rel
RUN mix do compile, release

###
### Second Stage - Setup the Runtime Environment
###

# prepare release docker image
FROM alpine:3.13.3 AS app
RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/gamenite ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey
ENV PORT=4000

CMD ["bin/gamenite", "start"]