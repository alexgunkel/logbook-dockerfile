all:
	docker build -t logbook .

up:
	docker run -p "8080:8080" -d logbook

official:
	docker run -p "8080:8080" -d alexandergunkel/logbook:0.0.1
