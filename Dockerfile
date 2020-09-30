FROM ocaml/opam2:alpine
WORKDIR /home/opam/project
RUN opam update
RUN sudo apk add m4 linux-headers gmp-dev perl
RUN opam depext ssl
RUN opam install ssl alcotest
COPY twostep.opam ./
RUN opam update
RUN opam install --deps-only .
COPY ./ ./
RUN sudo chmod a+rw -R ./
RUN eval $(opam env) && make test
RUN eval $(opam env) && make binary

FROM alpine
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="twostep" \
  org.label-schema.description="HOTP and TOTP algorithms for 2-step verification (for OCaml)." \
  org.label-schema.url="https://marcoonroad.dev/twostep" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/marcoonroad/twostep" \
  org.label-schema.vendor="Marco Aurélio da Silva (marcoonroad)" \
  org.label-schema.version=$VERSION \
  org.label-schema.schema-version="1.0"
COPY --from=0 /home/opam/project/twostep.exe /usr/bin/twostep
RUN chmod a+rx /usr/bin/twostep
ENTRYPOINT ["/usr/bin/twostep"]
