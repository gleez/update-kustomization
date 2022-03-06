# Update Kustomization
An CI image for updating image tags using kustomize.

Environment variables:
- `SSH_KEY`: Base64-encoded private ssh key of `MANIFEST_USER`
- `MANIFEST_HOST`: Manifest git server host
- `MANIFEST_USER`: Manifest git user name
- `MANIFEST_USER_EMAIL`: Manifest git user email
- `MANIFEST_REPO`: Manifest git repository
- `MANIFEST_BRANCH`: Manifest repository branch
- `IMAGES`: Updated images (comma-separated list)
- `IMAGE_TAG`: Image tag generated in current build
- `KUSTOMIZATION`: Kustomization path relative to the project root
## Github Actions Example
```yaml
name: Publish and Deploy Docker image

on:
  push:
    branches:
      - main

jobs:
  publish_deploy:
    name: Publish and Deploy Docker image
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repo
        uses: actions/checkout@v2
      
      - name: Log in to Container Registry
        uses: docker/login-action@v1
        with:
          registry: harbor.mycompany.com
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v3
        with:
          images: harbor.mycompany.com/myuser/mysvc1
          
      - name: Build and push Docker image
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          
      - name: Deploy Docker Image
        uses: minghsu0107/update-kustomization@v1.0.5
        env:
          SSH_KEY: ${{ secrets.SSH_KEY }}
          MANIFEST_HOST: git.mycompany.com
          MANIFEST_USER: myuser
          MANIFEST_USER_EMAIL: myuser@mycompany.com
          MANIFEST_REPO: myapp-manifests
          MANIFEST_BRANCH: main
          IMAGES: harbor.mycompany.com/myuser/mysvc1
          IMAGE_TAG: ${{ steps.meta.outputs.tags }}
          KUSTOMIZATION: overlays/production
```
## Drone Usage Example
```yaml
kind: pipeline
name: publish-mysvc1
steps:
- name: publish
  image: plugins/docker
  settings:
    context: mysvc1
    dockerfile: mysvc1/Dockerfile
    username:
      from_secret: docker_username
    password:
      from_secret: docker_password
    registry: harbor.mycompany.com
    repo: harbor.mycompany.com/myuser/mysvc1
    tags:
    - ${DRONE_COMMIT_BRANCH}-${DRONE_COMMIT_SHA:0:7}
    - latest
  when:
    event: push

---
kind: pipeline
name: publish-mysvc2
steps:
- name: publish
  image: plugins/docker
  settings:
    context: mysvc2
    dockerfile: mysvc2/Dockerfile
    username:
      from_secret: docker_username
    password:
      from_secret: docker_password
    registry: harbor.mycompany.com
    repo: harbor.mycompany.com/myuser/mysvc2
    tags:
    - ${DRONE_COMMIT_BRANCH}-${DRONE_COMMIT_SHA:0:7}
    - latest
  when:
    event: push
    
---
kind: pipeline
name: update-kustomization
steps:
- name: kustomization
  pull: if-not-exists
  image: minghsu0107/update-kustomization
  environment:
    SSH_KEY:
      from_secret: ssh_key
    MANIFEST_HOST: git.mycompany.com
    MANIFEST_USER: myuser
    MANIFEST_USER_EMAIL: myuser@mycompany.com
    MANIFEST_REPO: myapp-manifests
    MANIFEST_BRANCH: main
    IMAGES: harbor.mycompany.com/myuser/mysvc1,harbor.mycompany.com/myuser/mysvc2
    IMAGE_TAG: ${DRONE_COMMIT_BRANCH}-${DRONE_COMMIT_SHA:0:7}
    KUSTOMIZATION: overlays/production
  when:
    event: push
depends_on:
 - publish-mysvc1
 - publish-mysvc2
```
In the above example, the image tag is in the form of `${DRONE_COMMIT_BRANCH}-${DRONE_COMMIT_SHA:0:7}`, where `DRONE_COMMIT_BRANCH` and `DRONE_COMMIT_SHA` are environment variables provided by Drone at run time. 
