ARG PERL_VERSION=5.36

FROM perl:${PERL_VERSION} AS build-uwsgi

WORKDIR /
RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=private \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=private \
<<EOT /bin/bash -euo pipefail
    apt-get update
    apt-get install -y build-essential libcap-dev libpcre3-dev uwsgi-core uwsgi-src
    /usr/bin/uwsgi --build-plugin "/usr/src/uwsgi/plugins/psgi"
EOT

FROM perl:${PERL_VERSION} AS build-perl

WORKDIR /metacpan
COPY cpanfile cpanfile.snapshot /metacpan/

# cpm needs Carton::Snapshot to read cpanfile.snapshot
RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=private \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=private \
<<EOT /bin/bash -euo pipefail
    cpm install -g Carton::Snapshot
    cpm install -g
EOT

FROM perl:${PERL_VERSION}

RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
<<EOT /bin/bash -euo pipefail
    apt-get update
    apt-get install -y uwsgi-core
EOT

COPY --from=build-uwsgi psgi_plugin.so /usr/lib/uwsgi/plugins/psgi_plugin.so
COPY --from=build-perl /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build-perl /usr/local/bin /usr/local/bin
COPY wait-for-it.sh /
