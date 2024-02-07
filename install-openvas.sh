#!/bin/bash

# sudo apt install libxml2-utils

get_latest_release() {
        project=$1
        url="https://github.com/$project/releases.atom"
        feed="$(curl --silent --fail "$url")"
        if [ $? -ne 0 ]; then
                echo "Error fetching feed!" >&2
                continue
        fi

        latest_release="$(echo $feed | xmllint --xpath "//*[local-name()='entry'][1]/*[local-name()='title']/text()" -)"
        if [ $? -ne 0 ]; then
                echo "Error parsing feed!" >&2
                continue
        fi

        latest_release=$(echo $latest_release|tr -dc '.0-9')
        echo $latest_release
}

export ARCH=$(uname -m|sed 's/x86_64/amd64/')

export GVM_LIBS_VERSION=$(get_latest_release "greenbone/gvm-libs")
export GVMD_VERSION=$(get_latest_release "greenbone/gvmd")
export PG_GVM_VERSION=$(get_latest_release "greenbone/pg-gvm")
export GSA_VERSION=$(get_latest_release "greenbone/gsa")
export GSAD_VERSION=$(get_latest_release "greenbone/gsad")
export OPENVAS_SMB_VERSION=$(get_latest_release "greenbone/openvas-smb")
export OPENVAS_SCANNER_VERSION=$(get_latest_release "greenbone/openvas-scanner")
export OSPD_OPENVAS_VERSION=$(get_latest_release "greenbone/ospd-openvas")
export NOTUS_VERSION=$(get_latest_release "greenbone/notus-scanner")
export GREENBONE_FEED_SYNC_VERSION=$(get_latest_release "greenbone/greenbone-feed-sync")
export GVM_TOOLS_VERSION=$(get_latest_release "greenbone/gvm-tools")

echo "GVM_LIBS_VERSION = $GVM_LIBS_VERSION"
echo "GVMD_VERSION = $GVMD_VERSION"
echo "PG_GVM_VERSION = $PG_GVM_VERSION"
echo "GSA_VERSION = $GSA_VERSION"
echo "GSAD_VERSION = $GSAD_VERSION"
echo "OPENVAS_SMB_VERSION = $OPENVAS_SMB_VERSION"
echo "OPENVAS_SCANNER_VERSION = $OPENVAS_SCANNER_VERSION"
echo "OSPD_OPENVAS_VERSION = $OSPD_OPENVAS_VERSION"
echo "NOTUS_VERSION = $NOTUS_VERSION"
echo "GREENBONE_FEED_SYNC_VERSION = $GREENBONE_FEED_SYNC_VERSION"
echo "GVM_TOOLS_VERSION = $GVM_TOOLS_VERSION"

read -n 1 -s -r -p "Press any key to continue"

export GVMUSER=gvm
sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin $GVMUSER
sudo usermod -aG $GVMUSER $USER

# git config --global http.proxy http://10.10.210.4:8080/
# git config --global advice.detachedHead false
# export http_proxy=http://10.10.210.4:8080/
# export https_proxy=http://10.10.210.4:8080/

export SKIP_INSTALL_DEPS=1

export INSTALL_PREFIX=/usr/local
export PATH=$PATH:$INSTALL_PREFIX/sbin
export SOURCE_DIR=$HOME/openvas/source
mkdir -p $SOURCE_DIR
export BUILD_DIR=$HOME/openvas/build
mkdir -p $BUILD_DIR
export INSTALL_DIR=$HOME/openvas/install
mkdir -p $INSTALL_DIR

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt update
sudo apt install --no-install-recommends --assume-yes \
  build-essential \
  curl \
  cmake \
  pkg-config \
  python3 \
  python3-pip \
  gnupg
fi

##
## GVM_LIBS
##
INSTALLED=$(dpkg -s gvm-libs|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$GVM_LIBS_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  libglib2.0-dev \
  libgpgme-dev \
  libgnutls28-dev \
  uuid-dev \
  libssh-gcrypt-dev \
  libhiredis-dev \
  libxml2-dev \
  libpcap-dev \
  libnet1-dev \
  libpaho-mqtt-dev
sudo apt install -y \
  libldap2-dev \
  libradcli-dev
fi

if [ ! -d $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION ]; then
        git clone -b v$GVM_LIBS_VERSION --single-branch https://github.com/greenbone/gvm-libs.git $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION
fi

mkdir -p $BUILD_DIR/gvm-libs && cd $BUILD_DIR/gvm-libs

cmake $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var

make -j$(nproc)

mkdir -p $INSTALL_DIR/gvm-libs

make DESTDIR=$INSTALL_DIR/gvm-libs install

# sudo cp -rv $INSTALL_DIR/gvm-libs/* /
mkdir $INSTALL_DIR/gvm-libs/DEBIAN
cat >$INSTALL_DIR/gvm-libs/DEBIAN/control <<EOF
Package: gvm-libs
Version: $GVM_LIBS_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS gvm-libs
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build gvm-libs
sudo dpkg -i gvm-libs.deb

echo "Installed gvm-libs"
read -n 1 -s -r -p "Press any key to continue"
else
echo "gvm-libs already installed"
fi

##
## gvmd
##
INSTALLED=$(dpkg -s gvmd|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$GVMD_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  libglib2.0-dev \
  libgnutls28-dev \
  libpq-dev \
  postgresql-server-dev-14 \
  libical-dev \
  xsltproc \
  rsync \
  libbsd-dev \
  libgpgme-dev
sudo apt install -y --no-install-recommends \
  texlive-latex-extra \
  texlive-fonts-recommended \
  xmlstarlet \
  zip \
  rpm \
  fakeroot \
  dpkg \
  nsis \
  gnupg \
  gpgsm \
  wget \
  sshpass \
  openssh-client \
  socat \
  snmp \
  python3 \
  smbclient \
  python3-lxml \
  gnutls-bin \
  xml-twig-tools
fi

if [ ! -d $SOURCE_DIR/gvmd-$GVMD_VERSION ]; then
        git clone -b v$GVMD_VERSION --single-branch https://github.com/greenbone/gvmd.git $SOURCE_DIR/gvmd-$GVMD_VERSION
fi

cmake $SOURCE_DIR/gvmd-$GVMD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DLOCALSTATEDIR=/var \
  -DSYSCONFDIR=/etc \
  -DGVM_DATA_DIR=/var \
  -DGVMD_RUN_DIR=/run/gvmd \
  -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
  -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
  -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
  -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

mkdir -p $INSTALL_DIR/gvmd

make DESTDIR=$INSTALL_DIR/gvmd install

# Don't include header and lib files
rm -rf $INSTALL_DIR/gvmd$INSTALL_PREFIX/include
rm -rf $INSTALL_DIR/gvmd$INSTALL_PREFIX/lib

mkdir -p $INSTALL_DIR/gvmd/etc/systemd/system/
cat << EOF > $INSTALL_DIR/gvmd/etc/systemd/system/gvmd.service
[Unit]
Description=Greenbone Vulnerability Manager daemon (gvmd)
After=network.target networking.service postgresql.service ospd-openvas.service
Wants=postgresql.service ospd-openvas.service
Documentation=man:gvmd(8)
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=$GVMUSER
Group=$GVMUSER
PIDFile=/run/gvmd/gvmd.pid
RuntimeDirectory=gvmd
RuntimeDirectoryMode=2775
ExecStart=$INSTALL_PREFIX/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

# sudo cp -rv $INSTALL_DIR/gvmd/* /
mkdir $INSTALL_DIR/gvmd/DEBIAN
cat >$INSTALL_DIR/gvmd/DEBIAN/control <<EOF
Package: gvmd
Version: $GVMD_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS gvmd
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build gvmd
sudo dpkg -i gvmd.deb

echo "Installed gvmd"
read -n 1 -s -r -p "Press any key to continue"
else
echo "gvmd already installed"
fi

##
## pg-gvm
##
INSTALLED=$(dpkg -s pg-gvm|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$PG_GVM_VERSION" ]; then

if [ -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  libglib2.0-dev \
  postgresql-server-dev-14 \
  libical-dev
fi

if [ ! -f $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz ]; then
        curl -f -L https://github.com/greenbone/pg-gvm/archive/refs/tags/v$PG_GVM_VERSION.tar.gz -o $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz
fi

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz

mkdir -p $BUILD_DIR/pg-gvm && cd $BUILD_DIR/pg-gvm

cmake $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION \
  -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)

mkdir -p $INSTALL_DIR/pg-gvm

make DESTDIR=$INSTALL_DIR/pg-gvm install

# Remove conflicting files
# for fn in lib var etc usr/local/bin usr/local/sbin usr/local/share
# do
#       rm -rf $INSTALL_DIR/pg-gvm/$fn
# done

#sudo cp -rv $INSTALL_DIR/pg-gvm/* /
mkdir $INSTALL_DIR/pg-gvm/DEBIAN
cat >$INSTALL_DIR/pg-gvm/DEBIAN/control <<EOF
Package: pg-gvm
Version: $PG_GVM_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS pg-gvm
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build pg-gvm
sudo dpkg -i pg-gvm.deb

echo "Installed pg-gvm"
read -n 1 -s -r -p "Press any key to continue"
else
echo "pg-gvm already installed"
fi

##
## GSA
##
INSTALLED=$(dpkg -s gsa|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$GSA_VERSION" ]; then

if [ ! -f $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz ]; then
        curl -f -L https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz -o $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz
fi

mkdir -p $INSTALL_DIR/gsa$INSTALL_PREFIX/share/gvm/gsad/web/
tar -C $INSTALL_DIR/gsa$INSTALL_PREFIX/share/gvm/gsad/web/ -xvzf $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz

mkdir $INSTALL_DIR/gsa/DEBIAN
cat >$INSTALL_DIR/gsa/DEBIAN/control <<EOF
Package: gsa
Version: $GSA_VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS gsa
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build gsa
sudo dpkg -i gsa.deb

echo "Installed gsa"
read -n 1 -s -r -p "Press any key to continue"
else
echo "gsa already installed"
fi

##
## gsad
##
INSTALLED=$(dpkg -s gsad|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$GSAD_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  libmicrohttpd-dev \
  libxml2-dev \
  libglib2.0-dev \
  libgnutls28-dev
fi

if [ ! -d $SOURCE_DIR/gsad-$GSAD_VERSION ]; then
        git clone -b v$GSAD_VERSION --single-branch https://github.com/greenbone/gsad.git $SOURCE_DIR/gsad-$GSAD_VERSION
fi

mkdir -p $BUILD_DIR/gsad && cd $BUILD_DIR/gsad

cmake $SOURCE_DIR/gsad-$GSAD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DGVMD_RUN_DIR=/run/gvmd \
  -DGSAD_RUN_DIR=/run/gsad \
  -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

mkdir -p $INSTALL_DIR/gsad

make DESTDIR=$INSTALL_DIR/gsad install

mkdir -p $INSTALL_DIR/gsad/etc/systemd/system/
cat << EOF > $INSTALL_DIR/gsad/etc/systemd/system/gsad.service
[Unit]
Description=Greenbone Security Assistant daemon (gsad)
Documentation=man:gsad(8) https://www.greenbone.net
After=network.target gvmd.service
Wants=gvmd.service

[Service]
Type=exec
User=$GVMUSER
Group=$GVMUSER
RuntimeDirectory=gsad
RuntimeDirectoryMode=2775
PIDFile=/run/gsad/gsad.pid
ExecStart=$INSTALL_PREFIX/sbin/gsad --foreground --listen=127.0.0.1 --port=9392 --http-only
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOF

# sudo cp -rv $INSTALL_DIR/gsad/* /
mkdir $INSTALL_DIR/gsad/DEBIAN
cat >$INSTALL_DIR/gsad/DEBIAN/control <<EOF
Package: gsad
Version: $GSAD_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS gsad
EOF


cd $INSTALL_DIR
dpkg-deb --root-owner-group --build gsad
sudo dpkg -i gsad.deb

echo "Installed gsad"
read -n 1 -s -r -p "Press any key to continue"
else
echo "gsad already installed"
fi

##
## openvas-smb
##
INSTALLED=$(dpkg -s openvas-smb|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$OPENVAS_SMB_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  gcc-mingw-w64 \
  libgnutls28-dev \
  libglib2.0-dev \
  libpopt-dev \
  libunistring-dev \
  heimdal-dev \
  perl-base
fi

if [ ! -d $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION ]; then
        git clone -b v$OPENVAS_SMB_VERSION --single-branch https://github.com/greenbone/openvas-smb.git $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION
fi

mkdir -p $BUILD_DIR/openvas-smb && cd $BUILD_DIR/openvas-smb

cmake $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)

mkdir -p $INSTALL_DIR/openvas-smb

make DESTDIR=$INSTALL_DIR/openvas-smb install

#sudo cp -rv $INSTALL_DIR/openvas-smb/* /
mkdir $INSTALL_DIR/openvas-smb/DEBIAN
cat >$INSTALL_DIR/openvas-smb/DEBIAN/control <<EOF
Package: openvas-smb
Version: $OPENVAS_SMB_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS openvas-smb
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build openvas-smb
sudo dpkg -i openvas-smb.deb

echo "Installed openvas-smb"
read -n 1 -s -r -p "Press any key to continue"
else
echo "openvas-smb already installed"
fi

##
## openvas-scanner
##
INSTALLED=$(dpkg -s openvas-scanner|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$OPENVAS_SCANNER_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  bison \
  libglib2.0-dev \
  libgnutls28-dev \
  libgcrypt20-dev \
  libpcap-dev \
  libgpgme-dev \
  libksba-dev \
  rsync \
  nmap \
  libjson-glib-dev \
  libbsd-dev
sudo apt install -y \
  python3-impacket \
  libsnmp-dev
fi

if [ ! -d $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION ]; then
        git clone -b v$OPENVAS_SCANNER_VERSION --single-branch https://github.com/greenbone/openvas-scanner.git $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION
fi

mkdir -p $BUILD_DIR/openvas-scanner && cd $BUILD_DIR/openvas-scanner

cmake $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DINSTALL_OLD_SYNC_SCRIPT=OFF \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
  -DOPENVAS_RUN_DIR=/run/ospd

make -j$(nproc)

mkdir -p $INSTALL_DIR/openvas-scanner

make DESTDIR=$INSTALL_DIR/openvas-scanner install

# sudo cp -rv $INSTALL_DIR/openvas-scanner/* /
mkdir $INSTALL_DIR/openvas-scanner/DEBIAN
cat >$INSTALL_DIR/openvas-scanner/DEBIAN/control <<EOF
Package: openvas-scanner
Version: $OPENVAS_SCANNER_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS openvas-scanner
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build openvas-scanner
sudo dpkg -i openvas-scanner.deb

echo "Installed openvas-scanner"
read -n 1 -s -r -p "Press any key to continue"
else
echo "openvas-scanner already installed"
fi

##
## ospd-openvas
##
INSTALLED=$(dpkg -s ospd-openvas|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$OSPD_OPENVAS_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-defusedxml \
  python3-deprecated \
  python3-lxml \
  python3-packaging \
  python3-paho-mqtt \
  python3-psutil \
  python3-redis \
  python3-wrapt \
  python3-cffi \
  python3-paramiko
fi

if [ ! -d $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION ]; then
        git clone -b v$OSPD_OPENVAS_VERSION --single-branch https://github.com/greenbone/ospd-openvas.git $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION
fi

cd $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION

mkdir -p $INSTALL_DIR/ospd-openvas

python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-deps --no-warn-script-location .

# sudo cp -rv $INSTALL_DIR/ospd-openvas/* /
mkdir $INSTALL_DIR/ospd-openvas/DEBIAN
cat >$INSTALL_DIR/ospd-openvas/DEBIAN/control <<EOF
Package: ospd-openvas
Version: $OSPD_OPENVAS_VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS ospd-openvas
EOF

mkdir -p $INSTALL_DIR/ospd-openvas/etc/systemd/system/
cat << EOF > $INSTALL_DIR/ospd-openvas/etc/systemd/system/ospd-openvas.service
[Unit]
Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
Documentation=man:ospd-openvas(8) man:openvas(8)
After=network.target networking.service redis-server@openvas.service mosquitto.service
Wants=redis-server@openvas.service mosquitto.service notus-scanner.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=$GVMUSER
Group=$GVMUSER
RuntimeDirectory=ospd
RuntimeDirectoryMode=2775
PIDFile=/run/ospd/ospd-openvas.pid
ExecStart=$INSTALL_PREFIX/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0o770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build ospd-openvas
sudo dpkg -i ospd-openvas.deb

echo "Installed ospd-openvas"
read -n 1 -s -r -p "Press any key to continue"
else
echo "ospd-openvas already installed"
fi

##
## notus-scanner
##
INSTALLED=$(dpkg -s notus-scanner|awk '$1=="Version:" {print $2}')
if [ v"$INSTALLED" != v"$NOTUS_VERSION" ]; then

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-paho-mqtt \
  python3-psutil
fi

if [ ! -d $SOURCE_DIR/notus-scanner-$NOTUS_VERSION ]; then
        git clone -b v$NOTUS_VERSION --single-branch https://github.com/greenbone/notus-scanner.git $SOURCE_DIR/notus-scanner-$NOTUS_VERSION
fi

cd $SOURCE_DIR/notus-scanner-$NOTUS_VERSION

mkdir -p $INSTALL_DIR/notus-scanner

python3 -m pip install --root=$INSTALL_DIR/notus-scanner --no-deps --no-warn-script-location .

mkdir -p $INSTALL_DIR/notus-scanner/etc/systemd/system/
cat << EOF > $INSTALL_DIR/notus-scanner/etc/systemd/system/notus-scanner.service
[Unit]
Description=Notus Scanner
Documentation=https://github.com/greenbone/notus-scanner
After=mosquitto.service
Wants=mosquitto.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=$GVMUSER
RuntimeDirectory=notus-scanner
RuntimeDirectoryMode=2775
PIDFile=/run/notus-scanner/notus-scanner.pid
ExecStart=$INSTALL_PREFIX/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# sudo cp -rv $INSTALL_DIR/notus-scanner/* /
mkdir $INSTALL_DIR/notus-scanner/DEBIAN
cat >$INSTALL_DIR/notus-scanner/DEBIAN/control <<EOF
Package: notus-scanner
Version: $NOTUS_VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS notus-scanner
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build notus-scanner
sudo dpkg -i notus-scanner.deb

echo "Installed notus-scanner"
read -n 1 -s -r -p "Press any key to continue"
else
echo "notus-scanner already installed"
fi

##
## greenbone-feed-sync
##

if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  python3 \
  rsync \
  pipx
fi

mkdir -p $INSTALL_DIR/greenbone-feed-sync

# python3 -m pipx install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync

if [ ! -d $SOURCE_DIR/greenbone-feed-sync-$GREENBONE_FEED_SYNC_VERSION ]; then
        git clone -b v$GREENBONE_FEED_SYNC_VERSION --single-branch https://github.com/greenbone/greenbone-feed-sync.git $SOURCE_DIR/greenbone-feed-sync-$GREENBONE_FEED_SYNC_VERSION
fi

cd $SOURCE_DIR/greenbone-feed-sync-$GREENBONE_FEED_SYNC_VERSION

python3 -m pip install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location .

# sudo cp -rv $INSTALL_DIR/greenbone-feed-sync/* /
mkdir $INSTALL_DIR/greenbone-feed-sync/DEBIAN
cat >$INSTALL_DIR/greenbone-feed-sync/DEBIAN/control <<EOF
Package: greenbone-feed-sync
Version: $GREENBONE_FEED_SYNC_VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS greenbone-feed-sync
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build greenbone-feed-sync
sudo dpkg -i greenbone-feed-sync.deb

echo "Installed greenbone-feed-sync"
read -n 1 -s -r -p "Press any key to continue"

##
## gvm-tools
##
if [ ! -n "$SKIP_INSTALL_DEPS" ]; then
sudo apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-setuptools \
  python3-packaging \
  python3-lxml \
  python3-defusedxml \
  python3-paramiko
fi

mkdir -p $INSTALL_DIR/gvm-tools

python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-deps --no-warn-script-location gvm-tools

# sudo cp -rv $INSTALL_DIR/gvm-tools/* /
mkdir $INSTALL_DIR/gvm-tools/DEBIAN
cat >$INSTALL_DIR/gvm-tools/DEBIAN/control <<EOF
Package: gvm-tools
Version: 1.0
Section: utils
Priority: optional
Architecture: all
Maintainer: Jean-Francois Stenuit <jean-francois.stenuit@approach-cyber.com>
Description: Greenbone OpenVAS gvm-tools
EOF

cd $INSTALL_DIR
dpkg-deb --root-owner-group --build gvm-tools

echo "gvm-tools"
read -n 1 -s -r -p "Press any key to continue"

##### System setup ##################################################################

##
## redis
##
sudo apt install -y redis-server

sudo cp $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION/config/redis-openvas.conf /etc/redis/
sudo chown redis:redis /etc/redis/redis-openvas.conf
echo "db_address = /run/redis-openvas/redis.sock" | sudo tee -a /etc/openvas/openvas.conf

sudo systemctl start redis-server@openvas.service
sudo systemctl enable redis-server@openvas.service

sudo usermod -aG redis $GVMUSER

##
## Mosquitto (MQTT broker)
##
sudo apt install -y mosquitto
sudo systemctl start mosquitto.service
sudo systemctl enable mosquitto.service
echo -e "mqtt_server_uri = localhost:1883\ntable_driven_lsc = yes" | sudo tee -a /etc/openvas/openvas.conf

##
## Permissions
##
sudo mkdir -p /var/lib/notus
sudo mkdir -p /run/gvmd

sudo chown -R $GVMUSER:$GVMUSER /var/lib/gvm
sudo chown -R $GVMUSER:$GVMUSER /var/lib/openvas
sudo chown -R $GVMUSER:$GVMUSER /var/lib/notus
sudo chown -R $GVMUSER:$GVMUSER /var/log/gvm
sudo chown -R $GVMUSER:$GVMUSER /run/gvmd

sudo chmod -R g+srw /var/lib/gvm
sudo chmod -R g+srw /var/lib/openvas
sudo chmod -R g+srw /var/log/gvm

sudo chown $GVMUSER:$GVMUSER /usr/local/sbin/gvmd
sudo chmod 6750 /usr/local/sbin/gvmd

curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc

export GNUPGHOME=/tmp/openvas-gnupg
mkdir -p $GNUPGHOME

gpg --import /tmp/GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust

export OPENVAS_GNUPG_HOME=/etc/openvas/gnupg
sudo mkdir -p $OPENVAS_GNUPG_HOME
sudo cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/
sudo chown -R $GVMUSER:$GVMUSER $OPENVAS_GNUPG_HOME

##
## PostgreSQL
##
sudo apt install -y postgresql

sudo systemctl start postgresql@14-main

##
## Database and user creation
##

## TODO : database

## Create admin user
sudo -u $GVMUSER /usr/local/sbin/gvmd -v --create-user=admin
ADMIN_UUID=$(sudo -u $GVMUSER /usr/local/sbin/gvmd --get-users --verbose | grep admin | awk '{print $2}')
sudo -u $GVMUSER /usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $ADMIN_UUID

sudo systemctl daemon-reload
sudo systemctl --now enable ospd-openvas notus-scanner gvmd gsad

