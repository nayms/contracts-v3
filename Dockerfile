FROM node:16-slim

# install deps
RUN apt update
RUN apt install -y g++ make curl git
RUN curl -sSf https://sh.rustup.rs > $HOME/install_rust.sh
RUN chmod +x $HOME/install_rust.sh
RUN $HOME/install_rust.sh -y
RUN echo "source ~/.cargo/env" > ~/.profile
RUN source ~/.profile && cargo install svm-rs && svm install "0.7.6" && svm install "0.8.13"
RUN curl -L https://foundry.paradigm.xyz > $HOME/install_foundry.sh
RUN chmod +x $HOME/install_foundry.sh
RUN $HOME/install_foundry.sh
RUN source ~/.profile && foundryup

# start in the shell
ENTRYPOINT [ "/bin/bash" ]