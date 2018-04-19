#!/bin/sh

set -e

miniconda_download_url=https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

s3ql_download_url=https://bitbucket.org/nikratio/s3ql/downloads/s3ql-2.26.tar.bz2

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --no-install-recommends -y software-properties-common ca-certificates nfs-kernel-server build-essential pkg-config libfuse-dev libattr1-dev libsqlite3-dev psmisc procps wget
apt-get upgrade --no-install-recommends -y
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

wget $miniconda_download_url
sh $(basename $miniconda_download_url) -b -p /opt/conda
rm $(basename $miniconda_download_url)
ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate base" >> ~/.bashrc

PATH=/opt/conda/bin:$PATH

conda install pip
pip install --upgrade pip setuptools
pip install --upgrade setuptools pycrypto defusedxml requests apsw llfuse dugong

wget $s3ql_download_url
tar jxf $(basename $s3ql_download_url)
cd $(basename $s3ql_download_url .tar.bz2)
python3 setup.py install
# XXX remove cruft?

#S3QL ???
ulimit -n 30000

#NFS
mkdir -p /run/rpc_pipefs/nfs
# ???
sed -i 's#KILL_PROCESS_TIMEOUT = 5#KILL_PROCESS_TIMEOUT = 120#g' /sbin/my_init
sed -i 's#KILL_ALL_PROCESSES_TIMEOUT = 5#KILL_ALL_PROCESSES_TIMEOUT = 120#g' /sbin/my_init
mkdir -p /etc/my_init.d

sed -i 's#NEED_SVCGSSD=""#NEED_SVCGSSD=no#g' /etc/default/nfs-kernel-server
service rpcbind restart
service nfs-kernel-server restart
