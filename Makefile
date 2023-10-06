PONY: build run

build:
	go build -o server server.go

run:
	nohup ./server -user=$(USER) -pass=$(PASS) > server.log 2>&1 &