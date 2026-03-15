package main

import (
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func (s *MuxServer) routes() {

	// Business logic
	s.gorilla.HandleFunc("/user", s.addUser).Methods("POST")
	s.gorilla.HandleFunc("/users", s.listUsers).Methods("GET")
	s.gorilla.HandleFunc("/user/{id}", s.updateUser).Methods("PUT")
	s.gorilla.HandleFunc("/user/{id}", s.deleteUser).Methods("DELETE")

	//prometheus endpoint
	s.gorilla.Handle("/metrics", promhttp.Handler())

	// /heathz endpoint for startup probe
	s.gorilla.HandleFunc("/healthz", s.health).Methods("GET")

	// /ready endpoint to make sure app is able to connect to DB before accepting users requests
	s.gorilla.HandleFunc("/ready", s.ready).Methods("GET")
}
