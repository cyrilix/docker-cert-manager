FROM --platform=$BUILDPLATFORM golang:1.15-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG version="v1.0.4"


WORKDIR /opt

RUN apk add -U git
RUN git clone https://github.com/jetstack/cert-manager.git
WORKDIR /opt/cert-manager
RUN git checkout ${version}

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build ./cmd/acmesolver/ && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build ./cmd/cainjector/ && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build ./cmd/controller/ && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build ./cmd/webhook/





FROM gcr.io/distroless/static AS acmesolver

COPY --from=builder /opt/cert-manager/acmesolver /bin/acmesolver

USER 1234

ENTRYPOINT ["/bin/acmesolver"]



FROM gcr.io/distroless/static AS cainjector

COPY --from=builder /opt/cert-manager/cainjector /bin/cainjector

USER 1234

ENTRYPOINT ["/bin/cainjector"]



FROM gcr.io/distroless/static AS controller

COPY --from=builder /opt/cert-manager/controller /bin/controller

USER 1234

ENTRYPOINT ["/bin/controller"]




FROM gcr.io/distroless/static AS webhook

COPY --from=builder /opt/cert-manager/webhook /bin/webhook

USER 1234

ENTRYPOINT ["/bin/webhook"]
