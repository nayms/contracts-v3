FROM node:16-alpine
RUN apk add bash --no-cache g++ make curl
SHELL ["/bin/bash", "-c"]
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > $HOME/install_rust.sh
RUN chmod +x $HOME/install_rust.sh
RUN $HOME/install_rust.sh -y
RUN echo "source ~/.cargo/env" > ~/.bashrc
RUN source ~/.bashrc && cargo install svm-rs && svm install "0.7.6" && svm install "0.8.13"
ENTRYPOINT [ "/bin/bash" ]