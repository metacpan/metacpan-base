ARG PERL_VERSION=5.36
ARG SLIM_BUILD

FROM perl:${PERL_VERSION} AS build-uwsgi
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

WORKDIR /
RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
<<EOT
    rm -f /etc/apt/apt.conf.d/docker-clean
    apt-get update

    apt-get satisfy -y --no-install-recommends \
      'build-essential (>= 12.9)' \
      'libcap-dev (>= 1:2.66)' \
      'libpcre3-dev (>= 2:8.39)' \
      'uwsgi-core (>= 2.0.21)' \
      'uwsgi-src (>= 2.0.21)'

    /usr/bin/uwsgi --build-plugin "/usr/src/uwsgi/plugins/psgi"
    /usr/bin/uwsgi --build-plugin "https://github.com/DataDog/uwsgi-dogstatsd"
EOT

FROM perl:${PERL_VERSION} AS build-perl
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

WORKDIR /metacpan
COPY cpanfile cpanfile.snapshot /metacpan/

# cpm needs Carton::Snapshot to read cpanfile.snapshot
# Carton::Snapshot has no version, but it's packaged with Carton, which does
RUN \
  --mount=type=cache,target=/root/.cpm,sharing=locked \
<<EOT
    cpm install -g --show-build-log-on-failure \
      Carton~'>= 1.0.35'
    cpm install -g --show-build-log-on-failure
EOT

FROM perl:${PERL_VERSION}${SLIM_BUILD:+-slim}
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
<<EOT
    useradd -m metacpan -g users

    rm -f /etc/apt/apt.conf.d/docker-clean
    apt-get update
    apt-get satisfy -y --no-install-recommends \
      'uwsgi-core (>= 2.0.21)' \
      'inotify-tools (>= 3.22.6.0)' \
      'dumb-init (>= 1.2.5)'
EOT

COPY --from=build-uwsgi /psgi_plugin.so /dogstatsd_plugin.so /usr/lib/uwsgi/plugins/
COPY --from=build-perl /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build-perl /usr/local/bin /usr/local/bin
COPY watcher.sh uwsgi.sh wait-for-it.sh /
COPY uwsgi.ini /etc/uwsgi.ini
