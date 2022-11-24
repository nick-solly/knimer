.PHONY: build_final_image build_base_image download_base_image_dockerfile clean

build_final_image: build_base_image
	@echo "*** Building final image ***"
	docker build -t knimer .

build_base_image: download_base_image_dockerfile
	@echo "*** Building base KNIME image ***"
	docker build -t base_knime_image -f knimeDockerfile --build-arg PRODUCT_VERSION=4.6.4 .

download_base_image_dockerfile:
	@echo "*** Downloading base KNIME Dockerfile ***"
	curl https://raw.githubusercontent.com/DrSnowbird/knime-docker/86bf236cfe1fee47f82a3d6c49a69db0e0cf6336/Dockerfile --output knimeDockerfile

clean:
	@echo "*** Cleaning up docker images ***"
	docker image rm base_knime_image
	docker image rm knimer
