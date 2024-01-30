FROM ubuntu:22.04

RUN apt-get update -y && \
    apt-get install -y capnproto cmake curl g++ gettext git libc6-dev libcapnp-dev libcurl4-gnutls-dev libfreetype6-dev libgl1-mesa-dev libgmp-dev libjpeg-dev libjsoncpp-dev libluajit-5.1-dev libogg-dev libopenal-dev libpng-dev libsdl2-dev libsqlite3-dev libvorbis-dev libxi-dev libzmq3-dev libzstd-dev mold ninja-build xvfb zlib1g-dev

ENV CONDA_DIR /opt/conda
ENV PATH "${CONDA_DIR}/bin:${PATH}"
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ${HOME}/.bashrc \
 && echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/profile \
 && echo "conda activate base" >> ${HOME}/.bashrc \
 && echo "conda activate base" >> /etc/profile

RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    bash Miniforge3-$(uname)-$(uname -m).sh -b -p ${CONDA_DIR} && \
    rm Miniforge3-$(uname)-$(uname -m).sh
