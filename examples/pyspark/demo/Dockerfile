FROM --platform=linux/amd64 amazonlinux:2 AS base

RUN yum install -y python3

# config virtaul env
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# copy required files
COPY requirements.txt .
COPY my_python_project/ ./my_python_project/

# upgrade pip
RUN python3 -m pip install --upgrade pip

# install packages to virtual env (see https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
RUN python3 -m pip install -r requirements.txt

# install package from source
RUN python3 -m pip install ./my_python_project

# package virtual env
RUN mkdir /output && venv-pack -o /output/pyspark.tar.gz

FROM scratch AS export
COPY --from=base /output/pyspark.tar.gz /
