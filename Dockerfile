#
# SPDX-License-Identifier: Apache-2.0
#

# In the first stage, install the common dependencies, and then set up the standard user.
FROM registry.access.redhat.com/ubi9/ubi-minimal AS base
RUN microdnf install -y python39 shadow-utils git \
    && groupadd -g 7051 hlf-user \
    && useradd -u 7051 -g hlf-user -G root -s /bin/bash hlf-user \
    && chgrp -R root /home/hlf-user /etc/passwd \
    && chmod -R g=u /home/hlf-user /etc/passwd \
    && microdnf remove -y shadow-utils \
    && microdnf clean -y all

# In the second stage, install all the development packages, install the Python dependencies,
# and then install the Ansible collection.
FROM base AS builder
RUN microdnf install -y gcc gzip python-devel tar \
    && microdnf clean -y all
USER hlf-user
ENV PATH=/home/hlf-user/.local/bin:$PATH
RUN pip3.9 install --user -U 'ansible' fabric-sdk-py python-pkcs11 'openshift' semantic_version jmespath \
    && chgrp -R root /home/hlf-user/.local \
    && chmod -R g=u /home/hlf-user/.local
ADD . /tmp/collection
RUN cd /tmp/collection \
    && ansible-galaxy collection build --output-path /tmp \
    && ansible-galaxy collection install /tmp/hyperledger-fabric_ansible_collection-*.tar.gz \
    && ansible-galaxy collection install kubernetes.core \
    && chgrp -R root /home/hlf-user/.ansible \
    && chmod -R g=u /home/hlf-user/.ansible
RUN curl -sSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  -o /tmp/kubectl \
    && chmod +x /tmp/kubectl \
    && mv /tmp/kubectl /home/hlf-user/.local/bin

# In the third stage, build the Hyperledger Fabric binaries with HSM enabled (this is not the default).
FROM base AS fabric
RUN microdnf install -y git make tar gzip which findutils gcc \
    && microdnf clean -y all
RUN ARCH=$(uname -m) \
    && if [ "${ARCH}" = "x86_64" ]; then ARCH=amd64; fi \
    && if [ "${ARCH}" = "aarch64" ]; then ARCH=arm64; fi \
    && curl -sSL https://go.dev/dl/go1.21.9.linux-${ARCH}.tar.gz | tar xzf - -C /usr/local
ENV GOPATH=/go
ENV PATH=/usr/local/go/bin:$PATH
RUN mkdir -p /go/src/github.com/hyperledger \
    && cd /go/src/github.com/hyperledger \
    && git clone -n https://github.com/hyperledger/fabric.git \
    && cd fabric \
    && git checkout v2.5.7
RUN cd /go/src/github.com/hyperledger/fabric \
    && make configtxlator osnadmin peer GO_TAGS=pkcs11 EXECUTABLES=

# In the final stage, copy all the installed Python modules across from the second stage and the Hyperledger
# Fabric binaries from the third stage.
FROM base
COPY --from=builder /home/hlf-user/.local /home/hlf-user/.local
COPY --from=builder /home/hlf-user/.ansible /home/hlf-user/.ansible
COPY --from=fabric /go/src/github.com/hyperledger/fabric/build/bin /opt/fabric/bin
COPY --from=fabric /go/src/github.com/hyperledger/fabric/sampleconfig /opt/fabric/config
COPY docker/docker-entrypoint.sh /
COPY docker/docker-entrypoint-opensource-stack.sh /
RUN mkdir /home/hlf-user/.kube
ENV FABRIC_CFG_PATH=/opt/fabric/config
ENV PATH=/opt/fabric/bin:/home/hlf-user/.local/bin:$PATH
USER 7051
ENTRYPOINT [ "/docker-entrypoint.sh" ]
