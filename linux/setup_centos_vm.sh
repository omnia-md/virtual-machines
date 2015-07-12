# Prepare a vagrant CentOS 6.5 VM for building OpenMM
# Needs latest version of vagrant to auto-download the chef package
#vagrant init chef/centos-6.5
#vagrant up
#vagrant ssh

# Download and enable the EPEL RedHat EL extras repository
echo "********** Enabling EPEL RedHat EL extras repository..."
mkdir ~/Software
cd Software
sudo yum install -y --quiet wget
wget --quiet http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
sudo rpm -i --quiet epel-release-6-8.noarch.rpm

# Install things needed for virtualbox guest additions.
#echo "********** Removing old kernel package..."
#sudo yum remove -y --quiet kernel-2.6.32-431.el6.x86_64 # no longer needed
echo "********** Installing kernel headers and dkms for virtualbox guest additions..."
sudo yum install -y --quiet kernel-devel dkms

echo "********** Updating yum..."
sudo yum update -y --quiet

# Several of these come from the EPEL repo
echo "********** Installing lots of packages via yum..."
sudo yum install -y --quiet tar clang cmake graphviz perl flex bison rpm-build texlive texlive-latex ghostscript gcc gcc-c++ git vim emacs swig zip sphinx python-sphinx doxygen screen

# We have to install a modern texlive 2014 distro, since the yum-installable version is missing vital components.
echo "********** Installing texlive 2014..."
sudo yum remove -y --quiet texlive texlive-latex  # Get rid of the system texlive in preparation for latest version.
wget --quiet http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar zxf install-tl-unx.tar.gz
cd install-tl-*
sudo ./install-tl -profile /vagrant/texlive.profile
export PATH=/usr/local/texlive/2014/bin/x86_64-linux:$PATH  # texlive updates bashrc to put tex on the path, but we need to update the current shell session.
sleep 2

# Make sure texlive install worked, as it often dies.  Only retry once, though.
if which tex >/dev/null; then
    echo Found texlive
else
    echo No texlive, resuming installation
    sudo ./install-tl -profile /vagrant/texlive.profile
fi

cd ..




# Install fortran
echo "********** Installing fortran..."
sudo yum install -y --quiet gcc-gfortran # Used for ambermini

sudo yum install -y --quiet lapack-devel  # Used for cvxopt.  This also grabs BLAS dependency.

sudo yum clean headers
sudo yum clean packages

# Install CUDA7.0 for RHEL6
echo "********** Installing CUDA 7.0 ..."
cd ~/Software
CUDA_RPM=cuda-repo-rhel6-7.0-28.x86_64.rpm
wget --quiet http://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/$CUDA_RPM
sudo rpm -i --quiet $CUDA_RPM
sudo yum clean expire-cache
sudo yum install -y --quiet cuda
# NOTE: NVIDIA may push new MAJOR release versions of CUDA without warning.
# This is even *before* doing the below update.  Beware.

echo "********** Forcing a second yum update in case CUDA has patches..."
sudo yum update -y --quiet  # Force a second update, in case CUDA has necessary patches.

# Install Conda
echo "********** Installing conda..."
cd ~/Software
MINICONDA=Miniconda-latest-Linux-x86_64.sh
MINICONDA_MD5=$(curl -s http://repo.continuum.io/miniconda/ | grep -A3 $MINICONDA | sed -n '4p' | sed -n 's/ *<td>\(.*\)<\/td> */\1/p')
wget --quiet http://repo.continuum.io/miniconda/$MINICONDA
if [[ $MINICONDA_MD5 != $(md5sum $MINICONDA | cut -d ' ' -f 1) ]]; then
echo "Miniconda MD5 mismatch"
exit 1
fi
bash $MINICONDA -b

# So there is a bug in some versions of anaconda where the path to swig files is HARDCODED.  Below is workaround.  See https://github.com/ContinuumIO/anaconda-issues/issues/48
sudo ln -s  ~/miniconda/ /opt/anaconda1anaconda2anaconda3

echo "********** Installing conda/binstar channels and packages..."
export PATH=$HOME/miniconda/bin:$PATH
conda config --add channels http://conda.binstar.org/omnia
conda install --yes --quiet fftw3f jinja2 swig sphinx conda-build cmake binstar pip

# Install AMD APP SDK
echo "********** Installing AMD APP SDK..."
# Download AMD APP SDK from here, requires click agreement: http://developer.amd.com/amd-license-agreement-appsdk/
# Ideally we could cache this on AWS or something...
mkdir ~/Software/AMD
cd ~/Software/AMD
# Copy the tarball $APPSDKFILE to the directory containing VagrantFile, which will be shared on the guest as /vagrant/
sudo yum install -y --quiet redhat-lsb
APPSDKFILE="AMD-APP-SDK-linux-v2.9-1.599.381-GA-x64.tar.bz2"
echo "This will fail if you do not have $APPSDKFILE already downloaded to the directory containing VagrantFile."
tar -jxvf  /vagrant/$APPSDKFILE
sudo ./AMD-APP-SDK-v2.9-1.599.381-GA-linux64.sh -- -s -a yes

# Add conda to the path.
echo "********** Adding paths"
cd ~
echo "export PATH=$HOME/miniconda/bin:/usr/local/texlive/2014/bin/x86_64-linux:$PATH" >> $HOME/.bashrc
echo "" >> $HOME/.bashrc

# Install additional packages via pip.
echo "********** Installing packages via pip..."
$HOME/miniconda/bin/pip install --quiet sphinxcontrib-bibtex

