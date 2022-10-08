FROM line/kubectl-kustomize:latest

COPY entrypoint.sh /bin/
RUN chmod +x /bin/entrypoint.sh

ENV SSH_KEY=
ENV SSH_CONFIG=
ENV IMAGES=
ENV IMAGE_TAG=
ENV MANIFEST_HOST=
ENV MANIFEST_USER=
ENV MANIFEST_USER_EMAIL=
ENV MANIFEST_REPO=
ENV MANIFEST_BRANCH=
ENV KUSTOMIZATION=

ENTRYPOINT ["/bin/entrypoint.sh"]
