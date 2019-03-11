FROM alpine:3.7
EXPOSE 8545
EXPOSE 30303
EXPOSE 30303/udp
COPY . /cliquebait
CMD "/cliquebait/run.bash"
ARG GETH_VERSION
ENV GETH_VERSION=$GETH_VERSION
RUN \
  apk add --update bash git go make gcc musl-dev linux-headers curl jq       && \
  git clone --branch $GETH_VERSION https://github.com/ethereum/go-ethereum   && \
  (cd go-ethereum && make geth)                                              && \
  cp go-ethereum/build/bin/geth /usr/local/bin/                              && \
  (cd go-ethereum && build/env.sh go run build/ci.go install ./cmd/bootnode) && \
  cp go-ethereum/build/bin/bootnode /usr/local/bin/                          && \
  apk del git go make gcc musl-dev linux-headers                             && \
  rm -rf /go-ethereum && rm -rf /var/cache/apk/*

