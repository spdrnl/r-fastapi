cpus?=2
workers := $(shell echo ${cpus}*2 | bc)

install-ubuntu:
	sudo apt-get install podman pipx
	pipx poetry
	pipx inject poetry poetry-plugin-export

run-api:
	poetry run uvicorn app.main:app

dev-api:
	poetry run uvicorn app.main:app --reload

test-stress:
	ab -n 10000 -v 2 -c ${cpus} -p data.json -T application/json \
		-rk http://localhost:8080/predict/ > test.out
	tail -40 test.out

test-smoke:
	curl -X 'POST' \
	  'http://localhost:8080/predict/' \
	  -H 'accept: application/json' \
	  -H 'Content-Type: application/json' \
	  -d @data.json

package-versions:
	R -s -f package-versions.R > package_versions

generate-requirements:
	poetry export --without-hashes --format=requirements.txt > requirements.txt

build-container: generate-requirements
	podman rm -i -f r-fastapi
	podman build -t r-fastapi .

run-container:
	podman stop -i -t 0 r-fastapi
	podman rm -i --storage r-fastapi
	podman run -d -p 8080:80 --cpus ${cpus} -e workers="${workers}" --name r-fastapi r-fastapi


