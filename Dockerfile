FROM dlang2/dmd-ubuntu:2.096.1

RUN apt-get update && \
    apt-get install -y libssl-dev libscrypt-dev patch git && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /app

RUN git config --global --add safe.directory /app

ENTRYPOINT dub run
