ARG PERL_VERSION=5.36
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
COPY --from=build-perl /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build-perl /usr/local/bin /usr/local/bin
COPY wait-for-it.sh /
