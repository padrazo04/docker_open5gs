FROM docker_srslte

RUN apt-get update && \
    apt-get install -y libssl-dev xxd

RUN git clone https://github.com/pjsip/pjproject.git && \
    cd pjproject && \
    git fetch origin pull/4354/head:extra_aka && \
    git switch extra_aka && \
    git revert -n 7a302f27edb85c74c9a171383bfb561f9992291a && \
    echo "#include <pj/config_site_sample.h>\n\n#define PJ_HAS_SSL_SOCK 1\n#define PJSIP_HAS_DIGEST_AKA_AUTH 1" > pjlib/include/pj/config_site.h && \
    ./configure && make dep && make && make install
