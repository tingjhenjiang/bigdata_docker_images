ARG debian_buster_image_tag=11-jdk-buster
FROM openjdk:${debian_buster_image_tag}

# -- Layer: cluster-base

ARG shared_workspace=/opt/workspace

RUN mkdir -p ${shared_workspace}

ENV SHARED_WORKSPACE=${shared_workspace}

# -- Layer: JupyterHub-base

ARG NB_USERs="user1"
ARG NB_UID="1001"
ARG NB_GID="100"
ARG PYTHON_VERSION="3.7"

# Ref: https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md
# https://hub.docker.com/r/jupyter/base-notebook/dockerfile
# https://hub.docker.com/r/rocker/rstudio/Dockerfile
# https://github.com/grst/rstudio-server-conda/blob/master/docker/init2.sh

RUN for USER in `echo "${NB_USERs}" | grep -o -e "[^;]*"` ; do \
        echo "+ handling user \"$USER\"" && \
        useradd -m -s /bin/bash -N -g $NB_GID $USER && \
        adduser $USER users && \
        ln -s ${SHARED_WORKSPACE} /home/$USER/workspace ; \
    done

RUN apt-get update -y && \
    apt-get install -y python3 python3-pip python3-venv wget rustc build-essential libssl-dev libffi-dev python3-dev python3-setuptools vim curl && \
    python3 -m venv /opt/jupyterhub/ && \
    /opt/jupyterhub/bin/python3 -m pip install -U pip && \
    /opt/jupyterhub/bin/python3 -m pip install wheel && \
    /opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab && \
    /opt/jupyterhub/bin/python3 -m pip install ipywidgets && \
    apt-get install -y nodejs npm && \
    npm install -g configurable-http-proxy && \
    mkdir -p /opt/jupyterhub/etc/jupyterhub/ && \
    cd /opt/jupyterhub/etc/jupyterhub/ && \
    /opt/jupyterhub/bin/jupyterhub --generate-config && \
    echo "c.Spawner.default_url = '/lab'" >> /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py

RUN chmod 775 /opt/jupyterhub -R && chmod 771 ${SHARED_WORKSPACE} -R && \
    chgrp $NB_GID /opt/jupyterhub -R && chgrp $NB_GID ${SHARED_WORKSPACE} -R 

ENV PATH=/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/jupyterhub/bin:$PATH
ENV NB_GID=${NB_GID}
ENV PYTHON_VERSION=${PYTHON_VERSION}

# -- Layer: JupyterHub-run

# Ref: https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md
# https://hub.docker.com/r/jupyter/base-notebook/dockerfile
# https://hub.docker.com/r/rocker/rstudio/Dockerfile
# https://github.com/grst/rstudio-server-conda/blob/master/docker/init2.sh
# https://medium.com/@am.benatmane/setting-up-a-spark-environment-with-jupyter-notebook-and-apache-zeppelin-on-ubuntu-e12116d6539e

ARG CONDA_PATH="/opt/conda"
ARG CONDA_VER="4.10.3"
ARG CONDA_ARCH="Linux-x86_64"
ARG RSTUDIO_VERSION="2021.09.0-351"
ARG FINAL_RUN_INIT_SCRIPT="/run_jupyterhub_and_rstudio.sh"
ARG SPARK_VERSION=3.2.0
ARG sparkR_version=${SPARK_VERSION}
ARG ALMOND_VERSION=0.11.2
ARG SCALA_VERSION=2.13
ARG SCALA_DETAILED_VERSION=2.13.4

RUN pyverstring="${PYTHON_VERSION}" && \
    PYVER_without_dot=$( echo "$pyverstring"  | sed -e "s/\.//g") && \
    PY_BIN_in_CONDA="${CONDA_PATH}"/envs/python/bin/python && \
    conda_install_sh_name=Miniconda3-py$PYVER_without_dot && \
    conda_install_sh_name_suffix=$( echo "${CONDA_VER}"-"${CONDA_ARCH}".sh ) && \
    conda_install_sh_name=$(printf "%s_%s" "$conda_install_sh_name" "$conda_install_sh_name_suffix") && \
    conda_download_sh_path=$(printf "%s%s" "https://repo.anaconda.com/miniconda/" "$conda_install_sh_name") && \
    echo "export PY_BIN_in_CONDA=$PY_BIN_in_CONDA \
          \nexport PYVER_without_dot=$PYVER_without_dot \
          \nexport CONDA_INSTALL_SH_NAME=$conda_install_sh_name && \
          \nexport CONDA_DOWNLOAD_SH_PATH=$conda_download_sh_path" > /envvarset.sh

RUN . /envvarset.sh && \
    wget --quiet $CONDA_DOWNLOAD_SH_PATH && \
    /bin/bash $CONDA_INSTALL_SH_NAME -f -b -p ${CONDA_PATH} && \
    ln -s ${CONDA_PATH}/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    rm $CONDA_INSTALL_SH_NAME && \
    rm -Rf /tmp/*

RUN . /envvarset.sh && \
    ${CONDA_PATH}/bin/conda create --prefix ${CONDA_PATH}/envs/python -c conda-forge python=${PYTHON_VERSION} ipykernel requests pandas numpy scikit-learn scipy matplotlib pyspark git && \
    ${PY_BIN_in_CONDA} -m ipykernel install --prefix=/opt/jupyterhub/ --name python_$PYVER_without_dot --display-name "Python (data science default)" && \
    ${CONDA_PATH}/bin/conda clean -a

ENV RETICULATE_PYTHON=${PY_BIN_in_CONDA}

RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo file libapparmor1 libclang-dev libcurl4-openssl-dev libedit2 libssl-dev lsb-release multiarch-support psmisc procps libpq5 && \
    if [ -z "$RSTUDIO_VERSION" ]; \
        then RSTUDIO_URL="https://www.rstudio.org/download/latest/stable/server/bionic/rstudio-server-latest-amd64.deb"; \
        else RSTUDIO_URL="http://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"; fi && \
    wget -q $RSTUDIO_URL && \
    dpkg -i rstudio-server-*-amd64.deb && \
    rm rstudio-server-*-amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get autoclean && \
    rm -Rf /tmp/*

RUN ${CONDA_PATH}/bin/conda create --prefix ${CONDA_PATH}/envs/r -c conda-forge r-base r-sparklyr r-devtools r-irkernel git && \
    ${CONDA_PATH}/bin/conda clean -a

## Symlink pandoc & standard pandoc templates for use system-wide
RUN ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin && \
    ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin && \
    #${CONDA_PATH}/envs/r/bin/git clone --recursive --branch ${PANDOC_TEMPLATES_VERSION} https://github.com/jgm/pandoc-templates && \
    ${CONDA_PATH}/envs/r/bin/git clone https://github.com/jgm/pandoc-templates.git --depth=1 && \
    mkdir -p /opt/pandoc/templates && \
    cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* && \
    mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/ && \
    rm -Rf /tmp/* && \
    ## RStudio wants an /etc/R, will populate from $R_HOME/etc
    mkdir -p /etc/R && \
    ## Write config files in $R_HOME/etc
    mkdir -p /usr/local/lib/R/etc/ && \
    echo '\n\
    \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
    \n# is not set since a redirect to localhost may not work depending upon \
    \n# where this Docker container is running. \
    \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
    \n  options(httr_oob_default = TRUE) \
    \n}' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron && \
    ## Need to configure non-root user for RStudio
    useradd rstudio && \
    echo "rstudio:rstudio" | chpasswd && \
	mkdir /home/rstudio && \
	chown rstudio:${NB_GID} /home/rstudio && \
    adduser rstudio users && \
	addgroup rstudio staff && \
    mkdir -p /home/rstudio/.rstudio/monitored/user-settings && \
    echo 'alwaysSaveHistory="0" \
          \nloadRData="0" \
          \nsaveAction="0"' \
          > /home/rstudio/.rstudio/monitored/user-settings/user-settings && \
    chown -R rstudio /home/rstudio/.rstudio && \
    chgrp -R ${NB_GID} /home/rstudio/.rstudio && \
    ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package
    echo "rsession-which-r=${CONDA_PATH}/envs/r/bin/R" >> /etc/rstudio/rserver.conf && \
    echo "rsession-ld-library-path=${CONDA_PATH}/envs/r/lib" >> /etc/rstudio/rserver.conf && \
    ## use more robust file locking to avoid errors when using shared volumes:
    echo 'lock-type=advisory' >> /etc/rstudio/file-locks && \
    echo "auth-minimum-user-id=0" >> /etc/rstudio/rserver.conf && \
    echo "session-timeout-minutes=0" > /etc/rstudio/rsession.conf && \
    echo "auth-timeout-minutes=0" >> /etc/rstudio/rserver.conf && \
    echo "auth-stay-signed-in-days=30" >> /etc/rstudio/rserver.conf && \
    ## run custom scripts: install R kernel to jupyter and install SparkR
    wget -O "/opt/conda/envs/r/SparkR.tar.gz" "https://archive.apache.org/dist/spark/spark-${sparkR_version}/SparkR_${sparkR_version}.tar.gz" && \
    echo 'install.packages("/opt/conda/envs/r/SparkR.tar.gz", repos = NULL, type="source") \
          \nsetwd("/opt/jupyterhub/bin") \
          \nIRkernel::installspec(name="R", displayname="R", prefix="/opt/jupyterhub/")' \
          > /opt/jupyterhub/install_Rkernel_to_jupyer.R && \
    /opt/conda/envs/r/lib/R/bin/Rscript /opt/jupyterhub/install_Rkernel_to_jupyer.R && \
    rm /opt/conda/envs/r/SparkR.tar.gz

RUN chgrp $NB_GID ${CONDA_PATH}/envs/r -R && \
    chmod 775 ${CONDA_PATH}/envs/r -R

# scala part: 
# https://almond.sh/docs/quick-start-install
# https://github.com/almond-sh/almond/issues/729
ENV COURSIER_CACHE=/usr/share/coursier/cache
RUN curl -Lo coursier https://git.io/coursier-cli && \
    chmod +x coursier && \
    mkdir /usr/share/coursier/cache -p && \
    ./coursier launch --fork "almond:${ALMOND_VERSION}" --scala "${SCALA_DETAILED_VERSION}" -- --install --id "almond" --jupyter-path "/opt/jupyterhub/share/jupyter/kernels" --display-name "Scala (almond)" && \
    chgrp -R $NB_GID /usr/share/coursier && \
    chmod -R g+rwxs /usr/share/coursier && \
    rm ./coursier

#beakerx java part:
# would appear message: [InstallKernelSpec] Installed kernelspec java in /opt/jupyterhub/share/jupyter/kernels/java
RUN . /envvarset.sh && \
    ${CONDA_PATH}/bin/conda create --prefix ${CONDA_PATH}/envs/beakerx -c beakerx beakerx_kernel_java && \
    ${CONDA_PATH}/envs/beakerx/bin/beakerx_kernel_java install && \
    ${CONDA_PATH}/bin/conda clean -a && \
    chgrp $NB_GID ${CONDA_PATH}/envs/beakerx -R && \
    chmod 775 ${CONDA_PATH}/envs/beakerx -R

#/opt/conda/envs/beakerx/bin/beakerx_kernel_autotranslation
#/opt/conda/envs/beakerx/bin/beakerx_tabledisplay

#http://ot-note.logdown.com/posts/244277/scala-tdd-preliminary-environmental-setting-tips
#check path: https://repo1.maven.org/maven2/sh/almond/scala-kernel_2.13.4/
#./coursier launch --fork almond:0.11.1 --scala 2.13.4 -- --install --id "almond" --jupyter-path "/opt/jupyterhub/share/jupyter/kernels" --display-name "scala (almond 0.11.1)" --env PATH=$PATH:/opt/conda/envs/scala/bin/
#test: https://github.com/almond-sh/examples/blob/master/notebooks/scala-tour/basics.ipynb
#java -jar /opt/jupyterhub/share/jupyter/kernels/almond/launcher.jar --id almond 00jupyter-path /opt/jupyterhub/share/jupyter/kernels
#https://timothyzhang.medium.com/%E5%9C%A8jupyterlab%E4%B8%AD%E4%BD%BF%E7%94%A8scala%E5%92%8Cspark-5f7f7968e37e
#https://stackoverflow.com/questions/35563545/how-do-i-install-scala-in-jupyter-ipython-notebook

RUN echo '#!/bin/bash \
          \n/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 & \
          \n/opt/jupyterhub/bin/jupyterhub -f /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py' \
          > ${FINAL_RUN_INIT_SCRIPT} && \
    chmod 770 ${FINAL_RUN_INIT_SCRIPT}

# -- Runtime

EXPOSE 8888
EXPOSE 8000
EXPOSE 8787
WORKDIR ${SHARED_WORKSPACE}
VOLUME ${SHARED_WORKSPACE}
#VOLUME ${shared_workspace}
RUN chgrp $NB_GID ${SHARED_WORKSPACE} -R && chmod 771 ${SHARED_WORKSPACE} -R
ENV FINAL_RUN_INIT_SCRIPT=$FINAL_RUN_INIT_SCRIPT
CMD ["sh","-c","${FINAL_RUN_INIT_SCRIPT}"]