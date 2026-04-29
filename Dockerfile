FROM hpretl/iic-osic-tools:2025.07

RUN pip install --upgrade pip 
RUN pip install "cython<3.0.0" wheel
RUN pip install "PyYAML==5.2" --no-build-isolation 
RUN pip install git+https://github.com/jurevreca12/forastero.git@09c1817 
RUN pip install git+https://github.com/cocotb/cocotb.git@c463647 
RUN pip install git+https://github.com/jurevreca12/riscv-python-model@24daba0 
RUN pip uninstall -y riscv-config 
RUN pip install git+https://github.com/riscv-software-src/riscv-config@54171f2
RUN pip install git+https://github.com/riscv-software-src/riscof@aa146d4 
RUN pip uninstall -y riscv-isac
RUN pip install git+https://github.com/riscv-software-src/riscv-isac@777d2b4 
RUN pip install pytest-xdist

USER 0:0
RUN curl -L https://github.com/sifive/elf2hex/archive/refs/tags/v20.08.00.00.tar.gz -o elf2hex.tar.gz 
RUN tar -xvzpf elf2hex.tar.gz 
RUN rm elf2hex.tar.gz 
RUN cd elf2hex-* 
RUN ./configure --target=riscv32-unknown-elf 
RUN make 
RUN make install 
RUN cd .. 
RUN rm -rf elf2hex-*

RUN apt install -y boolector 

RUN git clone https://github.com/YosysHQ/riscv-formal && \
    cd riscv-formal && \
    git checkout 3a2512a22e79d5289f90a5ea2d208b21bba7b352 && \
    mkdir /foss/tools/riscv-formal && \
    cp -r ./checks /foss/tools/riscv-formal/ && \
    cp -r ./bus /foss/tools/riscv-formal/ && \
    cp -r ./insns /foss/tools/riscv-formal/ && \
    cp -r ./monitor /foss/tools/riscv-formal/ && \
    cd .. && \
    rm -rf riscv-formal && \
    sed -i "s/basedir\s=\sf\"{os\.getcwd()}\/\.\.\/\.\.\"/basedir = \"\/foss\/tools\/riscv-formal\"/" \
        /foss/tools/riscv-formal/checks/genchecks.py && \
    sed -i "s/corename\s=\sos\.getcwd()\.split(\"\/\")\[-1\]/corename = \"rvj1\"/" \
        /foss/tools/riscv-formal/checks/genchecks.py && \
    sed -i "s/with\sopen(f\"\.\.\/\.\./with open(f\"\/foss\/tools\/riscv-formal/" \
        /foss/tools/riscv-formal/checks/genchecks.py

WORKDIR /foss/designs/mcu-soc
