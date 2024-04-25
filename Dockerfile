ARG PERL_VERSION=5.36

FROM perl:${PERL_VERSION} AS build-uwsgi
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

WORKDIR /
RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
<<EOT
    rm -f /etc/apt/apt.conf.d/docker-clean
    apt-get update
    apt-get install -y build-essential libcap-dev libpcre3-dev uwsgi-core uwsgi-src
    /usr/bin/uwsgi --build-plugin "/usr/src/uwsgi/plugins/psgi"
EOT

FROM perl:${PERL_VERSION} AS build-perl
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

WORKDIR /metacpan
COPY cpanfile cpanfile.snapshot /metacpan/

# cpm needs Carton::Snapshot to read cpanfile.snapshot
RUN \
  --mount=type=cache,target=/root/.cpm,sharing=locked \
<<EOT
    cpm install -g Carton::Snapshot
    cpm install -g
EOT

FROM perl:${PERL_VERSION}
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
<<EOT
    useradd -m metacpan -g users

    rm -f /etc/apt/apt.conf.d/docker-clean
    apt-get update
    apt-get install -y uwsgi-core
EOT

COPY --from=build-uwsgi psgi_plugin.so /usr/lib/uwsgi/plugins/psgi_plugin.so
COPY --from=build-perl /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build-perl /usr/local/bin /usr/local/bin
COPY wait-for-it.sh /
