all:
	docker build -t logbook .

up:
	docker run -p "8080:8080" -d logbook
