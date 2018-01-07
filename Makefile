all:
	docker build -t logbook .

up:
	docker run -p "8080:8080" -d logbook

stop:
	docker ps | grep logbook | tr -s ' ' | cut -d' ' -f1 | xargs docker stop
