package main

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
)

func (s *MuxServer) addUser(w http.ResponseWriter, r *http.Request) {
	timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues("/user"))
	defer timer.ObserveDuration()

	var userData Userparam
	var user User

	if err := json.NewDecoder(r.Body).Decode(&userData); err != nil {
		httpRequestsTotal.WithLabelValues("POST", "/user", "400").Inc()
		http.Error(w, "invalid body", http.StatusBadRequest)
		return
	}

	user.Name = userData.Name
	user.Email = userData.Email
	user.Age = userData.Age

	if err := s.db.Create(&user).Error; err != nil {
		httpRequestsTotal.WithLabelValues("POST", "/user", "500").Inc()
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}

	httpRequestsTotal.WithLabelValues("POST", "/user", "201").Inc()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

func (s *MuxServer) listUsers(w http.ResponseWriter, r *http.Request) {
	timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues("/users"))
	defer timer.ObserveDuration()

	var users []User
	if err := s.db.Find(&users).Error; err != nil {
		httpRequestsTotal.WithLabelValues("GET", "/users", "500").Inc()
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}

	httpRequestsTotal.WithLabelValues("GET", "/users", "200").Inc()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

func (s *MuxServer) updateUser(w http.ResponseWriter, r *http.Request) {
	timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues("/user/{id}"))
	defer timer.ObserveDuration()

	var userData Userparam
	if err := json.NewDecoder(r.Body).Decode(&userData); err != nil {
		httpRequestsTotal.WithLabelValues("PUT", "/user/{id}", "400").Inc()
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	userId, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil {
		httpRequestsTotal.WithLabelValues("PUT", "/user/{id}", "400").Inc()
		http.Error(w, "invalid user id", http.StatusBadRequest)
		return
	}

	var user User
	if err := s.db.First(&user, userId).Error; err != nil {
		httpRequestsTotal.WithLabelValues("PUT", "/user/{id}", "404").Inc()
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	if userData.Name != "" {
		user.Name = userData.Name
	}
	if userData.Email != "" {
		user.Email = userData.Email
	}
	if userData.Age != 0 {
		user.Age = userData.Age
	}

	if err := s.db.Save(&user).Error; err != nil {
		httpRequestsTotal.WithLabelValues("PUT", "/user/{id}", "500").Inc()
		http.Error(w, "failed to update user", http.StatusInternalServerError)
		return
	}

	httpRequestsTotal.WithLabelValues("PUT", "/user/{id}", "200").Inc()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "User updated successfully",
	})
}

func (s *MuxServer) deleteUser(w http.ResponseWriter, r *http.Request) {
	timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues("/user/{id}"))
	defer timer.ObserveDuration()

	userId, err := strconv.Atoi(mux.Vars(r)["id"])
	if err != nil {
		httpRequestsTotal.WithLabelValues("DELETE", "/user/{id}", "400").Inc()
		http.Error(w, "invalid user id", http.StatusBadRequest)
		return
	}

	if err := s.db.Delete(&User{}, userId).Error; err != nil {
		httpRequestsTotal.WithLabelValues("DELETE", "/user/{id}", "500").Inc()
		http.Error(w, "failed to delete user", http.StatusInternalServerError)
		return
	}

	httpRequestsTotal.WithLabelValues("DELETE", "/user/{id}", "200").Inc()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "User deleted successfully",
	})
}

// To make sure whether the application process running and able to respond to HTTP requests?
func (s *MuxServer) health(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ok"))
}

// To check DB connection works and queries can be executed
// Since our application is dependent on DB for receiving incoming traffic
// We make sure app is able to connect to DB successfully before receiving user traffic
func (s *MuxServer) ready(w http.ResponseWriter, _ *http.Request) {
	sqlDB, err := s.db.DB()

	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		return
	}

	if err := sqlDB.Ping(); err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ready"))
}
