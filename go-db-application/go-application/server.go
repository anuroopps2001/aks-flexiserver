package main

import (
	"log"
	"log/slog"
	"net/http"

	"github.com/gorilla/mux"
)

type Server interface {
	Start() error
	routes()
}

type MuxServer struct {
	gorilla *mux.Router
	Client
}

func NewServer(db Client) Server {
	server := &MuxServer{
		mux.NewRouter(),
		db,
	}

	server.routes()
	return server
}

func (s *MuxServer) Start() error {
	slog.Info("Serving at port 8080")
	log.Fatal(http.ListenAndServe(":8080", s.gorilla))
	return nil
}
