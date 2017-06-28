FROM ubuntu
MAINTAINER Pablo Winant

RUN apt-get update
RUN apt-get install -y wget

RUN useradd -ms /bin/bash dynosaur

WORKDIR /home/dynosaur/


USER root
RUN apt-get install --no-install-recommends -y git bzip2 unzip libzmq5 nano hdf5-tools build-essential make gfortran

# Add Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]


USER dynosaur
ENV NBUSER=dynosaur
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -p /home/dynosaur/.opt/miniconda
RUN rm Miniconda3-latest-Linux-x86_64.sh
RUN /home/dynosaur/.opt/miniconda/bin/conda install -y -c conda-forge jupyterlab
ENV PATH /home/dynosaur/.opt/miniconda/bin:$PATH
CMD ["jupyter", "lab", "--ip=0.0.0.0"]


# ##################
# ###### Julia #####
# ##################
#
USER $NBUSER
RUN touch /home/$NBUSER/.curlrc
RUN chown $NBUSER /home/$NBUSER/.curlrc
RUN echo 'cacert=/etc/ssl/certs/ca-certificates.crt' > $HOME/.curlrc
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.0-linux-x86_64.tar.gz
RUN mkdir $HOME/.opt/julia
RUN tar xvf julia-0.6.0-linux-x86_64.tar.gz -C $HOME/.opt/julia --strip-components=1
RUN rm julia-0.6.0-linux-x86_64.tar.gz
ENV PATH /home/dynosaur/.opt/julia/bin:$PATH
#
# # Install IJulia kernel
RUN julia -e 'Pkg.add("IJulia")'
#
#
RUN julia -e 'Pkg.add("PyPlot"); \
           Pkg.add("Gadfly"); \
           Pkg.add("SymEngine"); \
           Pkg.add("AxisArrays"); \
           Pkg.add("YAML")'

#
RUN julia -e 'Pkg.clone("https://github.com/EconForge/Dolang.git")'
RUN julia -e 'Pkg.clone("https://github.com/EconForge/Dyno.git")'
RUN julia -e 'Pkg.build("Dyno")'
# #
USER root
RUN apt-get install --no-install-recommends -y libfftw3-double3 libfftw3-single3

USER $NBUSER
RUN julia -e 'Pkg.clone("https://github.com/EconForge/Dolo.jl.git")'
RUN julia -e 'using Dolo'

RUN git clone https://github.com/EconForge/dolo_models.git /home/dynosaur/dolo_examples
#
#
# # cleanup
#
