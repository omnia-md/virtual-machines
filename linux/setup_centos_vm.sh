# Prepare a vagrant CentOS 6.5 VM for building OpenMM
# Needs latest version of vagrant to auto-download the chef package
#vagrant init chef/centos-6.5
#vagrant up
#vagrant ssh

# Download and enable the EPEL RedHat EL extras repository
mkdir ~/Software
cd Software
sudo yum install wget -y
wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
sudo rpm -i epel-release-6-8.noarch.rpm

sudo yum update -y

# Install things needed for virtualbox guest additions.
sudo yum remove kernel-2.6.32-431.el6.x86_64 # remove old kernel
sudo yum install kernel-devel dkms

# Several of these come from the EPEL repo
sudo yum install clang cmake graphviz perl flex bison rpm-build texlive texlive-latex ghostscript gcc gcc-c++ git vim emacs swig zip sphinx python-sphinx -y
# Note: changed from clang-3.4 to clang because the package has apparently been renamed.  KAB Oct 2 2014.

# We have to install a modern texlive 2014 distro, since the yum-installable version is missing vital components.
wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
cd install-tl-*
sudo ./install-tl -profile /vagrant/texlive.profile

# Probably can't use RHEL6 version of doxygen because it's very old.
wget http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.8.src.tar.gz
sudo yum remove doxygen  # Remove yum version!  Necessary as otherwise might not overwrite.
rpmbuild -ta doxygen-1.8.8.src.tar.gz
sudo yum install -y ~/rpmbuild/RPMS/x86_64/doxygen-1.8.8-1.x86_64.rpm
echo "exclude=doxygen" | sudo tee --append /etc/yum.conf  # The hand-built RPM package has the wrong versioning scheme and by default will be overwritten by a yum update.  This prevents overwriting.
rm ~/rpmbuild -r
doxygen --version  # Should be 1.8.8


sudo yum install gcc-gfortran  # Used for ambermini
sudo yum clean headers
sudo yum clean packages

# Install CUDA6.5 for RHEL6
cd ~/Software
wget http://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/cuda-repo-rhel6-6.5-14.x86_64.rpm
sudo rpm -i  cuda-repo-rhel6-6.5-14.x86_64.rpm
sudo yum clean expire-cache
sudo yum install cuda -y
# NOTE: NVIDIA may push new MAJOR release versions of CUDA without warning.
# This is even *before* doing the below update.  Beware.

sudo yum update -y  # Force a second update, in case CUDA has necessary patches.

# Install Conda
cd ~/Software
wget http://repo.continuum.io/miniconda/Miniconda-3.7.0-Linux-x86_64.sh
bash Miniconda-3.7.0-Linux-x86_64.sh -b

# So there is a bug in some versions of anaconda where the path to swig files is HARDCODED.  Below is workaround.  See https://github.com/ContinuumIO/anaconda-issues/issues/48
sudo ln -s  ~/miniconda/ /opt/anaconda1anaconda2anaconda3

export PATH=$HOME/miniconda/bin:$PATH
conda config --add channels http://conda.binstar.org/omnia
conda install --yes fftw3f jinja2 swig sphinx conda-build cmake binstar pip

# Add conda to the path.
echo "export PATH=$HOME/miniconda/bin:/usr/local/texlive/2014/bin/x86_64-linux:$PATH" >> .bashrc

# Install additional packages via pip.
sudo pip install sphinxcontrib-bibtex

