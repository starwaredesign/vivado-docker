FROM ubuntu:22.04

# based on Dockerfile from Colm Ryan <cryan@bbn.com>
MAINTAINER Matteo Vit <matteo.vit@dev.starwaredesign.com> 

# build with docker build --build-arg VIVADO_TAR_HOST=host:port --build-arg VIVADO_TAR_FILE=Xilinx_Vivado_SDK_2016.3_1011_1 -t vivado .

#install dependences for:
# * downloading Vivado (wget)
# * xsim (gcc build-essential to also get make)
# * MIG tool (libglib2.0-0 libsm6 libxi6 libxrender1 libxrandr2 libfreetype6 libfontconfig)
# * CI (git)
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
  wget \
  build-essential \
  libglib2.0-0 \
  libsm6 \
  libxi6 \
  libxrender1 \
  libxrandr2 \
  libfreetype6 \
  libfontconfig \
  locales \
  git \
  gawk \
  iproute2 \
  python3 \ 
  gcc \
  make \
  net-tools \ 
  libncurses5-dev \
  tftpd \ 
  zlib1g-dev \
  libssl-dev \
  flex \
  bison \ 
  libselinux1 \
  gnupg \
  git-core \ 
  diffstat \
  chrpath \
  socat \
  xterm \ 
  autoconf \
  libtool \
  rsync \
  texinfo \
  gcc-multilib \
  zlib1g:i386 \
  lsb-release \
  libtinfo5 \
  dnsutils \
  bc \
  unzip \
  iverilog 


# copy in config file
COPY install_config.txt /

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# set bash as default shell
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# download and run the install
ARG VIVADO_TAR_HOST
ARG VIVADO_TAR_FILE
ARG VIVADO_VERSION
RUN echo "Downloading ${VIVADO_TAR_FILE} from ${VIVADO_TAR_HOST}" && \
  wget ${VIVADO_TAR_HOST}/${VIVADO_TAR_FILE}.tar.gz -q && \
  echo "Extracting Vivado tar file" && \
  tar xzf ${VIVADO_TAR_FILE}.tar.gz && \
  /${VIVADO_TAR_FILE}/xsetup --agree 3rdPartyEULA,XilinxEULA --batch Install --config install_config.txt && \
  rm -rf ${VIVADO_TAR_FILE}*

# get boards files
RUN wget https://github.com/Xilinx/XilinxBoardStore/archive/refs/heads/${VIVADO_VERSION}.zip && \
  unzip ${VIVADO_VERSION}.zip && \
  cp -a XilinxBoardStore-${VIVADO_VERSION}/boards/* /opt/Xilinx/Vivado/${VIVADO_VERSION}/data/xhub/boards/ && \
  rm -rf ${VIVADO_VERSION}.zip && \ 
  rm -rf XilinxBoardStore-${VIVADO_VERSION}

#make a xilinx user
RUN adduser --disabled-password --gecos '' xilinx 
USER xilinx
WORKDIR /home/xilinx
#add vivado tools to path
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/xilinx/.profile

#copy in the license file
RUN mkdir /home/xilinx/.Xilinx
#COPY Xilinx.lic /home/xilinx/.Xilinx/

ARG PETALINUX_VERSION
# install petalinux
ENV PETALINUX_FILE petalinux-v${VIVADO_VERSION}-${PETALINUX_VERSION}-installer.run
RUN echo "Downloading ${PETALINUX_FILE} from ${VIVADO_TAR_HOST}" && \
  wget ${VIVADO_TAR_HOST}/${PETALINUX_FILE} -q && \
  chmod a+x ${PETALINUX_FILE} && \
  mkdir -p /home/xilinx/petalinux && \
  ./${PETALINUX_FILE} -y --dir /home/xilinx/petalinux/${VIVADO_VERSION} --platform "arm aarch64" && \
  rm -rf ${PETALINUX_FILE}

RUN echo "source /home/xilinx/petalinux/${VIVADO_VERSION}/settings.sh" >> /home/xilinx/.profile

USER root
#add vivado tools to path (root)
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile

#copy in the license file (root)
RUN mkdir -p /root/.Xilinx
#COPY Xilinx.lic /root/.Xilinx/

USER xilinx

# install cocotb
pip install cocotb
pip install cocotb-bus
pip install pytest

