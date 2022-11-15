# Dockerfile for NC with pdlib and dlib

This is a Dockerfile which integrates the Facerecognition App with its dependencies into a NC:apache Dockerimage

## How to:
- `docker build . -t <image-name>`
- run the image e.g.: `docker run -d -p 8080:80 <image-name>`
- enable the app via NC admin panel
- install one model inside the container `./occ face:setup -m 1`
- and set the maximum memory you want to use `./occ face:setup --memory 2048M`
- run the background job `./occ face:background_job`

More information: https://github.com/matiasdelellis/facerecognition
